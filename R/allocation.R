#' @export
allocation <- function(demand_raster, traveltime_raster=NULL, bb_area, facilities=facilities, weights=NULL, objectiveminutes=10, objectiveshare=0.01, heur="max", dowscaling_model_type, mode, res_output){

if(is.null(traveltime_raster)){
print("Travel time layer not detected. Running traveltime function first.")
traveltime_raster_outer <- traveltime(facilities=facilities, bb_area=bb_area, dowscaling_model_type=dowscaling_model_type, mode=mode, res_output=res_output)

} else{

traveltime_raster_outer <- traveltime_raster

}

demand_raster <- mask_raster_to_polygon(demand_raster, bb_area)
traveltime_raster <- mask_raster_to_polygon(traveltime_raster_outer[[1]], bb_area)

totalpopconstant = raster::cellStats(demand_raster, 'sum', na.rm = TRUE)

traveltime_raster = raster::projectRaster(traveltime_raster, demand_raster)

demand_raster <-  raster::overlay(demand_raster, traveltime_raster, fun = function(x, y) {
  x[y<=objectiveminutes] <- NA
  return(x)
})

iter <- 1
k_save <- c(1)

repeat {

  iter <- iter + 1

  if(heur=="kd"){

    all <- spatialEco::sp.kde(x = st_as_sf(raster::rasterToPoints(demand_raster, spatial=TRUE)), y = all$layer, bw = 0.0083333,
              ref = terra::rast(demand_raster), res=0.0008333333,
              standardize = TRUE,
              scale.factor = 10000)

  } else if (heur =="max"){

  if(!is.null(weights)){ # optimize based on risk (exposure*hazard), and not on exposure only
    weights <- mask_raster_to_polygon(weights, bb_area)
    demand_raster_e <- demand_raster*(weights/mean(raster::values(weights), na.rm=T))

    all = raster::which.max(demand_raster_e)

  } else{

    all = raster::which.max(demand_raster)

  }}

  pos = as.data.frame(raster::xyFromCell(demand_raster, all))

  new_facilities <- if(exists("new_facilities")){
    rbind(new_facilities, sf::st_as_sf(pos, coords = c("x", "y"), crs = 4326))
  } else {
    sf::st_as_sf(pos, coords = c("x", "y"), crs = 4326)
  }

  merged_facilities <- dplyr::bind_rows(as.data.frame(sf::st_geometry(facilities)), as.data.frame(new_facilities))

  points = as.data.frame(sf::st_coordinates(merged_facilities$geometry))

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

  k_save[iter] = k

  print(paste0("Fraction of unmet demand:  ", k*100, " %"))
  # exit if the condition is met
  if (k<objectiveshare){ break}
  else if ( k == k_save[iter-1] ) {

      raster::values(demand_raster)[all] <- NA

}}

outer <- list(merged_facilities[-c(1:nrow(facilities)),], traveltime_raster_new)

return(outer)

}


