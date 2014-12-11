#!/bin/bash

green='\x1B[1;32m'
red='\x1B[1;31m'
NC='\x1B[0m' # No Color

# Make a place for da diffs
mkdir -p diffs

echo "##############################################################################"
echo ""
echo "Do some parsin'"
echo ""
echo "##############################################################################"
for test_file in tests/*.txt
do
    file_name=`basename $test_file`
    ./parser $test_file > tests/${file_name%.txt}.result
done


echo "##############################################################################"
echo ""
echo "Do some diffin'"
echo ""
echo "##############################################################################"

passed=0
failed=0

for actual_result in tests/*.result
do
    file_name=`basename $actual_result`
    expected_result=tests/${file_name%.result}.oal
    diff -i -b -B -w --side-by-side $actual_result $expected_result > diffs/${file_name%.result}.diff
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
echo -e "\t$failed failed"


echo "##############################################################################"
echo ""
echo "Do some runnin'"
echo ""
echo "##############################################################################"

passed=0
failed=0
broken=0

for oal_file in tests/*.oal
do
    filename=`basename $oal_file .oal`
    input=tests/$filename.input
    ./oal_interpreter $oal_file < $input > tests/$filename.oal.output
done

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
