;;;; package.lisp

(defpackage #:grovel-locally
  (:use #:cl #:cffi-grovel #:uiop #:asdf
        #:with-cached-reader-conditionals))
