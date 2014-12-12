#!/bin/bash

if [ ! -e ./IRGen ]
then
    echo "Please make IRGen first"
    exit 1
fi

./IRGen $1 2>&1 | llc-3.4 | gcc -x assembler ${*:2} -
