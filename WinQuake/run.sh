#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
pushd "${SCRIPT_DIR}" > /dev/null

# Enable function profiling?
PROFILE_FILE=""
PROFILE_ARGS=""
if [ "$1" == "--profile" ] ; then
    shift 1
    PROFILE_FILE=/tmp/mc1quake-sym-$$
    mrisc32-elf-readelf -sW out/mc1quake | grep FUNC | awk '{print $2,$8}' > "${PROFILE_FILE}"
    PROFILE_ARGS="-P ${PROFILE_FILE}"
fi

# Run the Quake binary.
mr32sim -g -ga 0x40000ae0 -gp 0x400006c4 -gd 8 -gw 320 -gh 180 ${PROFILE_ARGS} "$@" out/mc1quake

# Delete the temporary profiling data.
if [ -n "${PROFILE_FILE}" ] ; then
    rm "${PROFILE_FILE}"
fi

popd > /dev/null

