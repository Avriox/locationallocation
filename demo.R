
library(devtools)
library(sf)
library(tidyverse)

setwd("C:/Users/falchetta/OneDrive - IIASA/Current papers/cooling_centers_allocation/locationallocation/")

##

devtools::install_github("giacfalk/locationallocation")

library(locationallocation)

##

demo_data_load()

#######
#######
#######

terra::plot(pop)
terra::plot(boundary$geom, add=T, col="transparent")
terra::plot(sf::st_filter(fountains, boundary)$geom, add=T, col="blue")

#
png("map_demand_existing_facilities.png", height = 1000, width = 1500, res=200)
terra::plot(pop)
terra::plot(boundary$geom, add=T, col="transparent")
terra::plot(sf::st_filter(fountains, boundary)$geom, add=T, col="blue")
dev.off()
#

####

out_tt <- traveltime(facilities=fountains, bb_area=boundary, dowscaling_model_type="lm", mode="walk", res_output=100)

traveltime_plot(traveltime=out_tt,  bb_area=boundary, facilities = fountains, contour_traveltime=NULL)
traveltime_plot(traveltime=out_tt,  bb_area=boundary, facilities = fountains, contour_traveltime=15)

ggsave("traveltime_map_fountains_walk.png", height = 5, width = 5, scale=1.3)

####

out_tt2 <- traveltime(facilities=fountains, bb_area=boundary, dowscaling_model_type="lm", mode="fastest", res_output=100)

traveltime_plot(traveltime=out_tt2,  bb_area=boundary, facilities = fountains, contour_traveltime=NULL)
traveltime_plot(traveltime=out_tt2,  bb_area=boundary, facilities = fountains, contour_traveltime=15)

ggsave("traveltime_map_fountains_fastest.png", height = 5, width = 5, scale=1.3)


###

traveltime_stats(traveltime = out_tt, demand_raster = pop, breaks=c(5, 10, 15, 30), objectiveminutes=5)

ggsave("traveltime_curve_fountains_waòl.png", height = 3, width = 5, scale=1.3)

traveltime_stats(traveltime = out_tt2, demand_raster = pop, breaks=c(5, 10, 15, 30), objectiveminutes=5)

ggsave("traveltime_curve_fountains_fastest.png", height = 3, width = 5, scale=1.3)


###

output_allocation <- allocation(demand_raster = pop, traveltime_raster=out_tt, bb_area = boundary, facilities=fountains, weights=NULL, objectiveminutes=15, objectiveshare=0.99, heur="max", dowscaling_model_type="lm", mode="walk", res_output=100)

allocation_plot(output_allocation, bb_area = boundary)

ggsave("allocation_15mins_fountains.png", height = 5, width = 5, scale=1.3)

###

output_allocation_weighted <- allocation(demand_raster = pop, traveltime_raster=out_tt, bb_area = boundary, facilities=fountains, weights=hotdays, objectiveminutes=15, objectiveshare=0.99, heur="max", dowscaling_model_type="lm", mode="walk", res_output=100, approach = "norm")

allocation_plot(output_allocation_weighted, bb_area = boundary)

ggsave("allocation_15mins_fountains_weighted.png", height = 5, width = 5, scale=1.3)


output_allocation_weighted_expdemand2 <- allocation(demand_raster = pop, traveltime_raster=out_tt, bb_area = boundary, facilities=fountains, weights=hotdays, objectiveminutes=15, objectiveshare=0.99, heur="max", dowscaling_model_type="lm", mode="walk", res_output=100, approach = "norm", exp_demand = 2)

allocation_plot(output_allocation_weighted_expdemand2, bb_area = boundary)

ggsave("allocation_15mins_fountains_weighted_exp_demand2.png", height = 5, width = 5, scale=1.3)


####
####

set.seed(333)

candidates <- st_sample(boundary, 20)

set.seed(333)

### add allocation by target share (similar to allocation, but force pixel selection among locations where facilities can be placed)

output_allocation_discrete <- allocation_discrete(demand_raster = pop, traveltime_raster=NULL, bb_area = boundary, facilities=fountains, candidate=candidates, n_fac = 2, weights=NULL, objectiveminutes=15, dowscaling_model_type="lm", mode="walk", res_output=100, n_samples=1000, par=T)

allocation_plot_discrete(output_allocation_discrete, bb_area = boundary)

ggsave("allocation_discrete_fountains.png", height = 5, width = 5, scale=1.3)

###

set.seed(333)

output_allocation_discrete_weighted <- allocation_discrete(demand_raster = pop, traveltime_raster = out_tt, bb_area = boundary, facilities=fountains, candidate=candidates, n_fac = 5, weights=hotdays, objectiveminutes=15, dowscaling_model_type="lm", mode="walk", res_output=100, n_samples=1000, par=T, exp_demand = 1, approach = "norm")

allocation_plot_discrete(output_allocation_discrete_weighted, bb_area = boundary)

ggsave("allocation_discrete_fountains_weighted.png", height = 5, width = 5, scale=1.3)

###

###

set.seed(333)

output_allocation_discrete_weighted_2 <- allocation_discrete(demand_raster = pop, traveltime_raster = out_tt, bb_area = boundary, facilities=fountains, candidate=candidates, n_fac = 5, weights=hotdays, objectiveminutes=15, dowscaling_model_type="lm", mode="walk", res_output=100, n_samples=1000, par=T, exp_demand = 2, approach = "norm")

allocation_plot_discrete(output_allocation_discrete_weighted_2, bb_area = boundary)

ggsave("allocation_discrete_fountains_weighted_2.png", height = 5, width = 5, scale=1.3)

###

set.seed(333)

output_allocation_discrete_targetshare <- allocation_discrete(demand_raster = pop, traveltime_raster=NULL, bb_area = boundary, facilities=fountains, candidate=candidates, n_fac = 15, objectiveshare=0.95, weights=NULL, objectiveminutes=15, dowscaling_model_type="lm", mode="walk", res_output=100, n_samples=10000, par=T)

allocation_plot_discrete(output_allocation_discrete_targetshare, bb_area = boundary)

ggsave("allocation_discrete_fountains_targetshare.png", height = 5, width = 5, scale=1.3)


set.seed(333)

output_allocation_discrete_from_scratch <- allocation_discrete(demand_raster = pop, traveltime_raster=NULL, bb_area = boundary, facilities=NULL, candidate=candidates, n_fac = 10, weights=NULL, objectiveminutes=15, dowscaling_model_type="lm", mode="walk", res_output=1000, n_samples=1000, par=T)

allocation_plot_discrete(output_allocation_discrete_from_scratch, bb_area = boundary)

ggsave("allocation_discrete_fromscratch_fountains.png", height = 5, width = 5, scale=1.3)
