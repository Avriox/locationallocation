#' Demo data for locationallocation
#'
#' This function loads in the global environment four demo data objects to test the functions of the locationallocation package:
#' - boundary: a sf polygon geometry object representing the administrative boundary of the city of Naples, Italy
#' - fountains: a sf point geometry object representing the water fountains in the city of Naples, Italy
#' - pop: a raster Raster object representing the population density in the city of Naples, Italy
#' - hotdays: a raster Raster object representing the number of hot days in the city of Naples, Italy
#' @keywords vignette
#' @export

demo_data_load <- function(){

boundary <- sf::read_sf(system.file("extdata", "napoli.gpkg", package = "locationallocation"))
assign("boundary", boundary, envir = .GlobalEnv)

fountains <- sf::read_sf(system.file("extdata", "napoli_water_fountains.gpkg", package = "locationallocation"))
assign("fountains", fountains, envir = .GlobalEnv)

pop <- raster::raster(system.file("extdata", "pop_napoli.tif", package = "locationallocation"))
assign("pop", pop, envir = .GlobalEnv)

hotdays <- raster::raster(system.file("extdata", "hotdays_napoli.tif", package = "locationallocation"))
assign("hotdays", hotdays, envir = .GlobalEnv)

}


