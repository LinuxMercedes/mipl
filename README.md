MIPL
====

Mini-Imperative Programming Language Compiler - CS 5500

About this Compiler
-------------------

This MIPL compiler is built using the LLVM compiler
infrastructure. LLVM uses an intermediate language called LLVM IR,
which can be analyzed, optimized, and compiled to create executables
for a variety of different architectures. LLVM is used by a number of
modern compiler infrastructure projects including Clang, Rust, and
Swift.

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

### compile.sh

``compile.sh`` pipes the LLVM IR from ``IRGen`` through ``opt``, the
LLVM optimizer. Then, the optimized code is piped though ``llc``,
which translates LLVM IR into assembly code. The assembly is finally
passed to ``clang``, which assembles, links, and generates an
executable.



<!--  LocalWords:  LLVM MIPL executables IRGen optimizers
 -->
