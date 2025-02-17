
library(devtools)
devtools::document()

library(locationallocation)

demo_data_load()

plot(pop)
plot(boundary$geom, add=T, col="transparent")
plot(fountains$geom, add=T, col="blue")

##

out_tt <- traveltime(facilities=fountains, bb_area=boundary, dowscaling_model_type="lm", mode="walk", res_output=100)

traveltime_plot(t1=out_tt, facilities = fountains)

output_allocation <- allocation(demand_raster = pop, sf_area = boundary, facilities=fountains, traveltime=out_tt, weights=NULL, objectiveminutes=15, objectiveshare=0.02, heur="max")

allocation_plot(output_allocation)

####

candidate <- st_sample(boundary, 30)

output_allocation_discrete <- allocation_discrete(demand_raster = pop, sf_area = boundary, facilities=fountains, candidate=candidate, traveltime=out_tt, weights=NULL, objectiveminutes=25, objectiveshare=0.01)
