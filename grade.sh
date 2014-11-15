#!/bin/bash

set -v

flex wiselym.l
bison wiselym.y
g++ wiselym.tab.c -o parser

# wiselym_parser < inputFileName
bash check.sh
