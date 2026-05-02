#!/usr/bin/env bash
set -euo pipefail

cmd="${1:-}"

case "$cmd" in
  list-cases)
    find tests/public challenges/public -type f \
      \( -name '*.scm' -o -name '*.txt' \) 2>/dev/null | sort || true
    ;;

  run-case)
    impl="${2:-}"
    file="${3:-}"

    echo "Implementation: ${impl}"
    echo "Case: ${file}"

    case "$impl" in
      functional)
  raw_output="$(sbcl --script functional/evaluator.lisp "$file")"

  if [[ "$raw_output" == OK\|* ]]; then
    IFS='|' read -r status result result_type <<< "$raw_output"
    echo "Status: OK"
    echo "Result: ${result}"
    echo "Type: ${result_type}"
  elif [[ "$raw_output" == ERROR\|* ]]; then
    IFS='|' read -r status error_category <<< "$raw_output"
    echo "Status: ERROR"
    echo "Error: ${error_category}"
  else
    echo "Status: ERROR"
    echo "Error: PARSE_ERROR"
  fi
  ;;
        oop)
        mkdir -p oop/bin
        javac oop/src/*.java -d oop/bin
        result="$(java -cp oop/bin MiniScheme "$file")"

        if [[ "$result" == *"UNDECLARED_IDENTIFIER"* || \
              "$result" == *"DIVISION_BY_ZERO"* || \
              "$result" == *"WRONG_ARITY"* || \
              "$result" == *"TYPE_MISMATCH"* || \
              "$result" == *"PARSE_ERROR"* ]]; then
          echo "Status: ERROR"
          echo "Error: ${result}"
        else
          echo "Status: OK"
          echo "Result: ${result}"

          if [[ "$result" == "#t" || "$result" == "#f" ]]; then
            echo "Type: bool"
          else
            echo "Type: int"
          fi
        fi
        ;;
        procedural)
        g++ procedural/*.cpp -o procedural/minischeme
        ./procedural/minischeme "$file"
        ;;
      *)
        echo "Status: ERROR"
        echo "Error: UNKNOWN_IMPLEMENTATION"
        ;;
    esac
    ;;

  compare-case)
    file="${2:-}"

    echo "Case: ${file}"
    echo

    proc_result="$(./procedural/minischeme "$file")"
    if [[ "$proc_result" == "#t" || "$proc_result" == "#f" ]]; then
      echo "procedural: OK -> ${proc_result} : bool"
    else
      echo "procedural: OK -> ${proc_result} : int"
    fi
    
    oop_result="$(java -cp oop MiniScheme "$file")"
    if [[ "$oop_result" == "#t" || "$oop_result" == "#f" ]]; then
      echo "oop:        OK -> ${oop_result} : bool"
    else
      echo "oop:        OK -> ${oop_result} : int"
    fi

    result="$(sbcl --script functional/evaluator.lisp "$file")"
    if [[ "$result" == "#t" || "$result" == "#f" ]]; then
      echo "functional: OK -> ${result} : bool"
    else
      echo "functional: OK -> ${result} : int"
    fi
    ;;
    
  *)
    echo "Usage: ./run_all.sh {list-cases|run-case <implementation> <file>|compare-case <file>}"
    exit 1
    ;;
esac
