
library(devtools)
devtools::document()

library(locationallocation)

demo_data_load()

plot(pop)
plot(boundary$geom, add=T, col="transparent")
plot(fountains$geom, add=T, col="blue")

####

out_tt <- traveltime(facilities=fountains, bb_area=boundary, dowscaling_model_type="lm", mode="walk", res_output=1000)

traveltime_plot(traveltime=out_tt, facilities = fountains)

output_allocation <- allocation(demand_raster = pop, sf_area = boundary, facilities=fountains, traveltime=out_tt, weights=NULL, objectiveminutes=15, objectiveshare=0.01, heur="max")

allocation_plot(output_allocation)

####

candidates <- st_sample(boundary, 30)

output_allocation_discrete <- allocation_discrete(demand_raster = pop, sf_area = boundary, facilities=fountains, candidate=candidates, max_fac = 10, traveltime_raster=out_tt, weights=NULL, objectiveminutes=15)

allocation_plot_discrete(output_allocation_discrete)

output_allocation_discrete_from_scratch <- allocation_discrete(demand_raster = pop, sf_area = boundary, facilities=NULL, candidate=candidates, max_fac = 10, traveltime_raster=NULL, weights=NULL, objectiveminutes=15)

allocation_plot_discrete(output_allocation_discrete_from_scratch)

