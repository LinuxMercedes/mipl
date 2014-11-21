#!/bin/bash

green='\x1B[1;32m'
red='\x1B[1;31m'
NC='\x1B[0m' # No Color

# Make a place for da diffs
mkdir -p diffs

# Do some parsin'
for test_file in tests/*.txt
do
    file_name=`basename $test_file`
    ./parser $test_file > tests/${file_name%.txt}.result
done

passed=0
failed=0

# Do some diffin'
for actual_result in tests/*.result
do
    file_name=`basename $actual_result`
    expected_result=tests/${file_name%.result}.oal
    diff $actual_result $expected_result --ignore-space-change --side-by-side --ignore-case --ignore-blank-lines > diffs/${file_name%.result}.diff
    if [ "$?" -ne "0" ]
    then
        echo -e "${red}Broken${NC}\tdiffs/$file_name$"
        failed=$((failed + 1))
        diff $actual_result $expected_result --ignore-space-change --ignore-case --ignore-blank-lines | diffstat
    else
        echo -e "${green}OK${NC}\t$actual_result"
        passed=$((passed + 1))
    fi
done

echo -e "\n\nTests complete"
echo -e "\t$passed passed"
echo -e "\t$failed failed"
