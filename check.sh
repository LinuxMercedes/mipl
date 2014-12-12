#!/bin/bash

green='\x1B[1;32m'
red='\x1B[1;31m'
NC='\x1B[0m' # No Color

# Make a place for da diffs
mkdir -p diffs

echo "##############################################################################"
echo ""
echo "COMPILE THE THINGS!"
echo ""
echo "##############################################################################"

for source_file in tests/*.txt
do
    ./compile $source_file
done

echo "##############################################################################"
echo ""
echo "GO GO THE THING!"
echo ""
echo "##############################################################################"

passed=0
failed=0
broken=0

for result_file in tests/*.result
do
    filename=`basename $result_file .result`
    input=tests/$filename.input
    ./oal_interpreter $result_file < $input > tests/$filename.result.output
    if [ "$?" -ne "0" ]
    then
        broken=$((broken + 1))
    fi
done

for f in tests/*.txt
do
    filename=`basename $f .txt`
    expected_result=tests/${filename}.oal.output
    actual_result=tests/${filename}.result.output

    diff -i -b -B -w --side-by-side $actual_result $expected_result > diffs/${filename%.result}.diff.output

    if [ "$?" -ne "0" ]
    then
        echo -e "${red}Broken${NC}\tdiffs/$file_name$"
        failed=$((failed + 1))
        diff -i -b -B -w $actual_result $expected_result | diffstat
    else
        echo -e "${green}OK${NC}\t$actual_result"
        passed=$((passed + 1))
    fi
done

echo -e "\n\nTests complete"
echo -e "\t$passed passed"
echo -e "\t$broken broken"
echo -e "\t$failed failed"
