(in-package :grovel-locally)

;;------------------------------------------------------------

(let (cached)
  (defun os-id ()
    (or cached
        (setf cached (or #+windows (win-os-id)
                         #+unix (posix-os-id)
                         #+linux (posix-os-id)
                         (string (uiop:operating-system)))))))

;;------------------------------------------------------------

(defun posix-os-id ()
  (labels ((clean (x) (string-trim '(#\newline #\space) x)))
    (clean
     (with-output-to-string (s)
       (uiop:run-program '("uname" "-sr") :output s)))))

;;------------------------------------------------------------

(defun win-os-val-to-name (val)
  ;; http://stackoverflow.com/questions/13212033/get-windows-version-in-a-batch-file
  ;; [*] For applications that have been manifested for win-8.1 or
  ;;     win-10. Applications not manifested for win-8.1 or win-10 will
  ;;     return the win-8 OS version value (6.2). To manifest your
  ;;     applications for win-8.1 or win-10, refer to Targeting your
  ;;     application for Windows.
  ;;
  (let ((val (format nil "~a" val)))
    (cdr
     (assoc val '(("10.0" . :win-10) ;;            [*]
                  ("10.0" . :win-server-2016) ;;   [*]
                  ("6.3" . :win-8.1) ;;            [*]
                  ("6.3" . :win-server-2012-r2) ;; [*]
                  ("6.2" . :win-8)
                  ("6.2" . :win-server-2012)
                  ("6.1" . :win-7)
                  ("6.1" . :win-server-2008-r2)
                  ("6.0" . :win-server-2008)
                  ("6.0" . :win-vista)
                  ("5.2" . :win-server-2003-r2)
                  ("5.2" . :win-server-2003)
                  ("5.2" . :win-xp-64)
                  ("5.1" . :win-xp)
                  ("5.0" . :win-2000))
            :test #'equal))))

(defun win-os-id ()
  (labels ((extract (x)
             (first (cl-ppcre:all-matches-as-strings "\\d\\d\\.\\d" x))))
    (win-os-val-to-name
     (extract
      (with-output-to-string (s)
        (uiop:run-program "ver" :output s))))))

;;------------------------------------------------------------
