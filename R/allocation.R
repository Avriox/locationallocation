#' @export
allocation <- function(demand_raster, sf_area, friction=friction, weights=NULL, dowscaling_model_type, mode, objectiveminutes=10, objectiveshare=0.01){

  if(!exists(friction)){print("Error"); break} else{

    assign("demand_raster", demand_raster, envir = .GlobalEnv)

    require(tidyverse)

    options(error = expression(NULL), warn=-1)

    totalpopconstant = cellStats(pop, 'sum', na.rm = TRUE)

    pop <- overlay(pop, t1, fun = function(x, y) {
      x[y<=objectiveminutes] <- NA
      return(x)
    })

    T.filename <- 'study.area.T.rds'
    T.GC.filename <- 'study.area.T.GC.rds'

    old_facilities <- cooling %>% dplyr::select(geometry)

    repeat {
      all = rasterToPoints(pop, spatial=TRUE)

      # all <- sp.kde(x = st_as_sf(all), y = all$layer, bw = 0.0083333,
      #               ref = terra::rast(pop), res=0.0008333333,
      #               standardize = TRUE,
      #               scale.factor = 10000)

      if(risk_optim==T){
        all = which.max(pop*wbgt) # optimize based on risk (exposure*hazard), and not on exposure only
      } else{
        all = which.max(pop)
      }
      pos = as.data.frame(xyFromCell(pop, all))

      new_facilities <- if(exists("new_facilities")){
        rbind(new_facilities, st_as_sf(pos, coords = c("x", "y"), crs = 4326))
      } else {
        st_as_sf(pos, coords = c("x", "y"), crs = 4326)
      }

      merged_facilities <- rbind(new_facilities, old_facilities)

      points = as.data.frame(st_coordinates(merged_facilities$geometry))

      # Fetch the number of points
      temp <- dim(points)
      n.points <- temp[1]

      T.GC <- readRDS(T.GC.filename)

      # Convert the points into a matrix
      xy.data.frame <- data.frame()
      xy.data.frame[1:n.points,1] <- points[,1]
      xy.data.frame[1:n.points,2] <- points[,2]
      xy.matrix <- as.matrix(xy.data.frame)

      # Run the accumulated cost algorithm to make the final output map. This can be quite slow (potentially hours).
      t34_new <- accCost(T.GC, xy.matrix)

      t34_new = crop(t34_new, extent(pop))

      t34_new <- projectRaster(t34_new, pop)

      pop <- overlay(pop, t34_new, fun = function(x, y) {
        x[y<=objectiveminutes] <- NA
        return(x)
      })

      k = cellStats(pop, 'sum', na.rm = TRUE)/totalpopconstant
      print(paste0("Fraction of population >target mins away:  ", k))
      # exit if the condition is met
      if (k<objectiveshare) break
    }

    return(merged_facilities)

  }}
