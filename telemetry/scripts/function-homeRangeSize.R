# This function loads an aKDE list (saved as an .Rdata file) and returns home range size estimates (low, estimate, high) as a dataframe

# Author: A. Droghini (adroghini@alaska.edu)
#         Alaska Center for Conservation Science

summarizeHomeRange <- function(file) {
  require(plyr)
  rdata_file <- get(load(file))
  hr_list <- lapply(1:length(rdata_file),
                    function(i)
                      summary(rdata_file[[i]])$CI)
  names(hr_list) <- names(rdata_file)
  hr_df <- plyr::ldply(hr_list, data.frame)
  hr_df
}