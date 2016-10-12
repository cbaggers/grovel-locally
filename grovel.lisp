(in-package #:grovel-cache)



(defun generate-c-file* (c-file forms)
  (with-standard-io-syntax
    (let ((*print-readably* nil)
          (*print-escape* t))
      (with-open-file (out c-file :direction :output :if-exists :supersede)
        (let* ((header-forms (remove-if-not #'cffi-grovel::header-form-p forms))
               (body-forms (remove-if #'cffi-grovel::header-form-p forms)))
          (cffi-grovel::write-string cffi-grovel::*header* out)
          (dolist (form header-forms)
            (cffi-grovel::process-grovel-form out form))
          (cffi-grovel::write-string cffi-grovel::*prologue* out)
          (dolist (form body-forms)
            (cffi-grovel::process-grovel-form out form))
          (cffi-grovel::write-string cffi-grovel::*postscript* out)
          c-file)))))

;; {TODO} modify with-cached-reader-conditionals to allow telling the system
;;        to use #'dirty-featurep
(defun read-grovel-file* (input-file)
  (flet ((read-forms (s)
           (do ((forms ()) (form (read s nil nil) (read s nil nil)))
               ((null form) (nreverse forms))
             (labels
                 ((process-form (f)
                    (case (cffi-grovel::form-kind f)
                      (flag (warn "Groveler clause FLAG is deprecated, use CC-FLAGS instead.")))
                    (case (cffi-grovel::form-kind f)
                      (in-package
                       (setf *package* (find-package (second f)))
                       (push f forms))
                      (progn
                        ;; flatten progn forms
                        (mapc #'process-form (rest f)))
                      (t (push f forms)))))
               (process-form form)))))
    (with-open-file (in input-file :direction :input)
      (with-cached-reader-conditionals (read-forms in)))))


 ;;; *PACKAGE* is rebound so that the IN-PACKAGE form can set it during
 ;;; *the extent of a given grovel file.
(defun process-grovel-file* (input-file dest-lisp-file c-file exe-file absolute-cache-dir)
  (with-standard-io-syntax
    (multiple-value-bind (forms feature-expressions)
        (read-grovel-file* input-file)
      (let* ((cached-lisp-file (feature-specific-cache-file
                                dest-lisp-file absolute-cache-dir
                                feature-expressions))
             (*local-includes* nil))
        (if (and cached-lisp-file (file-exists-p cached-lisp-file))
            (process-grovel-file-from-cache dest-lisp-file c-file
                                            cached-lisp-file)
            (process-grovel-file-from-scratch forms dest-lisp-file c-file
                                              exe-file cached-lisp-file))
        dest-lisp-file))))

(defun process-grovel-file-from-cache (dest-lisp-file c-file cached-lisp-file)
  (touch-file c-file)
  (alexandria:copy-file cached-lisp-file dest-lisp-file
                        :if-to-exists :supersede))

(defun process-grovel-file-from-scratch (forms dest-lisp-file c-file exe-file
                                         cached-lisp-file)
  (generate-c-file* c-file forms)
  (let* ((lisp-file (cffi-grovel::tmp-lisp-file-name c-file))
         (inputs (list (cffi-grovel::cc-include-grovel-argument)
                       c-file)))
    ;;
    (when *local-includes*
      (push (copy-local-includes-to-cache c-file) inputs))
    ;;
    (handler-case (cffi-grovel::link-executable exe-file inputs)
      (error (e) (grovel-error "~a" e)))
    (cffi-grovel::invoke exe-file lisp-file)
    (rename-file-overwriting-target lisp-file dest-lisp-file)
    (when cached-lisp-file
      (ensure-directories-exist
       (pathname-directory-pathname cached-lisp-file))
      (alexandria:copy-file dest-lisp-file cached-lisp-file
                            :if-to-exists :supersede))))

;;------------------------------------------------------------
