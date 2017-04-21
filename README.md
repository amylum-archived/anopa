**Inactive Project:** I am no longer updating this with new releases, as I ended up using raw [s6](https://github.com/amylum/s6) for my systems.

anopa
=========

[![Build Status](https://img.shields.io/circleci/project/amylum/anopa/master.svg)](https://circleci.com/gh/amylum/anopa)
[![GitHub release](https://img.shields.io/github/release/amylum/anopa.svg)](https://github.com/amylum/anopa/releases)
[![GPLv3 Licensed](https://img.shields.io/badge/license-GPLv3-green.svg)](https://www.tldrlegal.com/l/gpl-3.0)

This is my package repo for [anopa](http://jjacky.com/anopa/), a framework for system process management built around [s6](http://skarnet.org/software/s6/).

The `upstream/` directory is taken directly from upstream. The rest of the repository is my packaging scripts for compiling a distributable build.

## Usage

To build a new package, update the submodule and run `make`. This launches the docker build container and builds the package.

To start a shell in the build environment for manual actions, run `make manual`.

## License

The anopa upstream code is GPLv3 licensed. My packaging code is MIT licensed.

