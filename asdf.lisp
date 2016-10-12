(in-package #:grovel-cache)

;;------------------------------------------------------------£

(defclass caching-grovel-file (grovel-file)
  ((cache-dir :initform nil :initarg :cache-dir :accessor cache-dir-of)))

(defclass caching-wrapper-file (wrapper-file)
  ((cache-dir :initform nil :initarg :cache-dir :accessor cache-dir-of)))

;;------------------------------------------------------------

(defvar *foooo* 1)

(defmethod perform ((op cffi-grovel::process-op) (c caching-grovel-file))
  (destructuring-bind (output-file c-file exe-file) (output-files op c)
    (break "WHAT-HO CRACKERJACK
~s
~s
~s" output-file c-file exe-file)
    (let* ((input-file (first (input-files op c)))
           (absolute-cache-dir
            (absolute-cache-dir input-file (cache-dir-of c))))
      (process-grovel-file*
       input-file output-file c-file exe-file absolute-cache-dir))))

(defmethod perform ((op cffi-grovel::process-op) (c caching-wrapper-file))
  (destructuring-bind (output-file lib-name c-file o-file) (output-files op c)
    (let* ((input-file (first (input-files op c))))
      (process-wrapper-file* (component-system c)
                             input-file
                             output-file
                             lib-name
                             c-file
                             o-file
                             :lib-soname (cffi-grovel::wrapper-soname c)
                             :cache-dir (sys-relative-cache-dir c)))))

;;------------------------------------------------------------

(defmethod output-files ((op cffi-grovel::process-op) (c caching-grovel-file))
  (let* ((input-file (first (input-files op c)))
         (input-name (pathname-name input-file))
         (features (get-spec-features input-file))
         (cache-dir (sys-relative-cache-dir c))
         (output-file (feature-specific-cache-file
                       (make-pathname
                        :name input-name
                        :type (cffi-grovel::generated-lisp-file-type c))
                       cache-dir features))
         (c-file (feature-specific-cache-file
                  (cffi-grovel::make-c-file-name input-name "__grovel")
                  cache-dir features))
         (exe-file (cffi-grovel::make-exe-file-name c-file)))
    ;; Return but don't transform to .cache dir
    (values (list output-file c-file exe-file)
            t)))

(defmethod output-files ((op cffi-grovel::process-op) (c caching-wrapper-file))
  (let* ((input-file (first (input-files op c)))
         (input-name (pathname-name input-file))
         (features (get-spec-features input-file))
         (cache-dir (sys-relative-cache-dir c))
         (output-file (feature-specific-cache-file
                       (make-pathname
                        :name input-name
                        :type (cffi-grovel::generated-lisp-file-type c))
                       cache-dir features))
         (c-file (feature-specific-cache-file
                  (cffi-grovel::make-c-file-name input-name "__wrapper")
                  cache-dir features))
         (o-file (feature-specific-cache-file
                  (cffi-grovel::make-o-file-name input-name "__wrapper")
                  cache-dir features))
         (lib-soname (cffi-grovel::wrapper-soname c))
         (lib-file (feature-specific-cache-file
                    (cffi-grovel::make-lib-file-name
                     (cffi-grovel::make-soname lib-soname output-file))
                    cache-dir features)))
    ;; Return but don't transform to .cache dir
    (values (list output-file lib-file c-file o-file)
            t)))

;;------------------------------------------------------------

(defun absolute-cache-dir (input-file cache-dir)
  (when cache-dir
    (let ((input-dir (pathname-directory-pathname input-file)))
      (ensure-directory-pathname
       (subpathname input-dir cache-dir)))))

(defun system-to-component-path (component)
  (let* ((sys (component-system component))
         (sys-dir (pathname-directory (component-pathname sys)))
         (comp-dir (pathname-directory (component-pathname component))))
    (make-pathname* :directory (cons :relative (subseq comp-dir (length sys-dir))))))

(defun sys-relative-cache-dir (c)
  (let ((cache-dir (cache-dir-of c)))
    (when cache-dir
      (ensure-directory-pathname
       (subpathname* (system-to-component-path c) cache-dir)))))


;;======================================================================
;; Allow for naked :grovel-file and :wrapper-file in asdf definitions.

(setf (find-class 'asdf::caching-grovel-file)
      (find-class 'caching-grovel-file))

(setf (find-class 'asdf::caching-wrapper-file)
      (find-class 'caching-wrapper-file))

;;======================================================================
