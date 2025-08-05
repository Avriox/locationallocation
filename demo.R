
library(devtools)
library(sf)
library(tidyverse)

setwd("C:/Users/Utente/OneDrive - IIASA/Current papers/cooling_centers_allocation/locationallocation/")

# usethis::use_pkgdown()
# usethis::use_gpl3_license()
# usethis::use_author(
#   given = "Giacomo",
#   family = "Falchetta",
#   role = c("aut", "cre"),
#   email = "giacomo.falchetta@cmcc.it",
#   comment = c(ORCID = "0000-0003-2607-2195")
# )
# usethis::use_citation()
# usethis::use_github_action("pkgdown")

##

devtools::document()

###

devtools::install_github("giacfalk/locationallocation")

pkgdown::build_site()

remove.packages("locationallocation")

# devtools::install_local(getwd())
#
# library(locationallocation)

demo_data_load()

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

ggsave("traveltime_map_fountains.png", height = 5, width = 5, scale=1.3)

###

traveltime_stats(traveltime = out_tt, demand_raster = pop, breaks=c(5, 10, 15, 30), objectiveminutes=5)

###

output_allocation <- allocation(demand_raster = pop, traveltime_raster=out_tt, bb_area = boundary, facilities=fountains, weights=NULL, objectiveminutes=15, objectiveshare=0.99, heur="max", dowscaling_model_type="lm", mode="walk", res_output=100)

allocation_plot(output_allocation, bb_area = boundary)

ggsave("allocation_15mins_fountains.png", height = 5, width = 5, scale=1.3)

###

output_allocation_weighted <- allocation(demand_raster = pop, traveltime_raster=out_tt, bb_area = boundary, facilities=fountains, weights=hotdays, objectiveminutes=15, objectiveshare=0.99, heur="max", dowscaling_model_type="lm", mode="walk", res_output=100, approach = "norm")

allocation_plot(output_allocation_weighted, bb_area = boundary)

ggsave("allocation_15mins_fountains_weighted.png", height = 5, width = 5, scale=1.3)


###

output_allocation_weighted_absweights <- allocation(demand_raster = pop, traveltime_raster=out_tt, bb_area = boundary, facilities=fountains, weights=hotdays, objectiveminutes=15, objectiveshare=0.99, heur="max", dowscaling_model_type="lm", mode="walk", res_output=100, approach = "absweights")

allocation_plot(output_allocation_weighted_absweights, bb_area = boundary)

ggsave("allocation_15mins_fountains_weighted_absweights.png", height = 5, width = 5, scale=1.3)


####

plot(output_allocation_weighted_absweights[[1]], col="red")
plot(output_allocation_weighted[[1]], col="blue", add=T)
plot(output_allocation[[1]], col="black", add=T)

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

output_allocation_discrete_targetshare <- allocation_discrete(demand_raster = pop, traveltime_raster=NULL, bb_area = boundary, facilities=fountains, candidate=candidates, n_fac = 5, objectiveshare=0.75, weights=NULL, objectiveminutes=15, dowscaling_model_type="lm", mode="walk", res_output=100, n_samples=1000, par=T)

allocation_plot_discrete(output_allocation_discrete_targetshare, bb_area = boundary)

ggsave("allocation_discrete_fountains_targetshare.png", height = 5, width = 5, scale=1.3)


set.seed(333)

output_allocation_discrete_from_scratch <- allocation_discrete(demand_raster = pop, traveltime_raster=NULL, bb_area = boundary, facilities=NULL, candidate=candidates, n_fac = 10, weights=NULL, objectiveminutes=15, dowscaling_model_type="lm", mode="walk", res_output=1000, n_samples=1000, par=T)

allocation_plot_discrete(output_allocation_discrete_from_scratch, bb_area = boundary)

ggsave("allocation_discrete_fromscratch_fountains.png", height = 5, width = 5, scale=1.3)
