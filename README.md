Further documentation available [here](https://docs.google.com/document/d/17NFwGvn4vMEXZV9Qmg30BqAcKrdxBYCOB4pFdkkwIIo/edit#)

# Using this template

This template repository should be used as the base for new Dockerized softare repositories.

# Software Dockers of multiple versions

## Pre-requisites

- Docker
- [just](https://github.com/casey/just)

`just init` will install the correct version of `pre-commit`, be sure to have a python3.8+ virtual environment active.

- `just build <VERSION>` will create the Docker for the specified VERSION

`just build-all` will build all available Docker images.

## Just

The `just` utility is a command runner replacement for `make`.

It has various improvements over `make` including the ability to list available command with `just -l`:

### Root Justfile

```
Available recipes:
    build VERSION # Builds individual workflow
    build-all      # Builds all docker images for each directory with a justfile
    init
```

The root `justfile` provides recipes for Dockerizing workflows locally, while workflow-level `justfiles` provide recipes for building the workflow.

### Workflow Justfile

The version-level `justfile` requires the `DOCKERFILE` path be updated.

```
# justfile
DOCKERFILE := "../Dockerfile.multi"
```

Many kinds of software are able to share a single Dockerfile with a parameterized version.

However, if a particular version needs a bespoke Dockerfile, simply create on in the version directory and upate the justfile: 

```
# justfile
DOCKERFILE := "./Dockerfile"
```

```
Available recipes:
    emit-dockerfile          # Prints which Dockerfile to use for CI builds
```


