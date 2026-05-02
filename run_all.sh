#!/usr/bin/env bash
set -euo pipefail

cmd="${1:-}"

check_file_exists() {
  file="$1"

  if [[ -z "$file" || ! -f "$file" ]]; then
    return 1
  fi

  return 0
}

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

    if ! check_file_exists "$file"; then
  echo "Status: ERROR"
  echo "Error: PARSE_ERROR"
  exit 0
fi

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
        javac oop/MiniScheme.java -d oop/bin
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

    if ! check_file_exists "$file"; then
  echo "procedural: ERROR -> PARSE_ERROR"
  echo "oop:        ERROR -> PARSE_ERROR"
  echo "functional: ERROR -> PARSE_ERROR"
  exit 0
fi

    procedural_output="$(./run_all.sh run-case procedural "$file")"
    procedural_status="$(echo "$procedural_output" | grep '^Status:' | cut -d' ' -f2)"
    if [[ "$procedural_status" == "OK" ]]; then
      procedural_result="$(echo "$procedural_output" | grep '^Result:' | cut -d' ' -f2-)"
      procedural_type="$(echo "$procedural_output" | grep '^Type:' | cut -d' ' -f2)"
      echo "procedural: OK -> ${procedural_result} : ${procedural_type}"
    else
      procedural_error="$(echo "$procedural_output" | grep '^Error:' | cut -d' ' -f2-)"
      echo "procedural: ERROR -> ${procedural_error}"
    fi

    oop_output="$(./run_all.sh run-case oop "$file")"
    oop_status="$(echo "$oop_output" | grep '^Status:' | cut -d' ' -f2)"
    if [[ "$oop_status" == "OK" ]]; then
      oop_result="$(echo "$oop_output" | grep '^Result:' | cut -d' ' -f2-)"
      oop_type="$(echo "$oop_output" | grep '^Type:' | cut -d' ' -f2)"
      echo "oop:        OK -> ${oop_result} : ${oop_type}"
    else
      oop_error="$(echo "$oop_output" | grep '^Error:' | cut -d' ' -f2-)"
      echo "oop:        ERROR -> ${oop_error}"
    fi

    functional_output="$(./run_all.sh run-case functional "$file")"
    functional_status="$(echo "$functional_output" | grep '^Status:' | cut -d' ' -f2)"
    if [[ "$functional_status" == "OK" ]]; then
      functional_result="$(echo "$functional_output" | grep '^Result:' | cut -d' ' -f2-)"
      functional_type="$(echo "$functional_output" | grep '^Type:' | cut -d' ' -f2)"
      echo "functional: OK -> ${functional_result} : ${functional_type}"
    else
      functional_error="$(echo "$functional_output" | grep '^Error:' | cut -d' ' -f2-)"
      echo "functional: ERROR -> ${functional_error}"
    fi
    ;;
esac
