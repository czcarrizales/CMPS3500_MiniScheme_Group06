;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; NAME: Chazz
; ASGT: MiniScheme Checkpoint 3
; ORGN: CSUB - CMPS 3500
; FILE: evaluator.lisp
; DATE: 05/01/2026
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This condition stores the required project error category.
(define-condition minisError (error)
  ((category :initarg :category :reader getErrorCategory)))

; This raises a MiniScheme error.
(defun raiseMiniError (error_category)
  (error 'minisError :category error_category))

; This reads the whole file into one string.
(defun readFileAsString (file_path)
  (handler-case
      (with-open-file (input_stream file_path)
        (let ((file_contents
                (make-string (file-length input_stream))))
          (read-sequence file_contents input_stream)
          file_contents))
    (error ()
      (raiseMiniError "PARSE_ERROR"))))

; This changes #t and #f into symbols SBCL can read.
(defun replaceBooleanTokens (file_contents)
  (with-output-to-string (output_stream)
    (let ((current_index 0)
          (text_length (length file_contents)))
      (loop while (< current_index text_length)
            do
              (cond
                ((and (< (+ current_index 1) text_length)
                      (char= (char file_contents current_index) #\#)
                      (char= (char file_contents
                                    (+ current_index 1)) #\t))
                 (write-string "true" output_stream)
                 (setf current_index (+ current_index 2)))

                ((and (< (+ current_index 1) text_length)
                      (char= (char file_contents current_index) #\#)
                      (char= (char file_contents
                                    (+ current_index 1)) #\f))
                 (write-string "false" output_stream)
                 (setf current_index (+ current_index 2)))

                (t
                 (write-char (char file_contents current_index)
                             output_stream)
                 (setf current_index (+ current_index 1))))))))

; This reads every expression from the file.
(defun readAllExpressions (file_path)
  (handler-case
      (let* ((file_contents (readFileAsString file_path))
             (updated_contents
               (replaceBooleanTokens file_contents)))
        (with-input-from-string (input_stream updated_contents)
          (loop for current_expression = (read input_stream nil 'eof)
                until (eq current_expression 'eof)
                collect current_expression)))
    (minisError (problem)
      (raiseMiniError (getErrorCategory problem)))
    (error ()
      (raiseMiniError "PARSE_ERROR"))))

; This checks for an exact list length.
(defun hasLength (expression expected_length)
  (and (listp expression)
       (= (length expression) expected_length)))

; This checks that every item is a symbol.
(defun allSymbols (item_list)
  (and (listp item_list)
       (every #'symbolp item_list)))

; This finds a variable in the environment.
(defun lookupVariable (variable_name environment)
  (let ((matching_binding (assoc variable_name environment)))
    (if matching_binding
        (cdr matching_binding)
        (raiseMiniError "UNDECLARED_IDENTIFIER"))))

; This adds new bindings to the environment.
(defun extendEnvironment (parameter_names argument_values environment)
  (append (pairlis parameter_names argument_values)
          environment))

; This creates a closure for lexical scope.
(defun createClosure (parameter_names body_expressions saved_environment)
  (list 'closure
        parameter_names
        body_expressions
        saved_environment))

; This checks if a value is a closure.
(defun isClosure (possible_closure)
  (and (listp possible_closure)
       (eq (first possible_closure) 'closure)))

; This gets the parameters from a closure.
(defun getClosureParameters (closure_value)
  (second closure_value))

; This gets the body from a closure.
(defun getClosureBody (closure_value)
  (third closure_value))

; This gets the saved environment from a closure.
(defun getClosureEnvironment (closure_value)
  (fourth closure_value))

; This checks if the symbol is a built-in operator.
(defun isPrimitiveOperator (operator_symbol)
  (member operator_symbol '(+ - * / = < > <= >=)))

; In MiniScheme, only false is false.
(defun isTrueValue (value)
  (not (eq value 'false)))

; This checks that all arguments are integers.
(defun checkIntegerArguments (argument_values)
  (dolist (single_value argument_values)
    (unless (integerp single_value)
      (raiseMiniError "TYPE_MISMATCH"))))

; This checks that primitive operators have enough arguments.
(defun checkPrimitiveArity (argument_values)
  (when (< (length argument_values) 2)
    (raiseMiniError "WRONG_ARITY")))

; This checks division by zero.
(defun checkDivisionByZero (argument_values)
  (dolist (single_value (rest argument_values))
    (when (= single_value 0)
      (raiseMiniError "DIVISION_BY_ZERO"))))

; This performs integer division.
(defun applyIntegerDivision (argument_values)
  (checkDivisionByZero argument_values)
  (truncate (reduce #'/ argument_values)))

; This runs built-in math and comparison operators.
(defun applyPrimitiveOperator (operator_symbol evaluated_arguments)
  (checkPrimitiveArity evaluated_arguments)
  (checkIntegerArguments evaluated_arguments)

  (case operator_symbol
    (+  (apply #'+ evaluated_arguments))
    (-  (apply #'- evaluated_arguments))
    (*  (apply #'* evaluated_arguments))
    (/  (applyIntegerDivision evaluated_arguments))
    (=  (if (apply #'= evaluated_arguments) 'true 'false))
    (<  (if (apply #'< evaluated_arguments) 'true 'false))
    (>  (if (apply #'> evaluated_arguments) 'true 'false))
    (<= (if (apply #'<= evaluated_arguments) 'true 'false))
    (>= (if (apply #'>= evaluated_arguments) 'true 'false))
    (otherwise
      (raiseMiniError "TYPE_MISMATCH"))))

; This evaluates several expressions and keeps the last result.
(defun evaluateExpressionList (expression_list environment)
  (let ((last_result nil))
    (dolist (current_expression expression_list last_result)
      (setf last_result
            (evaluateExpression current_expression environment)))))

; This checks let binding syntax.
(defun checkLetBindings (binding_list)
  (unless (listp binding_list)
    (raiseMiniError "PARSE_ERROR"))

  (dolist (single_binding binding_list)
    (unless (and (listp single_binding)
                 (= (length single_binding) 2)
                 (symbolp (first single_binding)))
      (raiseMiniError "PARSE_ERROR"))))

; This evaluates the values inside let bindings.
(defun evaluateLetBindings (binding_list environment)
  (checkLetBindings binding_list)

  (mapcar
   (lambda (single_binding)
     (cons (first single_binding)
           (evaluateExpression (second single_binding)
                               environment)))
   binding_list))

; This calls a closure with argument values.
(defun evaluateFunctionCall (function_value argument_values)
  (if (isClosure function_value)
      (let ((parameter_names
              (getClosureParameters function_value))
            (body_expressions
              (getClosureBody function_value))
            (saved_environment
              (getClosureEnvironment function_value)))
        (if (/= (length parameter_names) (length argument_values))
            (raiseMiniError "WRONG_ARITY")
            (evaluateExpressionList
             body_expressions
             (extendEnvironment parameter_names
                                argument_values
                                saved_environment))))
      (raiseMiniError "TYPE_MISMATCH")))

; This evaluates an if expression.
(defun evaluateIfExpression (expression environment)
  (unless (hasLength expression 4)
    (raiseMiniError "PARSE_ERROR"))

  (let ((test_result
          (evaluateExpression (second expression)
                              environment)))
    (if (isTrueValue test_result)
        (evaluateExpression (third expression) environment)
        (evaluateExpression (fourth expression) environment))))

; This evaluates a let expression.
(defun evaluateLetExpression (expression environment)
  (when (< (length expression) 3)
    (raiseMiniError "PARSE_ERROR"))

  (let* ((binding_list (second expression))
         (body_expressions (cddr expression))
         (new_bindings
           (evaluateLetBindings binding_list environment))
         (extended_environment
           (append new_bindings environment)))
    (evaluateExpressionList body_expressions
                            extended_environment)))

; This evaluates a lambda expression.
(defun evaluateLambdaExpression (expression environment)
  (when (< (length expression) 3)
    (raiseMiniError "PARSE_ERROR"))

  (let ((parameter_names (second expression))
        (body_expressions (cddr expression)))
    (unless (allSymbols parameter_names)
      (raiseMiniError "PARSE_ERROR"))

    (createClosure parameter_names
                   body_expressions
                   environment)))

; This evaluates a built-in operator expression.
(defun evaluatePrimitiveExpression (expression environment)
  (let ((operator_symbol (first expression))
        (argument_expressions (rest expression)))
    (applyPrimitiveOperator
     operator_symbol
     (mapcar (lambda (argument_expression)
               (evaluateExpression argument_expression
                                   environment))
             argument_expressions))))

; This evaluates cond clauses in order.
(defun evaluateCondExpression (expression environment)
  (when (< (length expression) 2)
    (raiseMiniError "PARSE_ERROR"))

  (block cond_result
    (let ((clause_list (rest expression)))
      (loop for single_clause in clause_list
            for remaining_clauses on clause_list
            do
              (unless (and (listp single_clause)
                           (= (length single_clause) 2))
                (raiseMiniError "PARSE_ERROR"))

              (let ((test_expression (first single_clause))
                    (result_expression (second single_clause)))
                (cond
                  ((eq test_expression 'else)
                   (unless (null (rest remaining_clauses))
                     (raiseMiniError "PARSE_ERROR"))
                   (return-from cond_result
                     (evaluateExpression result_expression
                                         environment)))

                  ((isTrueValue
                    (evaluateExpression test_expression environment))
                   (return-from cond_result
                     (evaluateExpression result_expression
                                         environment))))))

      ; If no clause matches, return false.
      'false)))

; This evaluates a normal function call.
(defun evaluateApplicationExpression (expression environment)
  (let ((function_value
          (evaluateExpression (first expression)
                              environment))
        (argument_values
          (mapcar (lambda (argument_expression)
                    (evaluateExpression argument_expression
                                        environment))
                  (rest expression))))
    (evaluateFunctionCall function_value argument_values)))

; This is the main expression evaluator.
(defun evaluateExpression (expression environment)
  (cond
    ((integerp expression)
     expression)

    ((eq expression 'true)
     'true)

    ((eq expression 'false)
     'false)

    ((symbolp expression)
     (lookupVariable expression environment))

    ((listp expression)
     (when (null expression)
       (raiseMiniError "PARSE_ERROR"))

     (let ((first_part (first expression)))
       (cond
         ((eq first_part 'if)
          (evaluateIfExpression expression environment))

         ((eq first_part 'let)
          (evaluateLetExpression expression environment))

         ((eq first_part 'lambda)
          (evaluateLambdaExpression expression environment))

         ((eq first_part 'cond)
          (evaluateCondExpression expression environment))

         ((eq first_part 'define)
          (raiseMiniError "PARSE_ERROR"))

         ((isPrimitiveOperator first_part)
          (evaluatePrimitiveExpression expression environment))

         (t
          (evaluateApplicationExpression expression environment)))))

    (t
     (raiseMiniError "TYPE_MISMATCH"))))

; This handles a top-level define.
(defun evaluateDefineExpression (expression environment)
  (unless (and (hasLength expression 3)
               (symbolp (second expression)))
    (raiseMiniError "PARSE_ERROR"))

  (let* ((variable_name (second expression))
         (placeholder_binding (cons variable_name nil))
         (extended_environment
           (cons placeholder_binding environment))
         (defined_value
           (evaluateExpression (third expression)
                               extended_environment)))
    (setf (cdr placeholder_binding) defined_value)
    (values defined_value extended_environment nil)))

; This evaluates one top-level expression.
(defun evaluateTopLevelExpression (expression environment)
  (if (and (listp expression)
           (not (null expression))
           (eq (first expression) 'define))
      (evaluateDefineExpression expression environment)
      (values (evaluateExpression expression environment)
              environment
              t)))

; This evaluates the whole file.
(defun evaluateProgram (expression_list)
  (when (null expression_list)
    (raiseMiniError "PARSE_ERROR"))

  (let ((environment nil)
        (last_result nil)
        (has_printable_result nil))
    (dolist (current_expression expression_list)
      (multiple-value-bind
          (current_result updated_environment is_printable)
          (evaluateTopLevelExpression current_expression environment)
        (setf environment updated_environment)
        (when is_printable
          (setf last_result current_result)
          (setf has_printable_result t))))

    (if has_printable_result
        last_result
        'true)))

; This turns a value into MiniScheme text.
(defun valueToString (value)
  (cond
    ((eq value 'true)
     "#t")
    ((eq value 'false)
     "#f")
    ((isClosure value)
     "<function>")
    (t
     (format nil "~a" value))))

; This gets the MiniScheme type.
(defun valueType (value)
  (cond
    ((integerp value)
     "int")
    ((or (eq value 'true)
         (eq value 'false))
     "bool")
    ((isClosure value)
     "function")
    (t
     "unknown")))

; This reads and evaluates one file.
(defun evaluateFile (file_path)
  (let* ((expression_list (readAllExpressions file_path))
         (final_result (evaluateProgram expression_list)))
    final_result))

; This prints output for run_all.sh to parse.
(defun printProgramResult (value)
  (format t "OK|~a|~a~%"
          (valueToString value)
          (valueType value)))

; This runs the evaluator from the terminal.
(defun main ()
  (let ((command_line_arguments sb-ext:*posix-argv*))
    (if (> (length command_line_arguments) 1)
        (let ((file_path (car (last command_line_arguments))))
          (handler-case
              (printProgramResult (evaluateFile file_path))
            (minisError (problem)
              (format t "ERROR|~a~%"
                      (getErrorCategory problem)))
            (error ()
              (format t "ERROR|PARSE_ERROR~%"))))
        (format t "ERROR|PARSE_ERROR~%"))))

(main)