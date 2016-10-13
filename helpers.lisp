(in-package #:grovel-locally)

(defun asdf-path (system &rest path)
  (asdf:component-pathname
   (or (asdf:find-component (asdf:find-system system t) path)
       (error "System ~S path not found: ~S" system path))))

(defun ensure-fresh-dir (abs-path)
  (assert (uiop:absolute-pathname-p abs-path))
  (assert (uiop:directory-pathname-p abs-path))
  (when (uiop:directory-exists-p abs-path)
    (uiop:delete-directory-tree abs-path :validate t))
  (ensure-directories-exist abs-path))

;; {TODO} should be able to delete this soon
(defun touch-file (pathname)
  (with-open-file (stream pathname :direction :output
                          :if-exists :append
                          :if-does-not-exist :create)))

(defun feature-specific-cache-dir (cache-dir feature-expressions)
  (let ((feature-expressions (copy-seq feature-expressions)))
    (when cache-dir
      (ensure-directory-pathname
       (subpathname cache-dir (gen-feature-hash feature-expressions))))))

(defun feature-specific-cache-file (file-name cache-dir feature-expressions)
  (let ((fs-cache-dir (feature-specific-cache-dir
                       cache-dir feature-expressions)))
    (when fs-cache-dir
      (subpathname fs-cache-dir (pathname-name file-name)
                   :type (pathname-type file-name)))))

(defun djb2 (string)
  (let ((hash 5381)
        (wrap (- (expt 2 64) 1)))
    (loop :for c :across string :do
       (setf hash (mod (+ (ash hash 5) hash (char-code c))
                       wrap)))
    hash))

(defun processed-os-id ()
  (cl-ppcre:regex-replace-all "[ \\.]" (os-id) "_"))

(defun gen-feature-hash (features)
  (format nil "~a_~a~@[_~x~]"
          (or (processed-os-id) (software-type))
          (or (architecture) (machine-type))
          (when features
            (djb2 (format nil "~{~a~}" features)))))

(defun get-spec-features (input-file)
  (with-cached-reader-conditionals
    (with-open-file (in input-file :direction :input)
      (loop :for form = (read in nil nil) :while form))))
