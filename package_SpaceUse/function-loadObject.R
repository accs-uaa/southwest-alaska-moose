# This function loads an .Rdata object and renames it
# From @pbee: https://stackoverflow.com/questions/52580816/loading-multiple-files-into-r-at-the-same-time-with-similar-file-names

# Load object in new environment and assign new name
load_obj <- function(file, filename) {
  env <- new.env()
  nm <- load(file, env)[1]  # load into new environ and capture name
  assign(filename, env[[nm]], pos = 1) # pos 1 is parent env
}

