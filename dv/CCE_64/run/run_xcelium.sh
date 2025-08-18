#!/bin/bash

# Default test name and seed
TESTNAME=${1:-xp10}
SEED=${2:-1}

# Compile and simulate in one step
xrun -64bit -sv -access +rwc \
     -f zipline.vlist \
     +define+TESTNAME=${TESTNAME} \
     +define+SEED=${SEED} \
     +vpdfile+${SEED}.${TESTNAME}.vpd \
     +fsdbfile+${SEED}.${TESTNAME}.fsdb \
     +waves+ +dump_fsdb+ \
     -top zipline_tb \
     -l xrun.log

