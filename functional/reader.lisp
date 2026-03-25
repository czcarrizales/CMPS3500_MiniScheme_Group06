(defun readAllExpressions (file_path)
  (with-open-file (in file_path)
    (loop for expr = (read in nil 'eof)
          until (eq expr 'eof)
          collect expr)))

(defun parseFile (file_path)
  (let ((exprs (readAllExpressions file_path)))
    (if (null exprs)
        (format t "PARSE_ERROR~%")
        (progn
          (format t "Parsed Expressions: ~a~%" exprs)
          exprs))))

(parseFile "tests/public/sample_case.scm")
(parseFile "tests/public/core_01.scm")
(parseFile "tests/public/core_02.scm")
(parseFile "tests/public/let_01.scm")
(parseFile "tests/public/lambda_01.scm")