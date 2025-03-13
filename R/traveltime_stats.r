#' A Cat Function
#'
#' This function allows you to express your love of cats.
#' @param love Do you love cats? Defaults to TRUE.
#' @keywords cats
#' @export


traveltime_stats <- function(traveltime, demand_raster, breaks=c(5, 10, 15, 30), objectiveminutes=15){

  traveltime <- raster::projectRaster(traveltime[[1]], demand_raster)

  data_curve <- data.frame(raster::values(traveltime), raster::values(demand_raster))

  data_curve <- na.omit(data_curve)

  colnames(data_curve) <- c("values.t1.", "values.pop.")

  data_curve <- data_curve %>%  dplyr::arrange(values.t1.) %>% dplyr::mutate(P15_cumsum=(cumsum(values.pop.)/sum(values.pop.))*100)

  data_curve$th <- cut(data_curve$values.t1., c(-Inf, breaks, Inf), labels=c(paste0("<", breaks), paste0(">", dplyr::last(breaks))))

  print(ggplot(data_curve)+
    theme_classic()+
    geom_step(aes(x=values.t1., y=P15_cumsum, colour=th))+
    ylab("Cum. pop.(%)")+
    xlab("travel time")+
    scale_colour_brewer(palette="Reds", direction = 1, name="minutes"))

return(paste0(round((sum(data_curve$values.pop.[data_curve$values.t1.<=objectiveminutes], na.rm=T)/sum(data_curve$values.pop.))*100 ,2), " % within the objectiveminutes threshold."))

}
