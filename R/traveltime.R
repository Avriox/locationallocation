#' Generate a traveltime map
#'
#' This function generates a traveltime map based on the input facilities, bounding box area, and travel mode.
#' @param facilities A sf object with the existing facilities.
#' @param bb_area A boundary box object with the area of interest.
#' @param dowscaling_model_type The type of model used for the spatial downscaling of the travel time layer.
#' @param mode The mode of transport.
#' @param res_output The spatial resolution of the friction raster (and of the analysis), in meters. If <1000, a spatial downscaling approach is used.
#' @keywords cats
#' @export

traveltime <- function(facilities, bb_area, dowscaling_model_type, mode, res_output = 100){

  out <- friction(bb_area = bb_area, mode=mode, res_output=res_output, dowscaling_model_type=dowscaling_model_type)

  # assess current accessibility

  points = as.data.frame(sf::st_coordinates(facilities |> sf::st_filter(bb_area)))

  # Fetch the number of points
  temp <- dim(points)
  n.points <- temp[1]

    # Convert the points into a matrix
  xy.data.frame <- data.frame()
  xy.data.frame[1:n.points,1] <- points[,1]
  xy.data.frame[1:n.points,2] <- points[,2]
  xy.matrix <- as.matrix(xy.data.frame)

  # Run the accumulated cost algorithm to make the final output map. This can be quite slow (potentially hours).
  t1 <- gdistance::accCost(out[[3]], xy.matrix)

  t1 <- mask_raster_to_polygon(t1, bb_area)

return(list(t1, out))

}
