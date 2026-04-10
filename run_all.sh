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
        result="$(sbcl --script functional/evaluator.lisp "$file")"
        echo "Status: OK"
        echo "Result: ${result}"

        if [[ "$result" == "#t" || "$result" == "#f" ]]; then
          echo "Type: bool"
        else
          echo "Type: int"
        fi
        ;;
      procedural|oop)
        echo "Status: ERROR"
        echo "Error: NOT_IMPLEMENTED"
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

    echo "procedural: ERROR -> NOT_IMPLEMENTED"
    echo "oop:        ERROR -> NOT_IMPLEMENTED"

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