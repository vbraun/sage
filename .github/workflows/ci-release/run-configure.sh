#!/usr/bin/env sh


ARGS='--with-system-python3=no'


CONDA_SAGE_PREREQ='/Users/buildbot-sage/opt/miniforge3/envs/sage-prereq'
if [ -d $CONDA_SAGE_PREREQ ]; then
    ARGS="$ARGS --with-boost=$CONDA_SAGE_PREREQ"
fi


echo "running configure with arguments $ARGS"
./configure $ARGS


