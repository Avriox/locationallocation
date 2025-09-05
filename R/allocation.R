#' Location allocation (continuous problem)
#'
#' This function is used to allocate facilities in a continuous location problem. It uses the accumulated cost algorithm to find the optimal location for the facilities based on the demand, travel time, and weights for the demand, and target travel time threshold and share of the demand to be covered.
#' @param demand_raster A raster object with the demand for the service.
#' @param traveltime_raster The output of the traveltime function. If not provided, the function will run the traveltime function first.
#' @param bb_area A boundary box object with the area of interest.
#' @param facilities A sf object with the existing facilities.
#' @param weights A raster with the weights for the demand.
#' @param objectiveminutes The objective travel time in minutes.
#' @param objectiveshare The share of the demand to be covered.
#' @param heur The heuristic approach to be used. Options are "max" (default) and "kd".
#' @param dowscaling_model_type The type of model used for the spatial downscaling of the travel time layer.
#' @param mode The mode of transport.
#' @param res_output The spatial resolution of the friction raster (and of the analysis), in meters. If <1000, a spatial downscaling approach is used.
#' @param approach The approach to be used for the allocation. Options are "norm" (default) and "equity". If "norm", the allocation is based on the normalized demand raster multiplied by the normalized weights raster. If "absweights", the allocation is based on the normalized demand raster multiplied by the raw weights raster.
#' @param exp_demand The exponent for the demand raster. Default is 1. A higher value will give less relative weight to areas with higher demand - with respect to the weights layer. This is useful in cases where the users want to increase the allocation in areas with higher values in the weights layer.
#' @param exp_weights The exponent for the weights raster. Default is 1.A higher value will give less relative weight to areas with higher weights - with respect to the demand layer. This is useful in cases where the users want to increase the allocation in areas with higher values in the demand layer.
#' @keywords location-allocation
#' @export

