# ECE 466: Compilers

**Course description**:

The theory, design and implementation of a practical compiler. Finite automata, LL and LR parsing, attribute grammars, syntax-directed translation, symbol tables and scopes, type systems and representations, abstract syntax trees, intermediate representation, basic blocks, data and control flow optimizations, assembly language generation including register and instruction selection. Students apply tools such as Flex and Bison to writing a functional compiler for a subset of a real programming language such as C.

## Prerequisities

### System Requirements

Ensure you are running a 32-bit Linux distro with an Intel CPU. The generated assembly instruction (from genassembly.out) are intended for 32-bit Intel architectures. The compiled executable will also not run on Windows Subsystem for Linux (WSL) aka Bash on Windows: [track this issue](https://github.com/Microsoft/WSL/issues/390).


### Other Dependencies

1. The lexical analyzer flex:

    <code>
    apt-get install flex
    </code>

2. The parser generator bison:

    <code>
    apt-get install bison
    </code>


## Using the toy compiler

1. Run <code>make</code> to generate **miragecompiler.out** and <code>make genassembly.out</code> to generate **genassembly.out**

2. Generate intermediate representation (quads) for simple C programs (with loops, conditional statements, or function calls), and save them in a textfile by redirecting the output

    <code>
    ./miragecompiler.out < simpleprog.c > simplequads.txt
    </code>

3. Use the assembly generator (genassembly.out) to create 32-bit assembly instructions

    <code>
    ./genassembly.out < simplequads.txt > simpleassembly.s
    </code>

4. Use gcc's assembler and linker to generate the executable using the 32-bit assembly instructions

    <code>
    gcc -m32 simpleassembly.s [-o simpleprog.out]
    </code>

5. Run the executable (a.out if you didn't specify a new name)

    <code> ./simpleprog.out
    </code>
