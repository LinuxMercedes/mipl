MIPL
====

Mini-Imperative Programming Language Compiler - CS 5500

About this Compiler
-------------------

This MIPL compiler is built using the LLVM compiler
infrastructure. LLVM uses an intermediate language called LLVM IR,
which can be analyzed, optimized, and compiled to create executables
for a variety of different architectures. LLVM is used by a number of
modern compiler projects including Clang, Rust, and Swift.

The compiler works in several stages. First, ``IRGen`` parses MIPL
code and translates it into an intermediate code. Then, the
intermediate code is optimized and translated to assembly code. Then,
assembly code can be assembled linked and made into an executable.

A number of different optimizers are available for LLVM IR code. For
this project, we've chosen to turn on dead code elimination, dead
storage elimination, constant propagation, and instruction
combine. Information about other LLVM optimizers can be found on
[their website](http://llvm.org/docs/Passes.html).


Implementation
--------------

### ``IRGen``

The source for ``IRGen`` is generated using flex (for lexing) and bison
(for parsing). ``IRGen`` generates LLVM IR with help from the
``llvm::IRBuilder`` C++ class. This class (and other helpful LLVM
libraries) allow for the construction of LLVM IR functions and
modules. LLVM also provides helper functions to verify the built
functions and modules to ensure that the IR code is sound.

``IRGen`` can be compiled using any C++ compiler (like ``g++`` or
``clang``). Your compiler will likely require the locations of header
and library files in order to build it. The flags indicating the
locations of these files can be found using ``llvm-config-3.4
--cxxflags --libs core`` and ``llvm-config-3.4 --ldflags --libs
core``. If you're building using ``g++``, be sure to pass the ``ld``
flags after listing the source files.

### ``compile.sh``

``compile.sh`` pipes the LLVM IR from ``IRGen`` through ``opt``, the
LLVM optimizer. Then, the optimized code is piped though ``llc``,
which translates LLVM IR into assembly code. The assembly is finally
passed to ``clang``, which assembles, links, and generates an
executable.


Building
--------

You'll need to have the following packages:

- ``flex``
- ``bison``
- ``llvm`` Version 3.4. If you install Clang, the LLVM tools should
  come with it.
- ``make``

Just run ``make`` to build ``IRGen``, which will generate the LLVM IR
code for a MIPL file. **This code has been tested on S&T CLC Linux
machines.** ``check.sh`` will run a series of tests on the compiled
MIPL code to verify that it works properly.


Usage
-----

After building ``IRGen``, you can start building MIPL programs!


Building and running a MIPL program:

```shell
$ ./compile.sh tests/writeConstants.txt
$ ./a.out
5!-42
```

You can even pass arguments to the assembler/linker

```shell
$ ./compile.sh tests/writeConstants.txt -o writeConstants.out
$ ./writeConstants.out
5!-42
```

You can talk to it too

```shell
$ ./compile.sh tests/allKindsOfThings.txt
$ ./a.out
> 4
> 5
> 6
> 7
> -1
( 4 5 6 7 )
? 3
No match for 3
? 4
Stuff[1] = 4
? -1
end
```


Testing
-------

A variety of test MIPL programs are included in the ``tests/``
directory. These programs were written by Dr. Jennifer Leopold to help
students test their CS 5500 assignments. A test script (``check.sh``)
is included to test our MIPL compiler on each of the test MIPL
programs and compare the output of the compiled executables against
the output generated by Dr. Leopold's compiled OAL programs. Here is
the basic breakdown of ``check.sh``:

1. Iterate through all MIPL test files ending in ``.txt``
2. Run ``compile.sh`` on each MIPL source file
   - Count the number of files that don't compile
3. Run each of the compiled MIPL programs on a given input file and
   save the output
   - Skip testing any programs that didn't successfully compile
4. Diff the output from the executed MIPL against the output from
   Dr. Leopold's OAL program and record the difference
   - Check the output from the diff
   - Count the number of successful runs (The files were the same,
     and diff had a return code of 0)
   - Count the number of failed runs (The files were different somehow
     and diff had a non-zero return code)
5. Output the results

They should like just about like this:

```
$ make
flex mipl.l
bison mipl.y
mipl.y: warning: 1 shift/reduce conflict [-Wconflicts-sr]
clang++ -g -Wno-switch `llvm-config-3.4 --cxxflags --libs core` mipl.tab.c `llvm-config-3.4 --ldflags --libs core` -o IRGen
clang: warning: treating 'c' input as 'c++' when in C++ mode, this behavior is deprecated

$ ./check.sh
##############################################################################

COMPILE THE THINGS!

##############################################################################

##############################################################################

GO DO THE THING!

##############################################################################
OK	tests/allKindsOfThings.resultp
OK	tests/arrayReferences.resultp
OK	tests/assignmentSimpleArithOpsExpr.resultp
OK	tests/assignmentSimpleNegation.resultp
OK	tests/assignmentSimpleRelOpsExpr.resultp
OK	tests/assignmentSimple.resultp
OK	tests/ifThenElseFalse.resultp
OK	tests/ifThenElseNested1.resultp
OK	tests/ifThenElseNested2.resultp
OK	tests/ifThenElseNested3.resultp
OK	tests/ifThenElseNested4.resultp
OK	tests/ifThenElseTrue.resultp
OK	tests/ifThenFalse.resultp
OK	tests/ifThenTrue.resultp
OK	tests/justSimpleAndArrayGlobals.resultp
OK	tests/justSimpleGlobals.resultp
OK	tests/multiProcDeclWithCalls.resultp
OK	tests/nestedProcDeclWithCalls.resultp
OK	tests/nestedProcDeclWithLocalsNoCalls.resultp
OK	tests/noGlobalsOrProcs.resultp
OK	tests/oneProcDeclNoLocalsNoCalls.resultp
OK	tests/oneProcDeclWithCall.resultp
OK	tests/oneProcDeclWithLocalsNoCalls.resultp
OK	tests/oneProcDeclWithRecursiveCall.resultp
OK	tests/readIndividuals.resultp
OK	tests/readMultiples.resultp
OK	tests/simpleStmtsFromWithinProc.resultp
OK	tests/twoProcDeclWithLocalsNoCalls.resultp
OK	tests/whileNestedDeep.resultp
OK	tests/whileNested.resultp
OK	tests/whileSimple.resultp
OK	tests/writeConstants.resultp


Tests complete
        32 passed
        0 skipped
        0 failed
        0 didn't compile

```


<!-- LocalWords: LLVM MIPL executables IRGen optimizers -->
