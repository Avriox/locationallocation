#' @export
traveltime_plot <- function(traveltime, bb_area, facilities=NULL){

  require(ggplot2)

  ggplot2::ggplot()+
  theme_void()+
  geom_raster(data=na.omit(raster::as.data.frame(mask_raster_to_polygon(traveltime[[1]], bb_area), xy=T)), aes(x=x, y=y, fill=layer))+
  scale_fill_distiller(palette = "Spectral", direction = -1, name="minutes")+
  ggtitle("Travel time (minutes)")+
  geom_sf(data=sf::st_filter(facilities, bb_area), colour=ifelse(is.null(facilities), "transparent", "black"), size=0.5)


}
