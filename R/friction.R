#' @export
friction <- function(bb_area, mode, res_output, dowscaling_model_type){

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

