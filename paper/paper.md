---
title: "*locationallocation*: solving Maximal Coverage
  Location-Allocation geospatial infrastructure assessment and planning
  problems"
tags:
  - R
  - geographic information science
  - geospatial analysis
  - spatial optimisation
  - Maximal Coverage Location-Allocation problems
authors:
  - name: Giacomo Falchetta
    orcid: 0000-0003-2607-2195
    affiliation: "1, 2" # (Multiple affiliations must be quoted)
affiliations:
 - name: Centro Euro-Mediterraneo sui Cambiamenti Climatici, Venice, Italy
   index: 1
 - name: International Institute for Applied Systems Analysis, Laxenburg, Austria
   index: 2
date: 24 March 2025
bibliography: paper.bib

---

# Summary

Assessing and planning infrastructure and networks over space
conditional to a spatially distributed demand and with consideration
of accessibility and spatial justice goals and under infrastructure
allocation constraints is a key policy objective. Potential
applications extend to the domains of public infrastructure assessment
and planning (public services provision, e.g. transport, social
services, healthcare, parks), urban environmental and climate risk
reduction interventions, logistics and hubs allocation, commercial and
strategic decisions. Here we introduce *locationallocation*, an R
package to solve Maximal Coverage Location-Allocation problems using
geospatial data in widely used R programming language geospatial
libraries. The package allows to produce travel time maps and
spatially optimizing the allocation of facilities in both continuous
and discrete choice problems and based on spatial accessibility
criteria weighted by one or more variables or a function of those. We
demonstrate the use of package through an example of how it can be
used to plan infrastructures that can tackle urban-scale climate risk
through infrastructure assessment and spatial planning.

# Statement of need

`Gala` is an Astropy-affiliated Python package for galactic dynamics. Python
enables wrapping low-level languages (e.g., C) for speed without losing
flexibility or ease-of-use in the user-interface. The API for `Gala` was
designed to provide a class-based and user-friendly interface to fast (C or
Cython-optimized) implementations of common operations such as gravitational
potential and force evaluation, orbit integration, dynamical transformations,
and chaos indicators for nonlinear dynamics. `Gala` also relies heavily on and
interfaces well with the implementations of physical units and astronomical
coordinate systems in the `Astropy` package [@astropy] (`astropy.units` and
`astropy.coordinates`).

`Gala` was designed to be used by both astronomical researchers and by
students in courses on gravitational dynamics or astronomy. It has already been
used in a number of scientific publications [@Pearson:2017] and has also been
used in graduate courses on Galactic dynamics to, e.g., provide interactive
visualizations of textbook material [@Binney:2008]. The combination of speed,
design, and support for Astropy functionality in `Gala` will enable exciting
scientific explorations of forthcoming data releases from the *Gaia* mission
[@gaia] by students and experts alike.

# Introduction

