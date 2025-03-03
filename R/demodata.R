#' @export
demo_data_load <- function(){

boundary <- sf::read_sf(system.file("extdata", "napoli.gpkg", package = "locationallocation"))
assign("boundary", boundary, envir = .GlobalEnv)

fountains <- sf::read_sf(system.file("extdata", "napoli_water_fountains.gpkg", package = "locationallocation"))
assign("fountains", fountains, envir = .GlobalEnv)

pop <- raster::raster(system.file("extdata", "pop_napoli.tif", package = "locationallocation"))
assign("pop", pop, envir = .GlobalEnv)

}


