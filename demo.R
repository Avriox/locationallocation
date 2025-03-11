
setwd("C:/Users/Utente/OneDrive - IIASA/Current papers/cooling_centers_allocation/locationallocation/")

library(devtools)
devtools::document()

library(locationallocation)

demo_data_load()

raster::plot(pop)
raster::plot(boundary$geom, add=T, col="transparent")
raster::plot(fountains$geom, add=T, col="blue")

####

out_tt <- traveltime(facilities=fountains, bb_area=boundary, dowscaling_model_type="lm", mode="walk", res_output=100)

traveltime_plot(traveltime=out_tt,  bb_area=boundary, facilities = fountains)

ggsave("traveltime_map_fountains.png", height = 5, width = 5, scale=1.3)

###

output_allocation <- allocation(demand_raster = pop, traveltime_raster=out_tt, bb_area = boundary, facilities=fountains, weights=NULL, objectiveminutes=15, objectiveshare=0.01, heur="max", dowscaling_model_type="lm", mode="walk", res_output=100)

allocation_plot(output_allocation, bb_area = boundary)

ggsave("allocation_15mins_fountains.png", height = 5, width = 5, scale=1.3)

###

output_allocation_weighted <- allocation(demand_raster = pop, traveltime_raster=out_tt, bb_area = boundary, facilities=fountains, weights=hotdays, objectiveminutes=15, objectiveshare=0.01, heur="max", dowscaling_model_type="lm", mode="walk", res_output=100)

allocation_plot(output_allocation_weighted, bb_area = boundary)

ggsave("allocation_15mins_fountains_weighted.png", height = 5, width = 5, scale=1.3)


####

candidates <- st_sample(boundary, 30)

output_allocation_discrete <- allocation_discrete(demand_raster = pop, traveltime_raster=NULL, bb_area = boundary, facilities=fountains, candidate=candidates, max_fac = 10, weights=NULL, objectiveminutes=15, dowscaling_model_type="lm", mode="walk", res_output=100, n_samples=100)

allocation_plot_discrete(output_allocation_discrete, bb_area = boundary)

ggsave("allocation_discrete_fountains.png", height = 5, width = 5, scale=1.3)

###

set.seed(333)

output_allocation_discrete_from_scratch <- allocation_discrete(demand_raster = pop, traveltime_raster=NULL, bb_area = boundary, facilities=NULL, candidate=candidates, max_fac = 10, weights=NULL, objectiveminutes=15, dowscaling_model_type="lm", mode="walk", res_output=100, n_samples=100)

allocation_plot_discrete(output_allocation_discrete_from_scratch, bb_area = boundary)

ggsave("allocation_discrete_fromscratch_fountains.png", height = 5, width = 5, scale=1.3)
