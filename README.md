# r-ci

Docker images for Continuous Integration / Continuous Delivery of R Projects. 

This image was created in order to be used in a CI/CD environment like Gitlab CI or Travis, so that you don't have to reinstall testing and dev packages. 

Available on docker hub at `https://hub.docker.com/r/maxheld83/r-ci`.

Images are tagged by all GitHub refs (commit hash, branch, release).

```
docker pull maxheld83/r-ci:master
```


## Packages Installed

Dockerfiles are based on a [rhub/debian-gcc-release](https://github.com/r-hub/rhub-linux-builders) image, with these packages and their respective system dependencies installed on top: 

- [remotes](https://remotes.r-lib.org) and, [to speed up](https://remotes.r-lib.org) `remotes::install_deps()`:
    - [pkgbuild](https://github.com/r-lib/pkgbuild)
    - [git2r](git2r.r-lib)
    - [curl](https://github.com/jeroen/curl/)
- [devtools](http://devtools.r-lib.org)
- [pkgdown](http://pkgdown.r-lib.org)
- [roxygen2](https://cran.r-project.org/web/packages/roxygen2/index.html)
- [covr](https://covr.r-lib.org)
- [rcmdcheck](https://github.com/r-lib/rcmdcheck)
- [pak](https://pak.r-lib.org)
- [testthat](https://testthat.r-lib.org)
- [withr](http://withr.r-lib.org)


## Isolation

(*This is an opinionated suggestion.*)

CI/CD should run an in-development R package in a computing environment defined by, *and only by* its `DESCRIPTION`.
For example, when a CI/CD script calls a function from the development package, say, as part of running tests, that function and all its dependencies should run in the versions specified in the `Imports` and `Suggests` fields of the `DESCRIPTION`.

This seemingly straightforward reproducibility is easily broken when the CI/CD scripts alter the computing environment by bringing their *own* system and R dependencies.
Problems can arise, when the CI/CD scripts and the development package have overlapping dependencies in different versions.
For example, when a CI/CD script uses, say, *devtools*, which depends on the CRAN-version of *httr*, but the development package depends on a development version of *httr* off of GitHub, there can be a conflict.
These problems may seem unlikely, though when they *do* occur, they can be very hard to reason about and debug.
Problems of this sort may also become more widespread, as CI/CD scripts rely on more (sometimes dependency-heavy) development helpers.

It is therefore a good idea to **strictly isolate the changes to the computing environment brought by the *development helpers* from those brought by *the development package*.**
This may not be possible to achieve in the absolute, but is a worthy design goal.

This image implements several practices to strengthen this isolation.


### `.libPaths()`

The development helpers in this image are all installed to `/usr/lib/R/dev-helpers-library` (stored in `R_LIBS_DEV_HELPERS`), a directory that is *not* usually on the `.libPaths()` search tree.

To make the `R_LIBS_DEV_HELPERS` available, you can:

1. `loadNamespace()` individual packages.
    Unfortunately `loadNamespace()` does not pass on `lib.loc` when recursively loading the dependencies of `package`.
    This image ships with a little helper function sourced from `/loadNamespace2()` which does that, defaulting to `lib.loc = Sys.getenv("R_LIBS_DEV_HELPERS")`.
    
    You can use it like this:
    
    ```
    loadNamespace2(package = "remotes")
    remotes::install_deps()
    unloadNamespace(ns = "remotes")
    ```
    
    This example also illustrates an advantage of isolation.
    Had *remotes* been on the package search path `.libPaths()` when *calling* `remotes::install_deps()`, any packages that are dependencies of *both* the in-dev package in question *and* remotes would not have been installed (again).
    Depending on how the CI/CD scripts are set up, this can cause problems.
    
    This method also comes with some limitations:
    
    - The attachment of the development helper via `loadNamespace2()` will persist throughout the call stack.
        That means that calls of, say, *devtools* *inside* the in-development package would use whichever version of remotes was on `R_LIBS_DEV_HELPERS` and disregard what the 
    - The attachment does not persist across sessions.
        If the development helper starts a new R session (such as by using *callr*) the side effet of `loadNamespace2()` is lost and the development helper can no longer be found.
2. You can wrap your call with *withr*:
    
    ```
    withr::with_libpaths(
      new = Sys.getenv("R_LIBS_DEV_HELPERS"),
      action = "suffix", 
      code = pkgdown::build_site()
    )
    ```
    
    This method will put *all* development helpers on the library search tree, not just *some* as in the above method.
    
3. You can prefix your `.libPaths()` by setting an `R_LIBS` environment variable.
    
    In the command line:
    
    ```
    export R_LIBS="$R_LIBS_DEV_HELPERS"
    ```
    
    Or set it your `Dockerfile`:
    
    ```
    ENV R_LIBS="$R_LIBS_DEV_HELPERS"
    ```
    
    This method will put *all* development helpers on the library search tree and let them persist until `R_LIBS` is un/reset.


### Call Tree

**TODO**: It would also be nice to isolate the dependencies *down* the call tree, where say, `rcmdcheck::check()` would use the `R_LIBS_DEV_HELPERS` *until* the call tree "passes over" into the development package, and call whatever is in `DESCRIPTION` there ([#212](https://github.com/r-lib/ghactions/issues/212))


### System Dependencies

Isolating system dependencies may be less urgent, but can also avoid thorny problems.
In particular, *not* having frequently used system dependencies available on the `PATH` in a CI/CD image may be beneficial, because it forces to developers to explicitly declare those up front.

**TODO**: should also be stored in a separate directory and only prepended to the `PATH` as necessary. ([#2](https://github.com/maxheld83/r-ci/issues/2)))


### Benefits

Adhering to this separation between run-time dependencies and "CI/CD-time" (more than just build-time) dependencies of an R package also frees up the `Suggests` field for *actual*  optional dependencies.
It is currently often (ab)used to store "CI/CD-time" dependencies, though these development helpers typically do *not* enhance or otherwise alter the package for a user at run-time.

Should a development package really need a *particular* version of a development helper, the developer can always list it in the `DESCRIPTION`
This should be exceedingly rare and only necessary for the development *of* development helpers.
**TODO**: how this would then take precedence in the lib tree is not yet implemented ([#3](https://github.com/maxheld83/r-ci/issues/3)).
