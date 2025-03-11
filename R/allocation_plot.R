#' A Cat Function
#'
#' This function allows you to express your love of cats.
#' @param love Do you love cats? Defaults to TRUE.
#' @keywords cats
#' @export
#' @examples

allocation_plot <- function(output_allocation, bb_area){

  require(ggplot2)

  ggplot2::ggplot()+
    theme_void()+
    geom_raster(data=na.omit(raster::as.data.frame(mask_raster_to_polygon(output_allocation[[2]], bb_area), xy=T)), aes(x=x, y=y, fill=layer))+
    scale_fill_distiller(palette = "Spectral", direction = -1, name="minutes")+
    geom_sf(data=st_as_sf(output_allocation[[1]]), colour="black", size=2.5)+
    ggtitle("Potential locations for new facilities")
}

#' A Cat Function
#'
#' This function allows you to express your love of cats.
#' @param love Do you love cats? Defaults to TRUE.
#' @keywords cats
#' @export
#' @examples

allocation_plot_discrete <- function(output_allocation, bb_area){

  ggplot2::ggplot()+
    theme_void()+
    geom_raster(data=na.omit(raster::as.data.frame(mask_raster_to_polygon(output_allocation[[2]], bb_area), xy=T)), aes(x=x, y=y, fill=layer))+
    scale_fill_distiller(palette = "Spectral", direction = -1, name="minutes")+
    geom_sf(data=st_as_sf(output_allocation[[1]]), colour="black", size=2.5)+
    ggtitle(paste0("Potential locations for new facilities. Coverage attained: ", (1 - round(output_allocation[[3]], 2))*100, " %"))
}
