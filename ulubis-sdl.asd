;;;; ulubis-sdl.asd

(asdf:defsystem #:ulubis-sdl
  :description "An SDL2 backend for the Ulubis Wayland compositor"
  :author "Malcolm Still"
  :license "BSD3"
  :depends-on (#:cffi
               #:cepl.sdl2)
  :serial t
  :components (;;(:file "package")
               (:file "ulubis-sdl")))

