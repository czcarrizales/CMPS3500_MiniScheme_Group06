;;; Tiny file-loading helper stub for the functional implementation.
(defun read-file-as-string (path)
  (with-open-file (in path :direction :input)
    (let ((contents (make-string (file-length in))))
      (read-sequence contents in)
      contents)))
