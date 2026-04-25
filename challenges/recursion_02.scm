(define sumdown
  (lambda (n)
    (if (= n 0)
        0
        (+ n (sumdown (- n 1))))))
(sumdown 4)
