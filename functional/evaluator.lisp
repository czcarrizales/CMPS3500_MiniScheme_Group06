;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; NAME: Chazz Carrizales
; ASGT: MiniScheme Checkpoint 2
; ORGN: CSUB - CMPS 3500
; FILE: evaluator.lisp
; DATE: 04/10/2026
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This reads the whole file into one string.
(defun readFileAsString (file_path)
  (with-open-file (input_stream file_path)
    (let ((file_contents
            (make-string (file-length input_stream))))
      (read-sequence file_contents input_stream)
      file_contents)))

; This changes #t and #f into words that SBCL can read.
(defun replaceBooleanTokens (file_contents)
  (with-output-to-string (output_stream)
    (loop with text_length = (length file_contents)
          for index from 0 below text_length
          do
            (cond
              ((and (< (+ index 1) text_length)
                    (char= (char file_contents index) #\#)
                    (char= (char file_contents (+ index 1)) #\t))
               (write-string "true" output_stream)
               (incf index))
              ((and (< (+ index 1) text_length)
                    (char= (char file_contents index) #\#)
                    (char= (char file_contents (+ index 1)) #\f))
               (write-string "false" output_stream)
               (incf index))
              (t
               (write-char (char file_contents index)
                           output_stream))))))

; This reads every expression from the file.
(defun readAllExpressions (file_path)
  (let* ((file_contents (readFileAsString file_path))
         (updated_contents
           (replaceBooleanTokens file_contents)))
    (with-input-from-string (input_stream updated_contents)
      (loop for current_expression = (read input_stream nil 'eof)
            until (eq current_expression 'eof)
            collect current_expression))))

; This looks for a variable in the environment.
(defun lookupVariable (variable_name environment)
  (let ((matching_binding (assoc variable_name environment)))
    (if matching_binding
        (cdr matching_binding)
        (error "UNDECLARED_IDENTIFIER"))))

; This adds new variable bindings to the environment.
(defun extendEnvironment (parameter_names argument_values environment)
  (append (pairlis parameter_names argument_values)
          environment))

; This makes a closure.
(defun createClosure (parameter_names body_expressions saved_environment)
  (list 'closure
        parameter_names
        body_expressions
        saved_environment))

; This checks if a value is a closure.
(defun isClosure (possible_closure)
  (and (listp possible_closure)
       (eq (first possible_closure) 'closure)))

; This gets the parameter list from a closure.
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

; In MiniScheme, only false counts as false.
(defun isTrueValue (value)
  (not (eq value 'false)))

; This runs built-in math and comparison operators.
(defun applyPrimitiveOperator (operator_symbol evaluated_arguments)
  (case operator_symbol
    (+  (apply #'+ evaluated_arguments))
    (-  (apply #'- evaluated_arguments))
    (*  (apply #'* evaluated_arguments))
    (/  (apply #'/ evaluated_arguments))
    (=  (if (apply #'= evaluated_arguments)
            'true
            'false))
    (<  (if (apply #'< evaluated_arguments)
            'true
            'false))
    (>  (if (apply #'> evaluated_arguments)
            'true
            'false))
    (<= (if (apply #'<= evaluated_arguments)
            'true
            'false))
    (>= (if (apply #'>= evaluated_arguments)
            'true
            'false))
    (otherwise
      (error "TYPE_MISMATCH"))))

; This evaluates several expressions and keeps the last result.
(defun evaluateExpressionList (expression_list environment)
  (let ((last_result nil))
    (dolist (current_expression expression_list last_result)
      (setf last_result
            (evaluateExpression current_expression environment)))))

; This evaluates the values inside a let binding list.
(defun evaluateLetBindings (binding_list environment)
  (mapcar
   (lambda (single_binding)
     (cons (first single_binding)
           (evaluateExpression (second single_binding)
                               environment)))
   binding_list))

; This calls a function with its argument values.
(defun evaluateFunctionCall (function_value argument_values)
  (if (isClosure function_value)
      (let ((parameter_names
              (getClosureParameters function_value))
            (body_expressions
              (getClosureBody function_value))
            (saved_environment
              (getClosureEnvironment function_value)))
        (if (/= (length parameter_names) (length argument_values))
            (error "WRONG_ARITY")
            (evaluateExpressionList
             body_expressions
             (extendEnvironment parameter_names
                                argument_values
                                saved_environment))))
      (error "TYPE_MISMATCH")))

; This evaluates an if expression.
(defun evaluateIfExpression (expression environment)
  (let ((test_result
          (evaluateExpression (second expression)
                              environment)))
    (if (isTrueValue test_result)
        (evaluateExpression (third expression)
                            environment)
        (evaluateExpression (fourth expression)
                            environment))))

; This evaluates a let expression.
(defun evaluateLetExpression (expression environment)
  (let* ((binding_list (second expression))
         (body_expressions (cddr expression))
         (new_bindings
           (evaluateLetBindings binding_list environment))
         (extended_environment
           (append new_bindings environment)))
    (evaluateExpressionList body_expressions
                            extended_environment)))

; This evaluates a lambda expression.
; It returns a closure instead of running the body right away.
(defun evaluateLambdaExpression (expression environment)
  (let ((parameter_names (second expression))
        (body_expressions (cddr expression)))
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

; This is the main evaluator.
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
     (let ((first_part (first expression)))
       (cond
         ((eq first_part 'if)
          (evaluateIfExpression expression environment))

         ((eq first_part 'let)
          (evaluateLetExpression expression environment))

         ((eq first_part 'lambda)
          (evaluateLambdaExpression expression environment))

         ((isPrimitiveOperator first_part)
          (evaluatePrimitiveExpression expression environment))

         (t
          (evaluateApplicationExpression expression
                                         environment)))))

    (t
     (error "TYPE_MISMATCH"))))

; This prints booleans in MiniScheme style.
(defun printMiniSchemeValue (value)
  (cond
    ((eq value 'true)
     (format t "#t~%"))
    ((eq value 'false)
     (format t "#f~%"))
    (t
     (format t "~a~%" value))))

; This reads one file, evaluates it, and prints the answer.
(defun evaluateFile (file_path)
  (let* ((expression_list (readAllExpressions file_path))
         (final_result
           (evaluateExpressionList expression_list nil)))
    (printMiniSchemeValue final_result)))

; This lets the program run from the terminal.
(defun main ()
  (let ((command_line_arguments sb-ext:*posix-argv*))
    (if (> (length command_line_arguments) 1)
        (evaluateFile (car (last command_line_arguments)))
        (format t
                "Usage: sbcl --script functional/evaluator.lisp <file>~%"))))

(main)