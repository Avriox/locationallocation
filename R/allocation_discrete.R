#' @export
allocation_discrete <- function(demand_raster, sf_area, facilities=NULL, candidate, max_fac = Inf, weights=NULL, objectiveminutes=10, heur="max", dowscaling_model_type, mode, res_output=100, n_samples){

  if(!is.null(traveltime_raster)){
    print("Travel time layer not detected. Running traveltime function first.")
    traveltime_raster <- traveltime(facilities=facilities, bb_area=sf_area, dowscaling_model_type=dowscaling_model_type, mode=mode, res_output=res_output)

  } else if(is.null(facilities)) {

    friction(bb_area=sf_area, mode=mode, res_output=res_output)

  }


  facilities <- if(is.null(facilities)){
   st_as_sf(data.frame(x=0,y=0), coords = c("x", "y"), crs = 4326)[-1,]
  } else{
    facilities
  }

  assign("boundary", sf_area, envir = .GlobalEnv)

  demand_raster <- mask_raster_to_polygon(demand_raster, sf_area)

  totalpopconstant = raster::cellStats(demand_raster, 'sum', na.rm = TRUE)

  if(!is.null(traveltime_raster)){
    traveltime_raster = raster::projectRaster(traveltime_raster, demand_raster)
    traveltime_raster <- mask_raster_to_polygon(traveltime_raster, sf_area)

  } else{

    traveltime_raster <- demand_raster
    raster::values(traveltime_raster) <- objectiveminutes + 1
    traveltime_raster <- mask_raster_to_polygon(traveltime_raster, sf_area)

  }

  demand_raster <-  raster::overlay(demand_raster, traveltime_raster, fun = function(x, y) {
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
  traveltime_raster_new <- gdistance::accCost(T.GC, xy.matrix)

  traveltime_raster_new = raster::crop(traveltime_raster_new, raster::extent(demand_raster))

  traveltime_raster_new <- raster::projectRaster(traveltime_raster_new, demand_raster)

  traveltime_raster_new <- mask_raster_to_polygon(traveltime_raster_new, sf_area)

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
  traveltime_raster_new <- gdistance::accCost(T.GC, xy.matrix)

  traveltime_raster_new = raster::crop(traveltime_raster_new, raster::extent(demand_raster))

  traveltime_raster_new <- raster::projectRaster(traveltime_raster_new, demand_raster)

  traveltime_raster_new_min <- mask_raster_to_polygon(traveltime_raster_new, sf_area)

  demand_raster <- raster::overlay(demand_raster, traveltime_raster_new_min, fun = function(x, y) {
    x[y<=objectiveminutes] <- NA
    return(x)
  })

  k = raster::cellStats(demand_raster, 'sum', na.rm = TRUE)/totalpopconstant

return(list(sf::st_as_sf(candidate)[samples[,which.min(unlist(outer))],], traveltime_raster_new_min, k))

}
