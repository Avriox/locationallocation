#' Download and optionally downscale the friction surface layer to conduct location-allocation analysis.
#'
#' This function retrieves the friction surface layer from the Malaria Atlas Project database and optionally downscales it to the spatial resolution of the analysis using road network data from OpenStreetMap. The function returns the friction surface layer, the transition matrix, and the geocorrection matrix.
#' @param bb_area A spatial object representing the area of interest.
#' @param mode The mode of transport. Options are "fastest" and "walk".
#' @param res_output The spatial resolution of the friction raster (and of the analysis), in meters. If <1000, a spatial downscaling approach is used.
#' @param dowscaling_model_type The type of model used for the spatial downscaling of the friction layer. Options are "lm" (linear model) and "rf" (random forest).
#' @keywords cats
#' @export

friction <- function(bb_area, mode, res_output, dowscaling_model_type){

  # Check bb_area is a numeric vector of length 4 (xmin, ymin, xmax, ymax)
  if (!inherits(bb_area, "sf") || nrow(bb_area) == 0) {
    stop("Error: 'bb_area' must be a non-empty sf polygon.")
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

  # Check dowscaling_model_type is a non-empty character string
  allowed_downscaling <- c("lm", "rf")
  if (!is.character(dowscaling_model_type) || length(dowscaling_model_type) != 1 || !(dowscaling_model_type %in% allowed_downscaling)) {
    stop("Error: 'dowscaling_model_type' must either be 'lm' or 'rf'.")
  }

handle <- curl::new_handle(timeout = 120)

if(mode =="fastest"){


  friction_layer <- malariaAtlas::getRaster(dataset_id = "Accessibility__201501_Global_Travel_Speed_Friction_Surface",
                                      extent = matrix(sf::st_bbox(bb_area), ncol=2))

} else if(mode =="walk"){


  friction_layer <- malariaAtlas::getRaster(dataset_id = "Accessibility__202001_Global_Walking_Only_Friction_Surface",
                                      extent = matrix(sf::st_bbox(bb_area), ncol=2))

} else{ break}


friction_layer <- raster::raster(friction_layer)

###

if (res_output<1000){

  x <- osmdata::opq(bbox = st_bbox(bb_area)) %>%
    osmdata::add_osm_feature(key = 'highway') %>%
    osmdata::osmdata_sf ()

  r <- raster::raster(raster::extent(bb_area |>st_transform(3395)), res = res_output, crs=st_crs(3395)$proj4string)

  streets <- fasterize::fasterize(st_buffer(st_transform(x$osm_lines, 3395), res_output), r, background=NA)

  streets = terra::rast(streets)

  d <- terra::distance(streets)

  d <- terra::project(d, y=st_crs(4326)$proj4string)
  terra::values(d) <- ifelse(terra::values(d)<0, 0, terra::values(d))
  terra::values(d) <- ifelse(is.na(terra::values(d)), 0, terra::values(d))

  d <- raster::raster(d)

  d_2 <- d

  d <- raster::stack(d, d_2)

  names(d) <-paste0("l", 1:raster::nlayers(d))

  min_iter <- 2 # Minimum number of iterations
  max_iter <- 10 # Maximum number of iterations
  p_train <- 0.5 # Subsampling of the initial data

  res_rf <- dissever::dissever(
    coarse = friction_layer, # stack of fine resolution covariates
    fine = d, # coarse resolution raster
    method = dowscaling_model_type, # regression method used for disseveration
    p = p_train, # proportion of pixels sampled for training regression model
    min_iter = min_iter, # minimum iterations
    max_iter = max_iter, # maximum iterations
    verbose=T
  )

  friction_layer <- res_rf$map

} else{

  friction_layer <- friction_layer

}

##########

Tr <- gdistance::transition(friction_layer, function(x) 1/mean(x), 16) # RAM intensive, can be very slow for large areas

T.GC <- gdistance::geoCorrection(Tr)

return(list(friction_layer, Tr, T.GC))

}

