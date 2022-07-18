#!/bin/bash
set -Ceu

printf "👯‍♂️ Updating submodules... \n"
git submodule foreach git pull
