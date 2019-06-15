workflow "Build and Push" {
  on = "push"
  resolves = [
    "push"
  ]
}

action "build" {
  uses = "actions/docker/cli@09314e9366705e146a0e3ae8d39511e4028c1bdd"
  args = "build -t r-ci ."
}

action "tag" {
  uses = "actions/docker/tag@09314e9366705e146a0e3ae8d39511e4028c1bdd"
  args = "r-ci maxheld83/r-ci"
  needs = "build"
}

action "test loadNamespace2 helper" {
  uses = "actions/docker/cli@09314e9366705e146a0e3ae8d39511e4028c1bdd"
  args = "run --entrypoint Rscript r-ci test_loadNamespace2.R"
  needs = "build"
}

action "Filter Not Act" {
  uses = "actions/bin/filter@3c0b4f0e63ea54ea5df2914b4fabf383368cd0da"
  args = "not actor nektos/act"
  needs = [
    "tag",
    "test loadNamespace2 helper"
  ]
}

action "login" {
  uses = "actions/docker/login@09314e9366705e146a0e3ae8d39511e4028c1bdd"
  secrets = [
    "DOCKER_USERNAME", 
    "DOCKER_PASSWORD"
  ]
  needs = "Filter Not Act"
}

action "push" {
  uses = "actions/docker/cli@09314e9366705e146a0e3ae8d39511e4028c1bdd"
  args = "push maxheld83/r-ci"
  needs = [
    "login"
  ]
}
