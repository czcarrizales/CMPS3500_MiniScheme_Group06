CMPS 3500 MiniScheme Comparative Implementation — Final Submission

Project Overview:
This project implements the same MiniScheme expression engine in three programming paradigms:
procedural C++, object-oriented Java, and functional Common Lisp. Each implementation reads
MiniScheme case files, evaluates expressions, and reports either a result with a type or a
standardized error through the shared run_all.sh runner.

Project Structure:
- procedural/   C++ procedural implementation
- oop/          Java object-oriented implementation
- functional/   Common Lisp functional implementation
- tests/        Public MiniScheme test cases
- challenges/   Public/hidden challenge case folders
- docs/         Technical brief and contribution statements
- run_all.sh    Main command-line runner
- README.txt    Project overview and run instructions

Supported MiniScheme Features:
All three implementations support:
- Integer literals
- Boolean literals
- Primitive arithmetic: + - * /
- Primitive comparisons: = < > <= >=
- if expressions
- let bindings
- lambda functions
- Function application
- define for top-level bindings
- Recursion
- Lexical scope
- cond add-on

Required Error Categories:
All three implementations handle:
- PARSE_ERROR
- UNDECLARED_IDENTIFIER
- WRONG_ARITY
- TYPE_MISMATCH
- DIVISION_BY_ZERO

Implementation Notes:

Procedural (C++):
- Reads input files and splits input into tokens
- Parses expressions into a Node-style tree structure
- Evaluates Nodes recursively
- Uses an environment structure for variables and functions

Object-Oriented (Java):
- Uses tokenizer and parser logic to build expression objects
- Organizes MiniScheme expressions through classes
- Uses an Environment object for bindings
- Uses closures for lambda functions and lexical scope

Functional (Common Lisp):
- Uses recursive evaluation and list processing
- Uses an environment to store variable and function bindings
- Uses closures to preserve the environment where lambdas are created
- Runs through SBCL

Requirements:
- g++
- Java JDK
- SBCL

Important:
Run all commands from the top-level project folder, the same folder that contains run_all.sh.

How to Run:
- chmod +x run_all.sh
- ./run_all.sh list-cases
- ./run_all.sh run-case procedural tests/public/core_01.scm
- ./run_all.sh run-case oop tests/public/core_01.scm
- ./run_all.sh run-case functional tests/public/core_01.scm
- ./run_all.sh compare-case tests/public/core_01.scm
- ./run_all.sh compare-case tests/public/recursion_01.scm
- ./run_all.sh compare-case tests/public/error_01.scm
- ./run_all.sh compare-case tests/public/addon_01.scm

Defensive Scripting Examples:
- ./run_all.sh compare-case fake_file.scm
- ./run_all.sh bad-command