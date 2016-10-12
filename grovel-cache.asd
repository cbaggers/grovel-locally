;;;; grovel-cache.asd

(asdf:defsystem #:grovel-cache
  :description "Grovel using cffi and cache the result locally to the system"
  :author "Chris Bagley (Baggers) <techsnuffle@gmail.com>"
  :license "BSD 2 Clause"
  :serial t
  :components ((:file "package")
               (:file "asdf")
               (:file "grovel")
               (:file "wrap")))
