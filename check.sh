#!/bin/bash

if [ ! -e ./IRGen ]
then
    echo "Please build IRGen first."
    exit 1
fi

green='\x1B[1;32m'
red='\x1B[1;31m'
NC='\x1B[0m' # No Color

# Make a place for da diffs
mkdir -p diffs

passed=0
skipped=0
failed=0
broken=0

echo "##############################################################################"
echo ""
echo "COMPILE THE THINGS!"
echo ""
echo "##############################################################################"

for source_file in tests/*.txt
do
    ./compile.sh $source_file -o ${source_file%.txt}.out

    if [ "$?" -ne "0" ]
    then
        echo -e "${red}Failed to compile $source_file${NC}"
        broken=$((broken + 1))
    fi
done

echo ""
echo "##############################################################################"
echo ""
echo "GO DO THE THING!"
echo ""
echo "##############################################################################"

for llvm_executable in tests/*.out
do
    filename=`basename $llvm_executable .out`
    input=tests/$filename.input
    ./$llvm_executable < $input > tests/$filename.result
done

for f in tests/*.txt
do
    filename=`basename $f .txt`
    expected_result=tests/${filename}.oal.output
    actual_result=tests/${filename}.result

    if [ ! -e "$actual_result" ]
    then
        echo -e "${red}Skip${NC}\t$actual_result not found. Skipping it."
        skipped=$((skipped + 1))
        continue
    fi

    diff -i -b -B -w --side-by-side $actual_result $expected_result > diffs/${filename}.diff.output

    if [ "$?" -ne "0" ]
    then
        echo -e "${red}Broken${NC}\tdiffs/$file_name$"
        failed=$((failed + 1))
        diff -i -b -B -w $actual_result $expected_result | diffstat
    else
        echo -e "${green}OK${NC}\t$actual_result"p
        passed=$((passed + 1))
    fi
done

echo -e "\n\nTests complete"
echo -e "\t$passed passed"
echo -e "\t$skipped skipped"
echo -e "\t$failed failed"
echo -e "\t$broken didn't compile"
