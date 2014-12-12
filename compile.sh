#!/bin/bash
set -e

if [ ! -e ./IRGen ]
then
    echo "Please make IRGen first"
    exit 1
fi

if [ "$#" -lt 1 ]
then
    echo "Please provide a MIPL file to compile"
    exit 1
fi

if [ ! -e "$1" ]
then
    echo "Please provide a MIPL file to compile"
    exit 1
fi

./IRGen $1 2>&1 | llc-3.4 2>/dev/null | gcc -x assembler ${*:2} - 2>/dev/null
