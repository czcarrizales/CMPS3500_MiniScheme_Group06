MiniScheme Checkpoint 3

Functional (Common Lisp):
- Runs through run_all.sh
- Supports integer literals
- Supports boolean literals
- Supports primitive arithmetic and comparisons
- Supports if
- Supports let
- Supports lambda
- Supports function application
- Supports define
- Supports recursion
- Supports lexical scope
- Supports cond
- Handles required errors:
  - PARSE_ERROR
  - UNDECLARED_IDENTIFIER
  - WRONG_ARITY
  - TYPE_MISMATCH
  - DIVISION_BY_ZERO

Progress in procedural:
  supported features:
  - Integer literals
  - Boolean literals (#t, #f)
  - Arithmetic operations: + - * /
  - Comparisons: = < > <= >=
  - if expressions
  - let bindings
  - lambda functions
  - function application
  - define (top-level)
  - recursion
  - lexical scope
  - cond
  
  The program handles the following errors:
  - PARSE_ERROR
  - UNDECLARED_IDENTIFIER
  - WRONG_ARITY
  - TYPE_MISMATCH
  - DIVISION_BY_ZERO
  
  Notes:
  - The program reads the entire file using readAll()
  - Input is split into tokens using splitTokens()
  - Expressions are parsed into a tree structure (Node)
  - Each Node is evaluated recursively
  - An environment structure is used to store variables and functions
  - The last expression evaluated is printed as the result

Progress in oop:
- progress here

Requirements:
- Functional: SBCL
- Procedural: g++
- Object-Oriented: Java JDK

How to run:
- ./run_all.sh list-cases
- ./run_all.sh run-case functional tests/public/core_01.scm
- ./run_all.sh run-case procedural tests/public/core_01.scm
- ./run_all.sh run-case oop tests/public/core_01.scm
- ./run_all.sh compare-case tests/public/core_01.scm