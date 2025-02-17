#' @export
allocation_discrete <- function(demand_raster, sf_area, facilities=facilities, traveltime=traveltime_raster, weights=NULL, objectiveminutes=10, objectiveshare=0.01, heur="max"){

  outer <- list()

  ff <- function(i){

  points = st_coordinates(candidate$geometry)[-i,]
 outer[[i]] <- (cellStats(pop_wbgt, 'sum', na.rm = TRUE)/totalriskconstant - cellStats(pop_wbgt_save, 'sum', na.rm = TRUE)/totalriskconstant)

  }

outer <- lapply(1:nrow(candidate), runner)

return(outer)

}
