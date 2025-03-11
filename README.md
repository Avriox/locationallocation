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

Operate the package as follows,

``` r
library(locationallocation)
```

``` r
demo_data_load()

out_tt <- traveltime(facilities=fountains, bb_area=boundary, dowscaling_model_type="lm", mode="walk", res_output=100)

traveltime_plot(traveltime=out_tt,  bb_area=boundary, facilities = fountains)

```

``` r
output_allocation <- allocation(demand_raster = pop, traveltime_raster=out_tt, bb_area = boundary, facilities=fountains, weights=NULL, objectiveminutes=15, objectiveshare=0.01, heur="max", dowscaling_model_type="lm", mode="walk", res_output=100)

allocation_plot(output_allocation, bb_area = boundary)

```


``` r
output_allocation_weighted <- allocation(demand_raster = pop, bb_area = boundary, facilities=fountains, weights=hotdays, objectiveminutes=15, objectiveshare=0.01, heur="max", dowscaling_model_type="lm", mode="walk", res_output=1000)

allocation_plot(output_allocation_weighted)
```

``` r
output_allocation_weighted <- allocation(demand_raster = pop, traveltime_raster=out_tt, bb_area = boundary, facilities=fountains, weights=hotdays, objectiveminutes=15, objectiveshare=0.01, heur="max", dowscaling_model_type="lm", mode="walk", res_output=100)

allocation_plot(output_allocation_weighted, bb_area = boundary)
```

``` r
candidates <- st_sample(boundary, 30)

output_allocation_discrete <- allocation_discrete(demand_raster = pop, traveltime_raster=NULL, bb_area = boundary, facilities=fountains, candidate=candidates, max_fac = 10, weights=NULL, objectiveminutes=15, dowscaling_model_type="lm", mode="walk", res_output=100, n_samples=100)

allocation_plot_discrete(output_allocation_discrete, bb_area = boundary)
```

``` r
set.seed(333)

output_allocation_discrete_from_scratch <- allocation_discrete(demand_raster = pop, traveltime_raster=NULL, bb_area = boundary, facilities=NULL, candidate=candidates, max_fac = 10, weights=NULL, objectiveminutes=15, dowscaling_model_type="lm", mode="walk", res_output=100, n_samples=100)

allocation_plot_discrete(output_allocation_discrete_from_scratch, bb_area = boundary)
```

## Disclaimer

This package is developed by a data user. 
