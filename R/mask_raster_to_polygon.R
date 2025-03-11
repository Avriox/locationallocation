#' A Cat Function
#'
#' This function allows you to express your love of cats.
#' @param love Do you love cats? Defaults to TRUE.
#' @keywords cats
#' @export
#' @examples

mask_raster_to_polygon <- function(ras = NULL, mask = NULL, inverse = FALSE, updatevalue = NA) {

  stopifnot(inherits(ras, "Raster"))

  stopifnot(inherits(mask, "Raster") | inherits(mask, "sf"))

  stopifnot(raster::compareCRS(ras, mask))


  ## If mask is a polygon sf, pre-process:

  if (inherits(mask, "sf")) {

    stopifnot(unique(as.character(sf::st_geometry_type(mask))) %in% c("POLYGON", "MULTIPOLYGON"))

    # First, crop sf to raster extent
    sf.crop <- suppressWarnings(sf::st_crop(mask,
                                            y = c(
                                              xmin = raster::xmin(ras),
                                              ymin = raster::ymin(ras),
                                              xmax = raster::xmax(ras),
                                              ymax = raster::ymax(ras)
                                            )))
    sf.crop <- sf::st_cast(sf.crop)

    # Now rasterize sf
    mask <- fasterize::fasterize(sf.crop, raster = ras)

  }



  if (isTRUE(inverse)) {

    ras.masked <- raster::overlay(ras, mask,
                                  fun = function(x, y)
                                  {ifelse(!is.na(y), updatevalue, x)})

  } else {

    ras.masked <- raster::overlay(ras, mask,
                                  fun = function(x, y)
                                  {ifelse(is.na(y), updatevalue, x)})

  }

  ras.masked

}
