#' @export
traveltime <- function(facilities, bb_area, dowscaling_model_type, mode, res_output = 100, friction=NULL){

assign("boundary", bb_area, envir = .GlobalEnv)

  friction(bb_area = bb_area, mode=mode, res_output=res_output)

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
  t1 <- gdistance::accCost(T.GC, xy.matrix)

  assign("traveltime_raster", t1, envir = .GlobalEnv)

return(t1)

}
