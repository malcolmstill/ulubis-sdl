;;;; ulubis-sdl.asd

(asdf:defsystem #:ulubis-sdl
  :description "An SDL2 backend for the Ulubis Wayland compositor"
  :author "Malcolm Still"
  :license "BSD 3-Clause"
  :depends-on (#:cffi
               #:cepl.sdl2
	       #:ulubis)
  :serial t
  :components ((:file "package")
               (:file "ulubis-sdl")))

