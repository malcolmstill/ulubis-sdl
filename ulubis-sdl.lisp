
(in-package :ulubis-sdl)

(setf ulubis-backend:backend-name (intern "backend-sdl" :ulubis-backend))

(defclass ulubis-backend:backend () ;; backend ()
  ((window :accessor window :initarg :window :initform nil)
   (counter :accessor counter :initarg :counter :initform 0)
   (mouse-button-handler :accessor mouse-button-handler :initarg :mouse-button-handler
                         :initform (lambda (button state x y) (declare (ignore button state x y))))
   (mouse-motion-handler :accessor mouse-motion-handler :initarg :mouse-motion-handler
                         :initform (lambda (x y xrel yrel state) (declare (ignore x y xrel yrel state))))
   (keyboard-handler :accessor keyboard-handler :initarg :keyboard-handler
                     :initform (lambda (key state) (declare (ignore key state))))
   (window-event-handler :accessor window-event-handler :initarg :window-event-handler :initform (lambda ()))
   ;; xkb
   (xkb-context :accessor xkb-context :initarg :xkb-context :initform nil)
   (keymap :accessor keymap :initarg :keymap :initform nil)
   (state :accessor state :initarg :state :initform nil)
   (modifier-state :accessor modifier-state :initarg :modifier-state :initform nil)
   (keysym-to-keycode :accessor keysym-to-keycode :initarg :keysym-to-keycode :initform nil)))

(defun make-keysym-to-keycode-table (keymap state)
  (let ((table (make-hash-table)))
    (loop :for i :from (xkb:xkb-keymap-min-keycode keymap) :to (xkb:xkb-keymap-max-keycode keymap)
       :do (let ((keysym (xkb:xkb-state-key-get-one-sym state i)))
	     (format t "Kesym: ~A, keycode: ~A, name: ~A~%" keysym i (xkb:get-keysym-name keysym))
	     (setf (gethash keysym table) i)))
    table))

