#' @export
traveltime_plot <- function(t1){


ggplot()+
  theme_void()+
  geom_raster(data=na.omit(as.data.frame(t1, xy=T)), aes(x=x, y=y, fill=layer))+
  scale_fill_distiller(palette = "Spectral", direction = 1, name="")+
  ggtitle("Travel time (minutes))")

}
