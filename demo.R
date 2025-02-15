
library(devtools)
devtools::document()

library(locationallocation)

demo_data_load()

traveltime(facilities=fountains, bb_area=boundary, dowscaling_model_type="lm", mode="walk")
