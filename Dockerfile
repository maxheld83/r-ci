FROM rhub/debian-gcc-release:latest
# github actions recommends debian, and this is the one closest to cran https://developer.github.com/actions/creating-github-actions/creating-a-docker-container/

LABEL "name"="r-ci"
LABEL "version"="0.0.0.9000"
LABEL "maintainer"="Maximilian Held <info@maxheld.de>"
LABEL "repository"="https://github.com/maxheld83/r-ci"
LABEL "homepage"="https://github.com/maxheld83/r-ci"

COPY .Rprofile "$HOME"/.Rprofile

# location for R development helpers
ENV R_LIBS_DEV_HELPERS="/usr/lib/R/dev-helpers-library"
RUN mkdir -p "$R_LIBS_DEV_HELPERS"

# system dependencies for frequently used R development helper Packages
RUN apt-get update \
  && apt-get install -y --no-install-recommends \ 
  libssl-dev \
  libxml2-dev \
  && apt-get clean -y

# these are for pensieve only for testing
# TODO delete these once https://github.com/r-lib/ghactions/issues/164 and https://github.com/r-lib/ghactions/issues/75
RUN apt-get update \
  && apt-get install -y --no-install-recommends \ 
  pdf2svg \
  libudunits2-dev \
  libpoppler-cpp-dev \
  && apt-get clean -y

# set shell to Rscript to make syntax shorter
SHELL ["usr/bin/Rscript", "-e"]
# write to $R_LIBS_DEV_HELPERS
ENV R_LIBS="$R_LIBS_DEV_HELPERS"
# bootstrap versioned remotes
RUN source('https://raw.githubusercontent.com/r-lib/remotes/master/install-github.R')[['value']]('r-lib/remotes@v2.0.4')
RUN install.packages('remotes')
# versions are hard-coded so as to *explicitly* upgrade pkgs, which will also invalidate the github cache
# without hard-coded versions, the below cache would *not* be invalidated and hard-to-reason about versions of the packages might still be lying around in the image
# necessary to let remotes install its helpers as per https://remotes.r-lib.org
ENV R_REMOTES_STANDALONE=true
RUN remotes::install_version('curl', '3.3')
RUN remotes::install_version('pkgbuild', '1.0.3')
RUN remotes::install_version('git2r', '0.25.2')
# standalone is no longer needed
ENV R_REMOTES_STANDALONE=false
RUN remotes::install_version('devtools', '2.0.2')
RUN remotes::install_version('pkgdown', '1.3.0')
RUN remotes::install_version('roxygen2', '6.1.1')
RUN remotes::install_version('covr', '3.2.1')
RUN remotes::install_version('rcmdcheck', '1.3.3')
RUN remotes::install_version('pak', '0.1.2')
RUN remotes::install_version('testthat', '2.1.1')
# helpful for modifying local .libPaths() etc.
RUN remotes::install_version('withr', '2.1.2')

# let downstream img start with unchanged env vars
# ... and without installed dev helpers on `.libPaths()`
# unset does not work https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
# unset r-libs to enable below test
ENV R_LIBS=""

# helper to make it easier to load dev helper pkgs
COPY loadNamespace2.R /loadNamespace2.R
COPY test_loadNamespace2.R /test_loadNamespace2.R

ONBUILD SHELL ["/bin/sh", "-c"]
