(set view (require :lib.view))
(set b64 (require :lib.base64))

(global eval_base64 (fn [base64_str]
  (let [expr_str (b64.decode base64_str)]
    (view ((load expr_str))))))
