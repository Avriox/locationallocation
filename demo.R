
library(devtools)

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

devtools::install_github("giacfalk/locationallocation")

pkgdown::build_site()

remove.packages("locationallocation")

##

devtools::document()

###

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

traveltime_plot(traveltime=out_tt,  bb_area=boundary, facilities = fountains)

ggsave("traveltime_map_fountains.png", height = 5, width = 5, scale=1.3)

###

traveltime_stats(traveltime = out_tt, demand_raster = pop, breaks=c(5, 10, 15, 30), objectiveminutes=5)

###

output_allocation <- allocation(demand_raster = pop, traveltime_raster=out_tt, bb_area = boundary, facilities=fountains, weights=NULL, objectiveminutes=15, objectiveshare=0.99, heur="max", dowscaling_model_type="lm", mode="walk", res_output=100)

allocation_plot(output_allocation, bb_area = boundary)

ggsave("allocation_15mins_fountains.png", height = 5, width = 5, scale=1.3)

###

output_allocation_weighted <- allocation(demand_raster = pop, traveltime_raster=out_tt, bb_area = boundary, facilities=fountains, weights=hotdays, objectiveminutes=15, objectiveshare=0.99, heur="max", dowscaling_model_type="lm", mode="walk", res_output=100)

allocation_plot(output_allocation_weighted, bb_area = boundary)

ggsave("allocation_15mins_fountains_weighted.png", height = 5, width = 5, scale=1.3)


####

candidates <- st_sample(boundary, 30)

output_allocation_discrete <- allocation_discrete(demand_raster = pop, traveltime_raster = out_tt, bb_area = boundary, facilities=fountains, candidate=candidates, n_fac = 10, weights=NULL, objectiveminutes=15, dowscaling_model_type="lm", mode="walk", res_output=100, n_samples=100, par=T)

allocation_plot_discrete(output_allocation_discrete, bb_area = boundary)

ggsave("allocation_discrete_fountains.png", height = 5, width = 5, scale=1.3)

###

set.seed(333)

output_allocation_discrete_from_scratch <- allocation_discrete(demand_raster = pop, traveltime_raster=NULL, bb_area = boundary, facilities=NULL, candidate=candidates, n_fac = 10, weights=NULL, objectiveminutes=15, dowscaling_model_type="lm", mode="walk", res_output=100, n_samples=100)

allocation_plot_discrete(output_allocation_discrete_from_scratch, bb_area = boundary)

ggsave("allocation_discrete_fromscratch_fountains.png", height = 5, width = 5, scale=1.3)
