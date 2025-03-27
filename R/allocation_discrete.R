#' Location allocation (discrete problem)
#'
#' This function is used to allocate facilities in a discrete location problem. It uses the accumulated cost algorithm to find the optimal location for the facilities based on a user-defined set of locations, objective travel time, and maximum number of allocable facilities. The problem is solved using a statistical heuristic approach that generates samples of the candidate locations (on top of the existing locations) and selects the facilities in the one that minimizes the objective function.
#' @param demand_raster A raster object with the demand for the service.
#' @param traveltime_raster The output of the traveltime function. If not provided, the function will run the traveltime function first.
#' @param bb_area A boundary box object with the area of interest.
#' @param facilities A sf object with the existing facilities.
#' @param candidate A sf object with the candidate locations for the new facilities.
#' @param n_fac The number of facilities that can be allocated.
#' @param weights A raster with the weights for the demand.
#' @param objectiveminutes The objective travel time in minutes.
#' @param dowscaling_model_type The type of model used for the spatial downscaling of the travel time layer.
#' @param mode The mode of transport.
#' @param res_output The spatial resolution of the friction raster (and of the analysis), in meters. If <1000, a spatial downscaling approach is used.
#' @param n_samples The number of samples to generate in the heuristic approach for identifying the best set of facilities to be allocated.
#' @keywords location-allocation
#' @export

allocation_discrete <- function(demand_raster, traveltime_raster=NULL, bb_area, facilities=NULL, candidate, n_fac = Inf, weights=NULL, objectiveminutes=10, dowscaling_model_type, mode, res_output, n_samples, par){

  # Check demand_raster is a raster layer
  if (!inherits(demand_raster, "RasterLayer")) {
    stop("Error: 'demand_raster' must be a raster layer.")
  }

  # Check traveltime is an output object from the traveltime function
  if (!is.null(traveltime_raster) & (!inherits(traveltime, "list") || length(traveltime) != 2 || !inherits(traveltime[[1]], "RasterLayer") || !inherits(traveltime[[2]], "list") || length(traveltime[[2]]) != 3)) {
    stop("Error: 'traveltime' must be an output object from the locationallocation::traveltime function.")
  }

  # Check bb_area is a numeric vector of length 4 (xmin, ymin, xmax, ymax)
  if (!inherits(bb_area, "sf") || nrow(bb_area) == 0) {
    stop("Error: 'bb_area' must be a non-empty sf polygon.")
  }

# Check facilities is a non-empty data frame
if (!is.null(facilities) & (!inherits(facilities, "sf") || nrow(facilities) == 0)) {
  stop("Error: 'facilities' must be a non-empty sf point geometry data frame.")
}

# Check candidates is a non-empty data frame
if (!inherits(candidate, "sf") || nrow(candidate) == 0) {
  stop("Error: 'candidate' must be a non-empty sf point geometry data frame.")
}

# Check n_fac is a numeric value
if (!is.numeric(n_fac) || length(n_fac) != 1) {
  stop("Error: 'n_fac' must be a numeric value.")
}

# Check weights is a raster layer
if (!is.null(weights) && !inherits(weights, "RasterLayer")) {
  stop("Error: 'weights' must be a raster layer.")
}

# Check objectiveminutes is a numeric value
if (!is.numeric(objectiveminutes) || length(objectiveminutes) != 1) {
  stop("Error: 'objectiveminutes' must be a numeric value.")
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

# Check n_samples is a numeric value
if (!is.numeric(n_samples) || length(n_samples) != 1) {
  stop("Error: 'n_samples' must be a numeric value.")
}


  ###


  if(is.null(traveltime_raster) & !is.null(facilities)){
    print("Travel time layer not detected. Running traveltime function first.")
    traveltime_raster_outer <- traveltime(facilities=facilities, bb_area=bb_area, dowscaling_model_type=dowscaling_model_type, mode=mode, res_output=res_output)

  } else if(is.null(facilities)) {

    out <- friction(bb_area=bb_area, mode=mode, res_output=res_output, dowscaling_model_type=dowscaling_model_type)

  } else if(!is.null(traveltime_raster)){


    traveltime_raster_outer <- traveltime_raster

  }


  else if(!is.null(traveltime_raster) & is.null(facilities)) {break}


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

  samples <- replicate(n_samples, sample(1:length(candidate), n_fac, replace = T))

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

  # outer <- function(n_samples, runner, paral=par, n_cores = parallel::detectCores() - 1) {
  #   if (paral==T) {
  #     # Determine OS
  #     if (.Platform$OS.type == "unix") {
  #       # Use mclapply for Unix-based systems
  #       result <- parallel::mclapply(1:n_samples, runner, mc.cores = n_cores)
  #     } else {
  #       # Use parLapply for Windows
  #       cl <- parallel::makeCluster(n_cores)
  #       result <- parallel::parLapply(cl, 1:n_samples, runner)
  #       parallel::stopCluster(cl)  # Clean up cluster
  #     }
  #   } else {
  #     # Fallback to standard lapply
  #     result <- pbapply::pblapply(1:n_samples, runner)
  #   }
  #
  #   return(result)
  # }

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
