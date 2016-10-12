;;;; grovel-locally.asd

(asdf:defsystem #:grovel-locally
  :description "Grovel using cffi and cache the result locally to the system"
  :author "Chris Bagley (Baggers) <techsnuffle@gmail.com>"
  :license "BSD 2 Clause"
  :depends-on (:cffi :cffi-grovel :with-cached-reader-conditionals :alexandria)
  :serial t
  :components ((:file "package")
               (:file "helpers")
               (:file "local-include")
               (:file "grovel")
               (:file "wrap")
               (:file "asdf")))
