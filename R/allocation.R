#' @export
allocation <- function(demand_raster, sf_area, facilities=facilities, traveltime=traveltime_raster, weights=NULL, objectiveminutes=10, objectiveshare=0.01, heur="max"){

  options(error = expression(NULL), warn=-1)
    require(tidyverse)
    require(raster)
    require(sf)
    require(gdistance)
    options(error = expression(NULL), warn=-1)

    assign("boundary", sf_area, envir = .GlobalEnv)

    demand_raster <- mask_raster_to_polygon(demand_raster, sf_area)
    traveltime <- mask_raster_to_polygon(traveltime, sf_area)

    totalpopconstant = raster::cellStats(demand_raster, 'sum', na.rm = TRUE)

    traveltime = raster::projectRaster(traveltime, demand_raster)

    demand_raster <-  raster::overlay(demand_raster, traveltime, fun = function(x, y) {
      x[y<=objectiveminutes] <- NA
      return(x)
    })

    repeat {
      all = rasterToPoints(demand_raster, spatial=TRUE)

      if(heur=="kd"){

        all <- sp.kde(x = st_as_sf(all), y = all$layer, bw = 0.0083333,
                  ref = terra::rast(demand_raster), res=0.0008333333,
                  standardize = TRUE,
                  scale.factor = 10000)

      } else if (heur =="max"){

      if(!is.null(weights)){
        weights <- mask_raster_to_polygon(weights, sf_area)
        all = raster::which.max(demand_raster*weights) # optimize based on risk (exposure*hazard), and not on exposure only
      } else{
        all = raster::which.max(demand_raster)
      }} else {print("Error"); break}

      pos = as.data.frame(xyFromCell(demand_raster, all))

      new_facilities <- if(exists("new_facilities")){
        rbind(new_facilities, st_as_sf(pos, coords = c("x", "y"), crs = 4326))
      } else {
        st_as_sf(pos, coords = c("x", "y"), crs = 4326)
      }

      merged_facilities <- bind_rows(as.data.frame(st_geometry(facilities)), as.data.frame(new_facilities))

      points = as.data.frame(st_coordinates(merged_facilities$geometry))

      # Fetch the number of points
      temp <- dim(points)
      n.points <- temp[1]

      # Convert the points into a matrix
      xy.data.frame <- data.frame()
      xy.data.frame[1:n.points,1] <- points[,1]
      xy.data.frame[1:n.points,2] <- points[,2]
      xy.matrix <- as.matrix(xy.data.frame)

      # Run the accumulated cost algorithm to make the final output map. This can be quite slow (potentially hours).
      t34_new <- accCost(T.GC, xy.matrix)

      t34_new = crop(t34_new, extent(demand_raster))

      t34_new <- projectRaster(t34_new, demand_raster)

      t34_new <- mask_raster_to_polygon(t34_new, sf_area)

      demand_raster <- overlay(demand_raster, t34_new, fun = function(x, y) {
        x[y<=objectiveminutes] <- NA
        return(x)
      })

      k = cellStats(demand_raster, 'sum', na.rm = TRUE)/totalpopconstant
      print(paste0("Fraction of unmet demand:  ", k*100, " %"))
      # exit if the condition is met
      if (k<objectiveshare) break
    }

    outer <- list(merged_facilities[-c(1:nrow(facilities)),], t34_new)

    return(outer)

  }
