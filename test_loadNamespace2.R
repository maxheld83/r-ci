#!/usr/bin/env Rscript

# this is not a testthat test, because attaching testthat would make this too complicated to reason about
if ("pkgdown" %in% loadedNamespaces()) {
  stop("Test package 'pkgdown' is already loaded.")
}
source("loadNamespace2.R")
loadNamespace2("pkgdown")
if (!("pkgdown" %in% loadedNamespaces())) {
  stop("Test package 'pkgdown' is still not loaded.")
}
message("Test package 'pkgdown' was successfully loaded.")
