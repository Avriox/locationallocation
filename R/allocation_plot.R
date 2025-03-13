#' Plot results of the allocation and allocation_discrete functions
#'
#' This function is used to plot the results of the allocation and allocation_discrete functions. It shows the potential locations for new facilities and the coverage attained.
#' @param output_allocation The output of the allocation or allocation_discrete functions.
#' @param bb_area A boundary box object with the area of interest.
#' @keywords reporting
#' @export

allocation_plot <- function(output_allocation, bb_area){

  require(ggplot2)

  ggplot2::ggplot()+
    theme_void()+
    geom_raster(data=na.omit(raster::as.data.frame(mask_raster_to_polygon(output_allocation[[2]], bb_area), xy=T)), aes(x=x, y=y, fill=layer))+
    scale_fill_distiller(palette = "Spectral", direction = -1, name="minutes")+
    geom_sf(data=st_as_sf(output_allocation[[1]]), colour="black", size=2.5)+
    ggtitle("Potential locations for new facilities")
}


allocation_plot_discrete <- function(output_allocation, bb_area){

  ggplot2::ggplot()+
    theme_void()+
    geom_raster(data=na.omit(raster::as.data.frame(mask_raster_to_polygon(output_allocation[[2]], bb_area), xy=T)), aes(x=x, y=y, fill=layer))+
    scale_fill_distiller(palette = "Spectral", direction = -1, name="minutes")+
    geom_sf(data=st_as_sf(output_allocation[[1]]), colour="black", size=2.5)+
    ggtitle(paste0("Potential locations for new facilities. Coverage attained: ", (1 - round(output_allocation[[3]], 2))*100, " %"))
}
