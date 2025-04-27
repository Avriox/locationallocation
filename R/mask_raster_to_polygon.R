#' Quick masking of a Rast object to an sf object
#'
#' This function rapidly masks a Rast object to an sf object.
#' @param ras A Rast object.
#' @param mask A Rast or sf object.
#' @param inverse Logical. If TRUE, the mask is inverted.
#' @param updatevalue The value to update the Rast object with.
#' @keywords masking
#' @export

mask_raster_to_polygon <- function (ras = NULL, mask = NULL, inverse = FALSE, updatevalue = NA) 
{
  stopifnot(inherits(ras, "Raster"))
  stopifnot(inherits(mask, "Raster") | inherits(mask, "sf"))
  
  mask <- sf::st_transform(mask, 4326)
  ras <- raster::projectRaster(ras, crs=sf::st_crs(mask)$proj4string)
  
  if (inherits(mask, "sf")) {
    stopifnot(unique(as.character(sf::st_geometry_type(mask))) %in% 
                c("POLYGON", "MULTIPOLYGON"))
    sf.crop <- suppressWarnings(sf::st_crop(mask, y = c(xmin = raster::xmin(ras), 
                                                        ymin = raster::ymin(ras), xmax = raster::xmax(ras), 
                                                        ymax = raster::ymax(ras))))
    sf.crop <- sf::st_cast(sf.crop)
    mask <- fasterize::fasterize(sf.crop, raster = ras)
  }
  if (isTRUE(inverse)) {
    ras.masked <- raster::overlay(ras, mask, fun = function(x, 
                                                            y) {
      ifelse(!is.na(y), updatevalue, x)
    })
  }
  else {
    ras.masked <- raster::overlay(ras, mask, fun = function(x, 
                                                            y) {
      ifelse(is.na(y), updatevalue, x)
    })
  }
  ras.masked
}