allocation <- function(demand_raster, traveltime_raster=NULL, bb_area, facilities=facilities, weights=NULL, objectiveminutes=10, objectiveshare=0.99, heur="max", dowscaling_model_type, mode, res_output, approach = "norm", exp_demand = 1, exp_weights = 1){

  # Check demand_raster is a raster layer
  if (!inherits(demand_raster, "RasterLayer")) {
    stop("Error: 'demand_raster' must be a raster layer.")
  }


	if(is.null(traveltime_raster) & !is.null(facilities)){
      print("Travel time layer not detected. Running traveltime function first.")
      traveltime_raster <- traveltime(facilities=facilities, bb_area=bb_area, dowscaling_model_type=dowscaling_model_type, mode=mode, res_output=res_output)

	# Check traveltime is an output object from the traveltime function

    }

	if (!inherits(traveltime_raster, "list") || length(traveltime_raster) != 2 || !inherits(traveltime_raster[[1]], "RasterLayer") || !inherits(traveltime_raster[[2]], "list") || length(traveltime_raster[[2]]) != 3) {
    stop("Error: 'traveltime_raster' must be an output object from the locationallocation::traveltime function.")
  }

  # Check bb_area is a numeric vector of length 4 (xmin, ymin, xmax, ymax)
  if (!inherits(bb_area, "sf") || nrow(bb_area) == 0) {
    stop("Error: 'bb_area' must be a non-empty sf polygon.")
  }

  # Check facilities is a non-empty data frame
  if (!inherits(facilities, "sf") || nrow(facilities) == 0) {
    stop("Error: 'facilities' must be a non-empty sf point geometry data frame.")
  }

  # Check weights is a raster layer
  if (!is.null(weights) && !inherits(weights, "RasterLayer")) {
    stop("Error: 'weights' must be a raster layer.")
  }

  # Check objectiveminutes is a numeric value
  if (!is.numeric(objectiveminutes) || length(objectiveminutes) != 1) {
    stop("Error: 'objectiveminutes' must be a numeric value.")
  }

  # Check objectiveshare is a numeric value
  if (!is.numeric(objectiveshare) || length(objectiveshare) != 1) {
    stop("Error: 'objectiveshare' must be a numeric value.")
  }

  # Check heur is a character string and one of the allowed values
  allowed_heur <- c("max", "kd")
  if (!is.character(heur) || length(heur) != 1 || !(heur %in% allowed_heur)) {
    stop(paste("Error: 'heur' must be one of", paste(allowed_heur, collapse = ", "), "."))
  }

  # Check dowscaling_model_type is a non-empty character string
  allowed_downscaling <- c("lm", "rf")
  if (!is.character(dowscaling_model_type) || length(dowscaling_model_type) != 1 || !(dowscaling_model_type %in% allowed_downscaling)) {
    stop("Error: 'dowscaling_model_type' must either be 'lm' or 'rf'.")
  }

  # Check mode is a character string and one of the allowed values
  allowed_modes <- c("walk", "fastest")
  if (!is.character(mode) || length(mode) != 1 || !(mode %in% allowed_modes)) {
    stop(paste("Error: 'mode' must be one of", paste(allowed_modes, collapse = ", "), "."))
  }

  # Check res_output is a single positive numeric value
  if (!is.numeric(res_output) || length(res_output) != 1 || res_output <= 0) {
    stop("Error: 'res_output' must be a single positive numeric value.")
  }

###

  sf::sf_use_s2(TRUE)

###

if(is.null(traveltime_raster)){
print("Travel time layer not detected. Running traveltime function first.")
traveltime_raster_outer <- traveltime(facilities=facilities, bb_area=bb_area, dowscaling_model_type=dowscaling_model_type, mode=mode, res_output=res_output)

} else{

traveltime_raster_outer <- traveltime_raster

}

demand_raster <- mask_raster_to_polygon(demand_raster, bb_area)
traveltime_raster <- mask_raster_to_polygon(traveltime_raster_outer[[1]], bb_area)

raster::crs(traveltime_raster) <- "+proj=longlat +datum=WGS84 +no_defs +type=crs"

traveltime_raster = raster::projectRaster(traveltime_raster, demand_raster)

raster::crs(traveltime_raster) <- "+proj=longlat +datum=WGS84 +no_defs +type=crs"

#######

normalize_raster <- function(r) {
  r_min <- raster::cellStats(r, stat='min')
  r_max <- raster::cellStats(r, stat='max')
  (r - r_min) / (r_max - r_min)
}

if(!is.null(weights) & approach=="norm"){ # optimize based on risk (exposure*hazard), and not on exposure only
  weights <- mask_raster_to_polygon(weights, bb_area)
  demand_raster <- (normalize_raster(demand_raster)^exp_demand)*(normalize_raster(weights)^exp_weights)


} else if(!is.null(weights) & approach=="absweights"){ # optimize based on risk (exposure*hazard), and not on exposure only
  weights <- mask_raster_to_polygon(weights, bb_area)
  demand_raster <- (normalize_raster(demand_raster)^exp_demand)*(weights^exp_weights)

}  else if(is.null(weights) ) {

  demand_raster <- demand_raster^exp_demand
}

totalpopconstant = raster::cellStats(demand_raster, 'sum', na.rm = TRUE)

demand_raster <-  raster::overlay(demand_raster, traveltime_raster, fun = function(x, y) {
  x[y<=objectiveminutes] <- NA
  return(x)
})

#######

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


      all = raster::which.max(demand_raster)


    }

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

  raster::crs(traveltime_raster_new) <- "+proj=longlat +datum=WGS84 +no_defs +type=crs"

  traveltime_raster_new <- raster::projectRaster(traveltime_raster_new, demand_raster)

  raster::crs(traveltime_raster_new) <- "+proj=longlat +datum=WGS84 +no_defs +type=crs"

  traveltime_raster_new <- mask_raster_to_polygon(traveltime_raster_new, bb_area)

  demand_raster <- raster::overlay(demand_raster, traveltime_raster_new, fun = function(x, y) {
    x[y<=objectiveminutes] <- NA
    return(x)
  })

  k = raster::cellStats(demand_raster, 'sum', na.rm = TRUE)/totalpopconstant

  k_save[iter] = k

  print(paste0("Fraction of unmet demand:  ", k*100, " %"))
  # exit if the condition is met
  if (k<(1-objectiveshare)){ break}
  else if ( k == k_save[iter-1] ) {

      raster::values(demand_raster)[all] <- NA

}}

outer <- list(merged_facilities[-c(1:nrow(facilities)),], traveltime_raster_new)

print(paste0(nrow(as.data.frame(new_facilities)), " facilities added to attain coverage of ", objectiveshare*100, "% of the demand within ", objectiveminutes, " minutes."))

return(outer)

}


