# locationallocation
 
locationallocation: an R package to solve Maximal Coverage Location-Allocation problems using geospatial data

<p align="center">
<img src="https://github.com/giacfalk/locationallocation/blob/main/logo.png?raw=true" alt="" width="300"/>
</p>

Package developer: Giacomo Falchetta, giacomo.falchetta@cmcc.it

## Background

Assessing and planning infrastructure and networks over space conditional to a spatially distributed demand and with consideration of accessibility and spatial justice goals and under infrastructure allocation constraints is a key policy objective. Such infrastructure can relate to many domains that are pertinent to climate risk reduction, including public health, public services provision, and logistics. This class of problems is generally defined as "Maximal Coverage Location-Allocation (MCLA)" spatial optimisation problems.

locationallocation, an R package to solve MCLA problems using geospatial data in widely used R programming language geospatial libraries. The locationallocation package allows to produce travel time maps and spatially optimise the allocation of facilities/infrastructure based on spatial accessibility criteria weighted by one or more variables or a function of those. 

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

As an example, We demonstrate how the package can tackle urban-scale climate risk through robust infrastructure assessment and geospatial planning. We run the `demo_data_load()` function to load a set of demo datasets to run the package's function. The demo data contains the coordinate-point location of public drinking water fountains in the city of Naples, Italy, as well as a gridded population raster data from GHS-POP, a 100-m resolution map of heat hazard (number of days with Wet-Bulb Globe Temperature greater than 25° C in the historical period 2008-2017, obtained from the UrbClim model), and the administrative boundaries of the city. 

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

We can also produce a summary plot and statistic based on the output of the traveltime function and a given demand (e.g., population) raster, as well as a given time threshold parameter:

``` r
traveltime_stats(traveltime = out_tt, demand_raster = pop, breaks=c(5, 10, 15, 30), objectiveminutes=5)
```

which will print an output message such as:

``` r
[1] "38.54 % of demand layer within the objectiveminutes threshold."
```

We can now  use the `allocation` function to optmise the spatial allocation of new water fountains to ensure that (virtually) everyone (i.e., the totality of the raster layer specified by the `demand_raster` parameter) can walk to one within 15 minutes, as specified by the `objectiveminutes` parameter:

``` r
output_allocation <- allocation(demand_raster = pop, traveltime_raster=out_tt, bb_area = boundary, facilities=fountains, weights=NULL, objectiveminutes=15, objectiveshare=0.01, heur="max", dowscaling_model_type="lm", mode="walk", res_output=100)

allocation_plot(output_allocation, bb_area = boundary)

```
<p align="center">
<img src="https://github.com/giacfalk/locationallocation/blob/main/outputs/allocation_15mins_fountains.png?raw=true" alt="" width="600"/>
</p>

Note that is is also possible to solve an allocation problem specifying a `weights` parameter, to attribute more relative importance or priority to areas where the demand_raster is overlapping with some weighting factors (defined by another raster layer), such as exposure to hot days, as in the following example:

``` r
output_allocation_weighted <- allocation(demand_raster = pop, traveltime_raster=out_tt, bb_area = boundary, facilities=fountains, weights=hotdays, objectiveminutes=15, objectiveshare=0.01, heur="max", dowscaling_model_type="lm", mode="walk", res_output=100)

allocation_plot(output_allocation_weighted, bb_area = boundary)
```

<p align="center">
<img src="https://github.com/giacfalk/locationallocation/blob/main/outputs/allocation_15mins_fountains_weighted.png?raw=true" alt="" width="600"/>
</p>

A variant of the allocation problem is the case when the set of candidate locations to allocate new faciltiies is discrete (and not continuous over the study area, as in the previous example). In this case, the user needs to provide a discrete set of location points into the `candidate` parameter of the allocation_discrete function, as well as a maximum number of facilities (`max_fac` parameter) that can be selected among the candidate locations. The function will apply a quasi-optimality heuristic (using a randomisation based approach, where the number of replications - defined by the `n_samples` parameters - will gradually approach the global optimum but it will linearly increase the computational time. 

``` r
candidates <- st_sample(boundary, 30)

output_allocation_discrete <- allocation_discrete(demand_raster = pop, traveltime_raster=NULL, bb_area = boundary, facilities=fountains, candidate=candidates, max_fac = 10, weights=NULL, objectiveminutes=15, dowscaling_model_type="lm", mode="walk", res_output=100, n_samples=100)

allocation_plot_discrete(output_allocation_discrete, bb_area = boundary)
```

<p align="center">
<img src="https://github.com/giacfalk/locationallocation/blob/main/outputs/allocation_discrete_fountains.png?raw=true" alt="" width="600"/>
</p>

Consider also the case of a problem where there are no existing facilities to start with, and hence the discrete location-allocation problem needs to optimise the allocation to cover as much as possible of the demand within the limited set of discrete choices over space to allocate new facilities, as well as the constraint set by the maximum number of allocable facilities:

``` r
set.seed(333)

output_allocation_discrete_from_scratch <- allocation_discrete(demand_raster = pop, traveltime_raster=NULL, bb_area = boundary, facilities=NULL, candidate=candidates, max_fac = 10, weights=NULL, objectiveminutes=15, dowscaling_model_type="lm", mode="walk", res_output=100, n_samples=100)

allocation_plot_discrete(output_allocation_discrete_from_scratch, bb_area = boundary)
```
<p align="center">
<img src="https://github.com/giacfalk/locationallocation/blob/main/outputs/allocation_discrete_fromscratch_fountains.png?raw=true" alt="" width="600"/>
</p>


## Disclaimer

The developer of this package does not hold any responsibility for the results produced by this package.  
