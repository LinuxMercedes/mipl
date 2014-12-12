#!/bin/bash

./parser $@ 2>&1 | llc-3.4 | gcc -x assembler -o a.out -
./a.out
