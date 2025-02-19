#' @export
allocation_plot <- function(output_allocation){

  ggplot()+
    theme_void()+
    geom_raster(data=na.omit(raster::as.data.frame(mask_raster_to_polygon(output_allocation[[2]], boundary), xy=T)), aes(x=x, y=y, fill=layer))+
    scale_fill_distiller(palette = "Spectral", direction = -1)+
    geom_sf(data=st_as_sf(output_allocation[[1]]) |> st_filter(boundary), colour="black", size=2.5)+
    ggtitle("Potential locations for new facilities")
}

#' @export
allocation_plot_discrete <- function(output_allocation){

  ggplot()+
    theme_void()+
    geom_raster(data=na.omit(raster::as.data.frame(mask_raster_to_polygon(output_allocation[[2]], boundary), xy=T)), aes(x=x, y=y, fill=layer))+
    scale_fill_distiller(palette = "Spectral", direction = -1)+
    geom_sf(data=st_as_sf(output_allocation[[1]]) |> st_filter(boundary), colour="black", size=2.5)+
    ggtitle(paste0("Potential locations for new facilities. Coverage attained: ", 100 - round(output_allocation[[3]]*100, 2), " %"))
}
