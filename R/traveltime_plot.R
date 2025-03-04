#' @export
traveltime_plot <- function(traveltime, facilities=NULL){

  require(ggplot2)

  ggplot2::ggplot()+
  theme_void()+
  geom_raster(data=na.omit(raster::as.data.frame(mask_raster_to_polygon(traveltime, boundary), xy=T)), aes(x=x, y=y, fill=layer))+
  scale_fill_distiller(palette = "Spectral", direction = -1, name="")+
  ggtitle("Travel time (minutes)")+
  geom_sf(data=fountains %>% st_filter(boundary), colour=ifelse(is.null(facilities), "transparent", "black"), size=0.5)


}
