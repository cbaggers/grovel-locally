(in-package #:grovel-cache)

(defvar *local-includes*)

(defun push-local-include (path)
  (let* ((abs-path (apply #'asdf-path path))
         (file-name (pathname-name abs-path))
         (ext (pathname-type abs-path))
         (new-file-name (format nil "~a~a~@[.~a~]" (length *local-includes*)
                                file-name ext)))
    (appendf *local-includes* (list (cons abs-path new-file-name)))
    new-file-name))


(eval-when (:compile-toplevel :load-toplevel :execute)
  (pushnew 'include-local cffi-grovel::*header-forms*))

;;; OUT is lexically bound to the output stream within BODY.
(cffi-grovel::define-grovel-syntax include-local (&rest paths)
  (format cffi-grovel::out "~{#include <~A>~%~}"
          (mapcar #'push-local-include paths)))

;;; OUT is lexically bound to the output stream within BODY.
(cffi-grovel::define-wrapper-syntax include-local (&rest paths)
  (format cffi-grovel::out "~{#include <~A>~%~}"
          (mapcar #'push-local-include paths)))

(defun copy-local-includes-to-cache (in-dir)
  (assert (boundp '*local-includes*))
  (assert *local-includes*)
  (let ((local-include-dir
         (uiop:ensure-directory-pathname
          (subpathname (uiop:pathname-directory-pathname in-dir)
                       "local-includes"))))
    (ensure-fresh-dir local-include-dir)
    (loop :for (src-file . local-name) :in *local-includes*
       :for dest-file := (subpathname local-include-dir local-name)
       :do (alexandria:copy-file src-file dest-file))
    (format nil "-I~A" (truename local-include-dir))))
