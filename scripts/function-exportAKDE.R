# This function loads an aKDE list, saved as an .Rdata file, and exports each akde as a raster. The raster takes on the name of the list object.

# Author: A. Droghini (adroghini@alaska.edu)
#         Alaska Center for Conservation Science

export_akdes <- function(file, file_path) {
  require(plyr)
  require(ctmm)
  require(raster)
  rdata_file <- get(load(file))
  plyr::laply(1:length(rdata_file), function(x)
    ctmm::writeRaster(
      rdata_file[[x]],
      DF = "PDF",
      filename = paste(file_path, names(rdata_file[x]), sep = "/"),
      format = "GTiff",
      level = 0.95,
      options = "COMPRESS=LZW"
    ), .progress = "text")
}