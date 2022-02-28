#!/bin/bash

# THIS IS NOT PART OF THE REFLECTION EXAMPLE
cd ../
ROM_BUILD_CI_TOP="$(pwd)"
source include/basic.sh

# START OF REFLECTION EXAMPLE

include reflect

run Example
