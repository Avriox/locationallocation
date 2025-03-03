#' @export
allocation_discrete <- function(demand_raster, sf_area, facilities=NULL, candidate, max_fac = Inf, traveltime_raster=NULL, weights=NULL, objectiveminutes=10, heur="max"){

  if(is.null(traveltime_raster) & !is.null(facilities)){
    print("Travel time layer not detected. Running traveltime function first.")
    traveltime_raster <- traveltime(facilities=facilities, bb_area=sf_area, dowscaling_model_type=dowscaling_model_type, mode=mode, res_output=res_output)

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
    values(traveltime_raster) <- 1000
    traveltime_raster <- mask_raster_to_polygon(traveltime_raster, sf_area)

  }

  demand_raster <-  raster::overlay(demand_raster, traveltime_raster, fun = function(x, y) {
    x[y<=objectiveminutes] <- NA
    return(x)
  })

  k_init = raster::cellStats(demand_raster, 'sum', na.rm = TRUE)/totalpopconstant

  demand_raster_bk <- demand_raster

  runner <- function(i){

    demand_raster <- demand_raster_bk

    points = rbind(sf::st_coordinates(facilities), sf::st_coordinates(sf::st_as_sf(candidate))[-i,])
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

    return(k_init-k)

  }

outer <- lapply(1:length(candidate), runner)

if(max_fac<Inf){

  outer <- unlist(outer)
  indices <- order(outer, decreasing = TRUE)[1:max_fac]

  demand_raster <- demand_raster_bk

  points = rbind(sf::st_coordinates(facilities), sf::st_coordinates(sf::st_as_sf(candidate))[c(indices),])
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

return(outer <- list(sf::st_as_sf(candidate)[c(indices),], traveltime_raster_new, k))

} else{

  outer <- unlist(outer)

  demand_raster <- demand_raster_bk

  points = rbind(sf::st_coordinates(facilities), sf::st_coordinates(sf::st_as_sf(candidate)))
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

  return(outer <- list(sf::st_as_sf(candidate), traveltime_raster_new, k))

}}
