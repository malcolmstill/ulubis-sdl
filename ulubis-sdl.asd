;;;; ulubis-sdl.asd

(asdf:defsystem #:ulubis-sdl
  :description "Describe ulubis-sdl here"
  :author "Malcolm Still"
  :license "Specify license here"
  :depends-on (#:cffi
               #:cepl.sdl2)
  :serial t
  :components (;;(:file "package")
               (:file "ulubis-sdl")))

