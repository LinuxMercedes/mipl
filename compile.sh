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


./IRGen $1 2>&1 | opt-3.4 -instcombine -dce -dse -constprop -S 2>/dev/null | llc-3.4 2>/dev/null | clang -x assembler ${*:2} - 2>/dev/null
