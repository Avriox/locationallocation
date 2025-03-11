# locationallocation
 
locationallocation: an R package to solve Maximal Coverage Location-Allocation problems using geospatial data

<p align="center">
<img src="https://github.com/giacfalk/locationallocation/blob/main/logo.png?raw=true" alt="" width="300"/>
</p>


## Background

<div style="text-align: justify">

</div>

## Installation

Install with:

``` r
library(devtools)
install_github("https://github.com/giacfalk/locationallocation")
```
## Operation

Operate the package as follows. 

First, load the package.

``` r
library(locationallocation)
```

Then, run the `demo_data_load()` function to load a set of demo datasets to run the package's function. The demo data contains the coordinate-point location of public drinking water fountains in the city of Naples, Italy, as well as a gridded population raster data from GHS-POP, a 100-m resolution map of heat hazard (number of days with Wet-Bulb Globe Temperature greater than 25° C in the historical period 2008-2017, obtained from the UrbClim model), and the administrative boundaries of the city. 

<p align="center">
<img src="https://github.com/giacfalk/locationallocation/blob/main/outputs/map_demand_existing_facilities.png?raw=true" alt="" width="600"/>
</p>


Then, we can use the `traveltime` function to generate a map of the current accessibility to the facility point sf input (here, fountains) within the specified geographical boundaries, and with a choosen travel mode (walk or fastest), and a given output spatial resolution (in meters; achieved using disseving spatial downscaling techniques). Once the function has run successfully, we can generate a map of the resulting layer using the `traveltime_plot` function. 

``` r
demo_data_load()

out_tt <- traveltime(facilities=fountains, bb_area=boundary, dowscaling_model_type="lm", mode="walk", res_output=100)

traveltime_plot(traveltime=out_tt,  bb_area=boundary, facilities = fountains)

```
<p align="center">
<img src="https://github.com/giacfalk/locationallocation/blob/main/outputs/traveltime_map_fountains.png?raw=true" alt="" width="600"/>
</p>

XXX

``` r
output_allocation <- allocation(demand_raster = pop, traveltime_raster=out_tt, bb_area = boundary, facilities=fountains, weights=NULL, objectiveminutes=15, objectiveshare=0.01, heur="max", dowscaling_model_type="lm", mode="walk", res_output=100)

allocation_plot(output_allocation, bb_area = boundary)

```
<p align="center">
<img src="https://github.com/giacfalk/locationallocation/blob/main/outputs/allocation_15mins_fountains.png?raw=true" alt="" width="600"/>
</p>

XX

``` r
output_allocation_weighted <- allocation(demand_raster = pop, traveltime_raster=out_tt, bb_area = boundary, facilities=fountains, weights=hotdays, objectiveminutes=15, objectiveshare=0.01, heur="max", dowscaling_model_type="lm", mode="walk", res_output=100)

allocation_plot(output_allocation_weighted, bb_area = boundary)
```

<p align="center">
<img src="https://github.com/giacfalk/locationallocation/blob/main/outputs/allocation_15mins_fountains_weighted.png?raw=true" alt="" width="600"/>
</p>

XX

``` r
candidates <- st_sample(boundary, 30)

output_allocation_discrete <- allocation_discrete(demand_raster = pop, traveltime_raster=NULL, bb_area = boundary, facilities=fountains, candidate=candidates, max_fac = 10, weights=NULL, objectiveminutes=15, dowscaling_model_type="lm", mode="walk", res_output=100, n_samples=100)

allocation_plot_discrete(output_allocation_discrete, bb_area = boundary)
```

<p align="center">
<img src="https://github.com/giacfalk/locationallocation/blob/main/outputs/allocation_discrete_fountains.png?raw=true" alt="" width="600"/>
</p>

XX

``` r
set.seed(333)

output_allocation_discrete_from_scratch <- allocation_discrete(demand_raster = pop, traveltime_raster=NULL, bb_area = boundary, facilities=NULL, candidate=candidates, max_fac = 10, weights=NULL, objectiveminutes=15, dowscaling_model_type="lm", mode="walk", res_output=100, n_samples=100)

allocation_plot_discrete(output_allocation_discrete_from_scratch, bb_area = boundary)
```
<p align="center">
<img src="https://github.com/giacfalk/locationallocation/blob/main/outputs/allocation_discrete_fromscratch_fountains.png?raw=true" alt="" width="600"/>
</p>


## Disclaimer

This package is developed by a data user. 
