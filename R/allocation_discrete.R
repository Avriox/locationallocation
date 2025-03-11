#' @export
allocation_discrete <- function(demand_raster, traveltime_raster=NULL, bb_area, facilities=NULL, candidate, max_fac = Inf, weights=NULL, objectiveminutes=10, heur="max", dowscaling_model_type, mode, res_output, n_samples){

  if(is.null(traveltime_raster) & !is.null(facilities)){
    print("Travel time layer not detected. Running traveltime function first.")
    traveltime_raster_outer <- traveltime(facilities=facilities, bb_area=bb_area, dowscaling_model_type=dowscaling_model_type, mode=mode, res_output=res_output)

  } else if(is.null(facilities)) {

    out <- friction(bb_area=bb_area, mode=mode, res_output=res_output, dowscaling_model_type=dowscaling_model_type)

  } else if(!is.null(traveltime_raster) & is.null(facilities)) {break}


  ###############

  facilities <- if(is.null(facilities)){
   st_as_sf(data.frame(x=0,y=0), coords = c("x", "y"), crs = 4326)[-1,]
  } else{
    facilities
  }

  demand_raster <- mask_raster_to_polygon(demand_raster, bb_area)

  totalpopconstant = raster::cellStats(demand_raster, 'sum', na.rm = TRUE)

  if(!exists("traveltime_raster_outer")){

    traveltime_raster <- demand_raster
    raster::values(traveltime_raster) <- objectiveminutes + 1
    traveltime_raster <- mask_raster_to_polygon(traveltime_raster, bb_area)

    traveltime_raster_outer <- list(traveltime_raster, out)

  }

  traveltime_raster_outer[[1]] <- raster::projectRaster(traveltime_raster_outer[[1]], demand_raster)

  demand_raster <-  raster::overlay(demand_raster, traveltime_raster_outer[[1]], fun = function(x, y) {
    x[y<=objectiveminutes] <- NA
    return(x)
  })

  demand_raster_bk <- demand_raster


  #######

  samples <- replicate(n_samples, sample(1:length(candidate), max_fac, replace = F))

  ########

  runner <- function(i){

  demand_raster <- demand_raster_bk

  points = rbind(sf::st_coordinates(facilities), sf::st_coordinates(sf::st_as_sf(candidate))[samples[,i],])
  points <- data.frame(x=points[,1], y=points[,2])

  # Fetch the number of points
  temp <- dim(points)
  n.points <- temp[1]

  # Convert the points into a matrix
  xy.data.frame <- data.frame()
  xy.data.frame[1:n.points,1] <- points[,1]
  xy.data.frame[1:n.points,2] <- points[,2]
  xy.matrix <- as.matrix(xy.data.frame)

  # Run the accumulated cost algorithm to make the final output map. This can be quite slow (potentially hours).
  traveltime_raster_new <- gdistance::accCost(traveltime_raster_outer[[2]][[3]], xy.matrix)

  traveltime_raster_new = raster::crop(traveltime_raster_new, raster::extent(demand_raster))

  traveltime_raster_new <- raster::projectRaster(traveltime_raster_new, demand_raster)

  traveltime_raster_new <- mask_raster_to_polygon(traveltime_raster_new, bb_area)

  demand_raster <- raster::overlay(demand_raster, traveltime_raster_new, fun = function(x, y) {
    x[y<=objectiveminutes] <- NA
    return(x)
  })

  k = raster::cellStats(demand_raster, 'sum', na.rm = TRUE)/totalpopconstant

  return(k)

  }

  outer <- pbapply::pblapply(1:n_samples, runner)

  ######

  demand_raster <- demand_raster_bk

  points = rbind(sf::st_coordinates(facilities), sf::st_coordinates(sf::st_as_sf(candidate))[samples[,  which.min(unlist(outer))],])
  points <- data.frame(x=points[,1], y=points[,2])

  # Fetch the number of points
  temp <- dim(points)
  n.points <- temp[1]

  # Convert the points into a matrix
  xy.data.frame <- data.frame()
  xy.data.frame[1:n.points,1] <- points[,1]
  xy.data.frame[1:n.points,2] <- points[,2]
  xy.matrix <- as.matrix(xy.data.frame)

  # Run the accumulated cost algorithm to make the final output map. This can be quite slow (potentially hours).
  traveltime_raster_new <- gdistance::accCost(traveltime_raster_outer[[2]][[3]], xy.matrix)

  traveltime_raster_new = raster::crop(traveltime_raster_new, raster::extent(demand_raster))

  traveltime_raster_new <- raster::projectRaster(traveltime_raster_new, demand_raster)

  traveltime_raster_new_min <- mask_raster_to_polygon(traveltime_raster_new, bb_area)

  demand_raster <- raster::overlay(demand_raster, traveltime_raster_new_min, fun = function(x, y) {
    x[y<=objectiveminutes] <- NA
    return(x)
  })

  k = raster::cellStats(demand_raster, 'sum', na.rm = TRUE)/totalpopconstant

return(list(sf::st_as_sf(candidate)[samples[,which.min(unlist(outer))],], traveltime_raster_new_min, k))

}