(defun sdl-to-linux-scancode (scancode)
  (case scancode
    (4 (+ 30 8)) ;; SDL_SCANCODE_A
    (5 (+ 48 8))
    (6 (+ 46 8))
    (7 (+ 32 8))
    (8 (+ 18 8))
    (9 (+ 33 8))
    (10 (+ 34 8))
    (11 (+ 35 8))
    (12 (+ 23 8))
    (13 (+ 36 8))
    (14 (+ 37 8))
    (15 (+ 38 8))
    (16 (+ 50 8)) ;; M
    (17 (+ 49 8)) ;; N
    (18 (+ 24 8))
    (19 (+ 25 8))
    (20 (+ 16 8))
    (21 (+ 19 8))
    (22 (+ 31 8))
    (23 (+ 20 8))
    (24 (+ 22 8))
    (25 (+ 47 8))
    (26 (+ 17 8))
    (27 (+ 45 8))
    (28 (+ 21 8))
    (29 (+ 44 8))
    (30 (+ 2 8)) ;; 1
    (31 (+ 3 8))
    (32 (+ 4 8))
    (33 (+ 5 8))
    (34 (+ 6 8))
    (35 (+ 7 8))
    (36 (+ 8 8))
    (37 (+ 9 8))
    (38 (+ 10 8))
    (39 (+ 11 8)) ;; 0
    (40 (+ 28 8)) ;; Return
    (41 (+ 1 8)) ;; Esc
    (42 (+ 14 8))
    (43 (+ 15 8)) ;; Tab
    (44 (+ 57 8))
    (45 (+ 12 8))
    (46 (+ 13 8))
    (47 (+ 26 8))
    (48 (+ 27 8))
    (49 (+ 43 8)) ;; \
    ;; (50 NONUSHASH
    (51 (+ 39 8))
    (52 (+ 40 8))
    (53 (+ 41 8))
    (54 (+ 51 8))
    (55 (+ 52 8))
    (56 (+ 53 8))
    ;; (57 CAPSLOCK
    (79 (+ 106 8))
    (80 (+ 105 8))
    (81 (+ 108 8))
    (82 (+ 103 8))
    (224 (+ 29 8))
    (225 (+ 42 8))
    (226 (+ 56 8))
    (227 (+ 125 8))
    (228 (+ 97 8))
    (229 (+ 54 8))
    (230 (+ 100))
    (otherwise 8)))

(defmethod ulubis-backend:initialise-backend ((backend backend) width height devices)
  (cepl:repl width height 3.3)
  (sdl2:set-relative-mouse-mode 1)
  (gl:viewport 0 0 width height)
  (gl:disable :cull-face)
  (gl:disable :depth-test))

(defmacro with-event-handlers (&body event-handlers)
  ;; Using poll here
  (let ((quit (gensym "QUIT-"))
        (sdl-event (gensym "SDL-EVENT-"))
        (sdl-event-type (gensym "SDL-EVENT-TYPE"))
	(sdl-event-id (gensym "SDL-EVENT-ID"))
	(rc (gensym "RC-")))
    `(sdl2:with-sdl-event (,sdl-event)
       (loop :as ,rc = (sdl2:next-event ,sdl-event)
	  :until (= 0 ,rc)
	  :do
	  (let* ((,sdl-event-type (sdl2:get-event-type ,sdl-event))
		 (,sdl-event-id (and (sdl2::user-event-type-p ,sdl-event-type)
				     (,sdl-event :user :code))))
	    (case ,sdl-event-type
	      (:lisp-message () (sdl2::get-and-handle-messages))
	      ,@(loop :for (type params . forms) :in event-handlers
		   :collect
		   (if (eq type :quit)
		       (sdl2::expand-quit-handler sdl-event forms quit)
		       (sdl2::expand-handler sdl-event type params forms))
		   :into results
		   :finally (return (remove nil results))))
	    (when (and ,sdl-event-id (not (eq ,sdl-event-type :lisp-message)))
	      (sdl2::free-user-data ,sdl-event-id)))))))

(defun sdl-to-evdev (button)
  (cond
    ((= button 1) #x110)
    ((= button 3) #x111)
    (t 0)))

(defmethod ulubis-backend:process-events ((backend backend))
  (with-event-handlers
    (:mousemotion (:x x :y y :xrel dx :yrel dy)
                  (declare (ignore x y))
		  (funcall (mouse-motion-handler backend) (get-internal-real-time) dx dy))
    (:mousebuttondown (:button button :state state :x x :y y)
                      (declare (ignore x y))
		      (funcall (mouse-button-handler backend) (get-internal-real-time) (sdl-to-evdev button) state))
    (:mousebuttonup (:button button :state state :x x :y y)
                    (declare (ignore x y))
		    (funcall (mouse-button-handler backend) (get-internal-real-time) (sdl-to-evdev button) state))
    (:keydown (:keysym keysym)
	      (let ((scancode (sdl-to-linux-scancode (sdl2:scancode-value keysym))))
		(format t "Key down: ~A~%" scancode)
		(if (>= scancode 8)
		    (funcall (keyboard-handler backend)
			     (get-internal-real-time)
			     (- scancode 8)
			     1))))
    (:keyup (:keysym keysym)
	      (let ((scancode (sdl-to-linux-scancode (sdl2:scancode-value keysym))))
		(if (>= scancode 8)
		    (funcall (keyboard-handler backend)
			     (get-internal-real-time)
			     (- scancode 8)
			     0))))
    (:windowevent (:type type :data1 data1 :data2 data2)
                  (declare (ignore type data1 data2))
		  (funcall (window-event-handler backend)))))

;; Bother with these methods or just setf?
(defmethod ulubis-backend:register-keyboard-handler ((backend backend) keyboard-handler)
  (setf (keyboard-handler backend) keyboard-handler))

(defmethod ulubis-backend:register-mouse-motion-handler ((backend backend) mouse-motion-handler)
  (setf (mouse-motion-handler backend) mouse-motion-handler))

(defmethod ulubis-backend:register-mouse-button-handler ((backend backend) mouse-button-handler)
  (setf (mouse-button-handler backend) mouse-button-handler))

(defmethod ulubis-backend:register-window-event-handler ((backend backend) window-event-handler)
  (setf (window-event-handler backend) window-event-handler))

(defmethod ulubis-backend:swap-buffers ((backend backend))
  (cepl:swap))

(defmethod ulubis-backend:destroy-backend ((backend backend))
  (cepl:quit))
