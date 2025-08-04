#' Plot results of the traveltime function
#'
#' This function is used to plot the results of the traveltime function. It shows the travel time from the facilities to the area of interest.
#' @param traveltime The output of the traveltime function.
#' @param bb_area A boundary box object with the area of interest.
#' @param facilities A sf object with the existing facilities.
#' @param contour_traveltime A numeric vector with the contour thresholds for the travel time.
#' @keywords reporting
#' @export

traveltime_plot <- function(traveltime, bb_area, facilities=NULL, contour_traveltime = NULL){

  # Check traveltime is an output object from the traveltime function
  if (!inherits(traveltime, "list") || length(traveltime) != 2 || !inherits(traveltime[[1]], "RasterLayer") || !inherits(traveltime[[2]], "list") || length(traveltime[[2]]) != 3) {
    stop("Error: 'traveltime' must be an output object from the locationallocation::traveltime function.")
  }

  # Check bb_area is a numeric vector of length 4 (xmin, ymin, xmax, ymax)
  if (!inherits(bb_area, "sf") || nrow(bb_area) == 0) {
    stop("Error: 'bb_area' must be a non-empty sf polygon.")
  }

  # Check facilities is a non-empty data frame
  if (!inherits(facilities, "sf") || nrow(facilities) == 0) {
    stop("Error: 'facilities' must be a non-empty sf point geometry data frame.")
  }

  if (!is.null(contour_traveltime) && !is.numeric(contour_traveltime)) {
    stop("Error: 'contour_traveltime' must be a numeric vector.")
  }

  require(ggplot2)

  p <- ggplot2::ggplot()+
  theme_void()+
  geom_raster(data=na.omit(raster::as.data.frame(mask_raster_to_polygon(traveltime[[1]], bb_area), xy=T)), aes(x=x, y=y, fill=layer))+
  scale_fill_distiller(palette = "Spectral", direction = -1, name="minutes")+
  ggtitle("Travel time (minutes)")+
  geom_sf(data=sf::st_filter(facilities, bb_area), colour=ifelse(is.null(facilities), "transparent", "black"), size=0.5)

  if(!is.null(contour_traveltime)){

    p +
      geom_contour(data=na.omit(raster::as.data.frame(mask_raster_to_polygon(traveltime[[1]], bb_area), xy=T)), aes(x=x, y=y, z = layer), color = "black", breaks = contour_traveltime)

  } else{

    p

  }


}