Assessing and planning infrastructure and networks over space
conditional to a spatially distributed demand and with consideration of
accessibility and spatial justice goals and under infrastructure
allocation constraints is a key policy objective
[@schindler2021getting; @seto2014human; @todes2012new; @brown2014spatial].
This is particularly crucial in cities because the world is keeping on
urbanizing (the size and share of global population classified as living
in urban areas has overtaken the rural population since 2007 and it
projected to increase to 68% by 2050 [@urbanization2018revision]).\
In facility location problems, one of the most critical considerations
is maximizing the coverage of demand points with a limited number of
facilities. The Maximal Coverage Location-Allocation (MCLA) seeks to
determine the best locations for facilities to serve the highest
possible number of demand points within a predefined distance or service
threshold. @Church1974 provided the first mathematical formulation of
the Maximal Covering Location Problem (MCLP) to determine the best
locations for facilities to maximize the coverage of demand within a
given distance or time constraint.\
Some of the primary reasons why MCLA problems are important include: (i)
Efficient Resource Utilization: Many organizations operate with limited
resources, such as emergency response units, public health clinics, or
distribution centers. The MCLA problem helps optimize the placement of
these resources to maximize service coverage, ensuring that the highest
number of people benefit from the available facilities; (ii) Emergency
Response and Public Safety: In scenarios where response time is crucial,
such as ambulance or fire station placement, solving the MCLA problem
can directly impact lives. By strategically locating these facilities,
authorities can reduce response times and improve emergency
preparedness; (iii) Retail and Service Industry Optimization: Businesses
often seek to maximize their customer base while minimizing costs.
Retail chains, fast-food franchises, and service providers can use MCLA
models to identify optimal store locations, improving accessibility for
the largest number of potential customers; (iv) infrastructure and Urban
Planning: Governments and city planners use MCLA models to determine the
best locations for schools, hospitals, and transportation hubs. Properly
placed infrastructure ensures equitable access to essential services,
reducing disparities in service distribution.\
Recent work, such as @Bonnet2015, demonstrated an implementation of the
MCLA framework with the use of geospatial data for optimally locating
automated external defibrillators (AEDs) in cities to improve emergency
response times and cardiac arrest survival rates. Other studies, such as
@Falchetta2020 - upon which the scientific software package introduced
in this paper is building - demonstrated solutions to the MCLA for
healthcare facilities accessibility, a challenge which was already
explored (although mostly in a descriptive rather than planning-oriented
lens, by @weiss2020global). Their framework is implemented with
spatially-explicit data on factors such as population density,
historical cardiac arrest data, and accessibility constraints. However,
irrespective of such previous work implementing the domains of data
science and the solution to problem such as MCLA (see the review of
@chen2021open), existing open-source implementations in R are limited to
*traveltime* [@Ryan2025], which is suitable to calculate descriptive
snapshots and maps, the *maxcovr* [@maxcovrbib] package
(<https://github.com/njtierney/maxcovr>) which however is not
implemented in a way to be integrated with R's geospatial data
processing capabilities.\
In this paper, I introduce the *locationallocation* R package, which
allows spatially optimizing the allocation of facilities and
infrastructure based on spatial accessibility criteria weighted by one
or more variables or a function of those. In *locationallocation*, such
maximization can be modified to e.g. minimize risk (exposure of the
population times environmental hazard), even considering
population-specific vulnerability (age, health status, other
geographical features). I demonstrate the package with a use case on how
to tackle urban-scale climate risk through infrastructure assessment and
spatial planning.\
The remainder of the paper is structured as follows: in Section 2 we
provide a concise mathematical formulation of the MCLP problem and of
its solution algorithm; then we discuss the software and data
implementation that underlie the *locationallocation* R package. In
Section 3 we present an use of the package based on sample data and
objectives. We conclude in Section 4 with a commentary on the potential
use cases of the package, as well as its current limitation and
potential for future further developments.\

# Methods and data

## Maximal Coverage Location Problem (MCLP) {#maximal-coverage-location-problem-mclp .unnumbered}

Before introducing the software implementation and the functioning of
the *locationallocation* package, it is worth providing a concise
mathematical formulation of the class of problems addressed by the
package.\
**Sets and Indices:**

- $I$ : Set of candidate facility locations ($i \in I$).

- $J$ : Set of demand points ($j \in J$).

**Parameters:**

- $w_j$ : Population (or demand weight) at location $j$.

- $d_{ij}$ : Travel time from facility location $i$ to demand point $j$.

- $T$ : Maximum acceptable travel-time threshold for coverage.

- $N_j = \{ i \in I \mid d_{ij} \leq T \}$ : Set of candidate facilities
  that can cover demand point $j$.

- *Optionally,* $P^(\star)$ : Maximum number of facilities to be located
  from a discrete set of pre-defined locations $P$ on the lattice space.

\
**Decision Variables:**

- $x_i \in \{0,1\}$ : 1 if a facility is located at site $i$, 0
  otherwise.

- $y_j \in \{0,1\}$ : 1 if demand point $j$ is covered by at least one
  facility, 0 otherwise.

\
**Objective Function:** Maximize the total covered population:

$$\max \sum_{j \in J} w_j y_j$$

**Constraints:**

1.  Coverage constraint: A demand point $j$ is covered if at least one
    facility in $N_j$ is selected:
    $$y_j \leq \sum_{i \in N_j} x_i, \quad \forall j \in J$$

2.  Binary constraints: $$x_i \in \{0,1\}, \quad \forall i \in I$$

    $$y_j \in \{0,1\}, \quad \forall j \in J$$

    and, optionally:\

3.  Facility location constraint (at most $P^(\star)$ facilities must be
    chosen from a discrete set of pre-defined locations $P$ on the
    lattice space): $$\sum_{i \in I} x_i \leq P^(\star)$$

## Problem solution algorithm {#problem-solution-algorithm .unnumbered}

Greedy Heuristic are used to identify quasi-optimal solution without
resorting to resource and time-intensive constrained optimization
approaches such as Mixed-Integer Programming (MIP):\

:::: algorithm
::: algorithmic
Set of candidate facility locations $I$, set of demand points $J$,
travel-time matrix $d_{ij}$, population weights $w_j$, number of
facilities $P$, coverage threshold $T$. A set $S$ of selected facility
locations.

Initialize $S \gets \emptyset$ Initialize $J_{\text{unmet}} \gets J$

Find the facility $i^*$ that maximizes covered demand:
$$i^* = \arg\max_{i \in I \setminus S} \sum_{j \in J_{\text{unmet}}} w_j \mathbb{1}(d_{ij} \leq T)$$
Add $i^*$ to the selected facilities: $S \gets S \cup \{ i^* \}$ Update
covered demand points:
$$J_{\text{unmet}} \gets J_{\text{unmet}} \setminus \{ j \mid d_{i^* j} \leq T \}$$

$S$
:::
::::

In the heuristics, to choose the location of the next facility
allocation, two approaches are implemented:

- Allocation based on maximum demand weight location at each iteration
  $k$

- Allocation based on maximum value of spatial kernel density map (using
  a kernel function to fit a smoothly tapered surface to each point) of
  demand weights location at each iteration $k$

In the case of a discrete set of potential allocation sites, a random
sampling approach is adopted, where the accessibility algorithm is
implemented $r$ times, in each of which a set of $P*$ locations is drawn
and the global demand coverage based on such facilities is calculated at
the end of each iteration to gauge the best performing set of facilities
in the discrete number of sets drawn from the discrete set of all the
combinations of size $P*$ among the $P$ global set of candidate
facilities.\

## Software and data implementation {#software-and-data-implementation .unnumbered}

The approach includes consideration of different travel modes and can be
applied to any location in the world. A spatial statistical downscaling
(\"disseving\") approach for the underlying friction surface data based
on street network data from Open Street Map API is embedded in the
package to perform location-allocation spatial optimization at a high
spatial-resolution (particularly useful in urban-scale applications). A
set of reporting functions and graphical outputs are pre-calculated as
part of the package. The package relies on *malariaAtlas*, *dissever*
and *gdistance* functions, as well as on *raster*, *terra*, and *sf*
classes od object.\

- **Friction layers:** Malaria Atlas friction surfaces: walking or
  fastest mode

- **Point locations of existing facilities:** A point simple feature
  geometry ($sf$)

- **Point locations for candidate facilities:** Optional, point simple
  feature geometry ($sf$)

- **Demand weights:** A raster. It can be, for instance, population
  counts per location (grid cell), optionally in a weighted form by
  specifying the $weights$ argument to another raster. This would allow
  using a risk framework where the demand is defined as a risk map $R$
  of:

  $R = POP \times HAZARD \times VULNERABILITY$

The package core functions are the following:

``` {.r language="R"}

traveltime(facilities, bb_area, dowscaling_model_type, mode, res_output = 100)
```

The $traveltime$ function generates a travel time map based on the input
facilities, bounding box area, and travel mode, having the following
arguments:

- $facilities$: A sf object with the existing facilities.

- $bb\_area$: A boundary box object with the area of interest.

- dowscaling_model_type: The type of model used for the spatial
  statistical downscaling of the travel time layer.

- $mode$: The mode of transport.

- $res\_output$: The spatial resolution of the friction raster (and of
  the analysis), in meters. If \<1000, a spatial statistical downscaling
  approach is used.

``` {.r language="R"}

allocation(demand_raster, traveltime_raster = NULL, bb_area, facilities = facilities, weights = NULL, objectiveminutes = 10, objectiveshare = 0.99, heur = "max", dowscaling_model_type, mode, res_output)
```

The $allocation$ function is used to allocate facilities in a continuous
location problem. It uses the accumulated cost algorithm to find the
optimal location for the facilities based on the demand, travel time,
and weights for the demand, and target travel time threshold and share
of the demand to be covered, having the following arguments:

- $demand\_raster$: A raster object with the demand for the service.

- $traveltime\_raster$: The output of the traveltime function. If not
  provided, the function will run the traveltime function first.

- $bb\_area$: A boundary box object with the area of interest.

- $facilities$: A sf object with the existing facilities.

- $weights$: A raster with the weights for the demand.

- $objectiveminutes$: The objective travel time in minutes.

- $objectiveshare$: The share of the demand to be covered.

- $heur$: The heuristic approach to be used. Options are \"max\"
  (default) and \"kd\".

- $dowscaling\_model\_type$: The type of model used for the spatial
  statistical downscaling of the travel time layer.

- $mode$: The mode of transport.

- $res_output$: The spatial resolution of the friction raster (and of
  the analysis), in meters. If \<1000, a spatial statistical downscaling
  approach is used.

``` {.r language="R"}

allocation_discrete(demand_raster, traveltime_raster = NULL, bb_area, facilities = NULL, candidate, n_fac = Inf, weights = NULL, objectiveminutes = 10, dowscaling_model_type, mode, res_output, n_samples)
```

The $allocation_discrete$ function, having the following arguments:

- $demand\_raster$: A raster object with the demand for the service.

- $traveltime\_raster$; The output of the traveltime function. If not
  provided, the function will run the traveltime function first.

- $bb\_area$: A boundary box object with the area of interest.

- $facilities$: A sf object with the existing facilities.

- $candidate$: A sf object with the candidate locations for the new
  facilities.

- $n\_fac$: The number of facilities that can be allocated.

- $weights$: A raster with the weights for the demand.

- $objectiveminutes$: The objective travel time in minutes.

- $dowscaling\_model\_type$: The type of model used for the spatial
  statistical downscaling of the travel time layer.

- $mode$: The mode of transport.

- $res\_output$: The spatial resolution of the friction raster (and of
  the analysis), in meters. If \<1000, a spatial statistical downscaling
  approach is used.

- $n\_samples$: The number of samples to generate in the heuristic
  approach for identifying the best set of facilities to be allocated.

Ancillary functions include $allocation\_plot()$, $demo\_data\_load()$,
$friction()$,\
$mask\_raster\_to\_polygon()$, $traveltime\_plot()$, and
$traveltime\_stats()$, and they are documented in the package repository
and vignette website.

# Use case: optimal allocation of public water fountains with consideration of heat hazard, exposure, and vulnerability

The world is experiencing climate change impacts (climate impacts are
becoming ever more frequent and severe for both citizens and governments
across a range of dimensions, including socio-economic outcomes, human
health, and environmental systems). Hence, evaluating the public
provisions of infrastructure that can support adaptation to different
climate hazards and impacts at the urban scale has crucial implications
for acting to reduce the adversity and inequity of climate change
impacts. Such knowledge can be used to inform the design and
transformation of urban areas into more climate-resilient, just,
sustainable living systems.\
As a use case, we evaluate accessibility and optimize accessibility
goals to public drinking water fountains in the city of Naples, Italy
with consideration of exposure (population density), hazard (average
number of days per year with a local Wet-Bulb Globe Temperature \> 25°
C, and vulnerability (poverty map).\
First, we obtain water fountain coordinate location for city from the
Open Street Maps API using the *osmdata* package using the query
*$amenity = drinking_water$*. We also obtain gridded population data at
a 100m spatial resolution from GHS-POP data product [@Florczyk2019], a
urban microclimate model output for historical Wet-Bulb Globe
Temperature from the UrbClim model [@Lauwaet2024], and the
administrative boundaries of the city of Naples from the Eurostat's LAU
database, as depicted in Figure
[1](#fig:maps_naples){reference-type="ref" reference="fig:maps_naples"}.
The following example datasets are fully embedded in the package and
they become available in the R global environment by calling the
*demo_data_load* function.

![Map of population density and location of public drinking water
fountains in Naples, Italy.](outputs/maps_Napoli.pdf){#fig:maps_naples}

Then, we implement the *traveltime* function to calculate a map of
accessibility to public drinking water sources as follows:

``` {.r language="R"}

out_tt <- traveltime(facilities=fountains, bb_area=boundary, dowscaling_model_type="lm", mode="walk", res_output=100)
```

The function yields a raster output which - for each pixel - shows the
estimated travel time to reach the most accessible facility (nearest in
travel time terms) for the selected travel mode. The resulting layer can
be visualized via:

``` {.r language="R"}

traveltime_plot(traveltime=out_tt,  bb_area=boundary, facilities = fountains)
```

![Map of the walking travel time to the nearest public drinking water
fountain in Naples,
Italy.](outputs/traveltime_map_fountains.png){#fig:enter-label}

We can also produce a summary plot and statistic based on the output of
the $traveltime$ function and a given demand (e.g., population) raster,
as well as a given time threshold parameter:

``` {.r language="R"}

traveltime_stats(traveltime = out_tt, demand_raster = pop, breaks=c(5, 10, 15, 30), objectiveminutes=5)
```

yielding:

``` {.r language="R"}

[1] "38.54 % of demand layer within the objectiveminutes threshold."
```

We then can proceed optimize allocation of new water fountains to cover
maximum fraction of (unweighted) population. Location-allocation can be
either solved discretely or continuously over space, and either with a
facility constraint or with a policy goal for demand (population)
coverage. For instance, if the goals is to optimise allocation of new
water fountains to cover maximum fraction of heat-risk weighted
population (exposure), we can use:

``` {.r language="R"}

output_allocation <- allocation(demand_raster = pop, traveltime_raster=out_tt, bb_area = boundary, facilities=fountains, weights=NULL, objectiveminutes=15, objectiveshare=0.01, heur="max", dowscaling_model_type="lm", mode="walk", res_output=100)

allocation_plot(output_allocation, bb_area = boundary)
```

This yields an output object containing both the coordinate location of
the allocated facility to meet the accessibility objectives, and the
updated travel time map:

![Map of the continuous location-allocation problem solution for a
15-minute walk and a 99% demand coverage objective for the nearest
public drinking water fountain in Naples,
Italy.](outputs/allocation_15mins_fountains.png){#fig:sol_cont}

If we use demadn weights (e.g. maximum temperature), we can use:

``` {.r language="R"}

output_allocation_weighted <- allocation(demand_raster = pop, traveltime_raster=out_tt, bb_area = boundary, facilities=fountains, weights=hotdays, objectiveminutes=15, objectiveshare=0.01, heur="max", dowscaling_model_type="lm", mode="walk", res_output=100)

allocation_plot(output_allocation_weighted, bb_area = boundary)
```

where $tmax$ is a raster layer matching the extent, spatial resolution
of the $pop$ demand raster. We can notice how results change when using
such weighted approach:

![Map of the continuous location-allocation weighted problem solution
for a 15-minute walk, a 99% demand coverage objective, and a demand
weight based on the frequency of hot days for the nearest public
drinking water fountain in Naples,
Italy.](outputs/allocation_15mins_fountains_weighted.png){#fig:sol_cont_weighted}

Otherwise, if we want to prioritize among a discrete set of pre-defined
potential sites (e.g. sites along the water pipes network), we can use:

``` {.r language="R"}

candidates <- st_sample(boundary, 30)

output_allocation_discrete <- allocation_discrete(demand_raster = pop, traveltime_raster=NULL, bb_area = boundary, facilities=fountains, candidate=candidates, n_fac = 10, weights=NULL, objectiveminutes=15, dowscaling_model_type="lm", mode="walk", res_output=100, n_samples=100)

allocation_plot_discrete(output_allocation_discrete, bb_area = boundary)
```

The resulting map shows the coordinate location of the selected
facilities among the candidate set (subject to the number of facilities
constraint), with the title of the plot reporting the demand coverage
rate attained:

![Map of the discrete location-allocation problem solution for a
15-minute walk and a 99% demand coverage objective for the nearest
public drinking water fountain in Naples,
Italy.](outputs/allocation_discrete_fountains.png){#fig:sol_disc}

Note that it is also possible to solve location-allocation problems from
scratch, i.e. in the absence of pre-existing facilities:

``` {.r language="R"}

set.seed(333)

output_allocation_discrete_from_scratch <- allocation_discrete(demand_raster = pop, traveltime_raster=NULL, bb_area = boundary, facilities=NULL, candidate=candidates, n_fac = 10, weights=NULL, objectiveminutes=15, dowscaling_model_type="lm", mode="walk", res_output=100, n_samples=100)

allocation_plot_discrete(output_allocation_discrete_from_scratch, bb_area = boundary)
```

Also in this case, the resulting map shows the coordinate location of
the selected facilities among the candidate set (subject to the number
of facilities constraint, with the title of the plot reporting the
demand coverage rate attained). We can note that in this case the travel
time layer is computed from scratch, rather than updated:

![Map of the discrete location-allocation problem solution for a
15-minute walk and a 99% demand coverage objective and in a case of
absence of pre-existing facilities in Naples,
Italy.](outputs/allocation_discrete_fromscratch_fountains.png){#fig:sol_disc}

# Discussion and conclusion

This paper provides an illustration of the theoretical background, the
software and data implementation, and the use case for the
*locationallocation* R package. The suite of functions in the package
are suitable to be applied to geographical location-allocation problems,
such as (but not only) in cities. Example applications in the domain of
urban environmental and climate risk include cooling centers, green
space, emergency services, drinking water, transport, or flood
protection infrastructure. Beyond, other domains of application include
public infrastructure assessment and planning (public services
provision, e.g. transport, social services, healthcare, parks),
logistics and hubs allocation, commercial and strategic decisions.\
Despite the advancements brought by *locationallocation* in its capacity
to bridge the mathematical formulation of the MCLA problem with the
application with geospatial data and libraries in the R scientific
programming language, the package has limitations. For instance
currently, the package does not support facility-level attributes that
can affect the location allocation or local density or size of the
facility to be allocated (e.g. supply constraints such as beds per
hospital or users per facilities), as all facilities are equally
defined. Moreover, the apporach to establish the location of the next
facility to be allocated in the lattice space (in the continuous
allocation problem) or the exact set of facilities optimizing the
objective (in the discrete allocation problem) is currently based on
heuristics which might not necessarily coincide with the single (if
uniquely identified) globally optimal solution. Such heuristics are
based on the selection of the highest demand or spatial kernel density
of demand pixel where accessibility objectives are not yet satisfied at
each iteration $i$, or - in the discrete problem case - on the number of
random sets of facilities of size $n$ that are sampled and evaluated
among the global set of candidate facilities of size $N$. The
identification of a truly global optimal solution would however require
the development of a constrained optimization framework requiring the
use of computationally intensive professional solvers. Future software
work might implement such features and expand the package capabilities.\


# Acknowledgements

The author gratefully acknowledges the openly available data and
algorithm resources from malariaAtlas and OpenStreetMap, without which
the development of this package would not have been possible. The author
is thankful to Ahmed T. Hammad for the previous joint work in
@Falchetta2020 which led to the development of this package. THe author
is also grateful to his scientific affiliations CMCC and IIASA for their
continuous support.

# References