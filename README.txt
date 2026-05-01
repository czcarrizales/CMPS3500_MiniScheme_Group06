MiniScheme Checkpoint 2

Fully functional implementation:
- functional (Common Lisp)

Working core features in functional:
- integer literals
- boolean literals
- primitive arithmetic
- primitive comparisons
- if
- let
- lambda
- function application
- lexical scope

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
- SBCL (Steel Bank Common Lisp)

Install SBCL:
- Windows: https://www.sbcl.org/
- Mac: brew install sbcl
- Linux (Ubuntu/Debian): sudo apt install sbcl

How to run:
- ./run_all.sh run-case functional tests/public/core_01.scm
- ./run_all.sh compare-case tests/public/core_01.scm
