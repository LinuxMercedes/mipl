#!/bin/bash

# Make a place for the results
mkdir -p actual diffs

# Do some parsin'
for test_file in test/*
do
    file_name=`basename $test_file`
    ./parser < $test_file > actual/$file_name.out
done

passed=0
failed=0

# Do some diffin'
for actual_result in actual/*
do
    file_name=`basename $actual_result`
    expected_result=expected/$file_name
    diff $actual_result $expected_result --ignore-space-change --side-by-side --ignore-case --ignore-blank-lines > diffs/$file_name
    if [ "$?" -ne "0" ]
    then
        echo -e "Broken\tdiffs/$file_name$"
        failed=$((failed + 1))
        diff $actual_result $expected_result --ignore-space-change --ignore-case --ignore-blank-lines | diffstat
    else
        echo -e "OK\t$actual_result"
        passed=$((passed + 1))
    fi
done

echo -e "\n\nTests complete"
echo -e "\t$passed passed"
echo -e "\t$failed failed"
