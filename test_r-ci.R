#!/usr/bin/env Rscript

# this is not a testthat test, because attaching testthat would make this too complicated to reason about
# use pkgdown as an example

if ("pkgdown" %in% loadedNamespaces()) {
  stop("Test package 'pkgdown' is already loaded.")
}
.libPaths(new = Sys.getenv("R_LIBS_DEV_HELPERS"))
library('pkgdown')
if (!("pkgdown" %in% loadedNamespaces())) {
  stop("Test package 'pkgdown' is still not loaded.")
}
message("Test package 'pkgdown' was successfully loaded.")
