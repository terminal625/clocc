;;; Environment & System access
;;;
;;; Copyright (C) 1999 by Sam Steingold
;;; This is open-source software.
;;; GNU Lesser General Public License (LGPL) is applicable:
;;; No warranty; you may copy/modify/redistribute under the same
;;; conditions with the source code.
;;; See <URL:http://www.gnu.org/copyleft/lesser.html>
;;; for details and the precise copyright document.
;;;
;;; $Id: sys.lisp,v 1.4 2000/03/01 20:01:36 sds Exp $
;;; $Source: /cvsroot/clocc/clocc/src/port/sys.lisp,v $
;;; $Log: sys.lisp,v $
;;; Revision 1.4  2000/03/01 20:01:36  sds
;;; (arglist, class-slot-list): new functions
;;;
;;; Revision 1.3  2000/03/01 16:02:03  sds
;;; (variable-special-p): new function
;;;
;;; Revision 1.2  2000/02/18 21:16:45  sds
;;; in-package :port now; make system works
;;;
;;; Revision 1.1  1999/11/24 17:07:09  sds
;;; Cross-implementation Portability System
;;;
;;;

(eval-when (compile load eval)
  (require :ext (translate-logical-pathname "clocc:src;port;ext")))

(in-package :port)

(export
 '(getenv variable-special-p arglist class-slot-list
   probe-directory default-directory chdir sysinfo
   +month-names+ +week-days+ +time-zones+ +whitespace+
   tz->string current-time))

;;;
;;; System
;;;

(defun getenv (var)
  "Return the value of the environment variable."
  #+cmu (cdr (assoc (string var) *environment-list* :test #'equalp
                    :key #'string)) ; xlib::getenv
  #+(or allegro clisp) (system::getenv (string var))
  #+lispworks (lw:environment-variable (string var))
  #+lucid (lcl:environment-variable (string var))
  #+gcl (si:getenv (string var))
  #-(or cmu allegro clisp lispworks lucid gcl)
  (error 'not-implemented :proc (list 'getenv var)))

;;;
;;; Introspection
;;;

(defun variable-special-p (symbol)
  "Return T if the symbol names a global special variable."
  #+allegro (clos::variable-special-p symbol nil)
  #+clisp (system::special-variable-p symbol)
  #+cmu (walker:variable-globally-special-p symbol)
  #+gcl (system:specialp symbol)
  #-(or allegro clisp cmu gcl)
  (error 'not-implemented :proc (list 'variable-special-p symbol)))

(defun arglist (fn)
  "Return the signature of the function."
  #+allegro (ext:arglist fn)
  #+clisp (sys::arglist fn)
  #+cmu (values (let ((st (kernel:%function-arglist fn)))
                  (if (stringp st) (read-from-string st)
                      (eval:interpreted-function-arglist fn))))
  #+gcl (let ((fn (etypecase fn
                    (symbol fn)
                    (function (system:compiled-function-name fn)))))
          (get fn 'si:debug))
  ;; #+lispworks
  #-(or allegro clisp cmu gcl) (error 'not-implemented :proc 'arglist))

(defun class-slot-list (class &optional (all t))
  "Return the list of slots of a CLASS.
CLASS can be a symbol, a class object (as returned by `class-of')
or an instance of a class.
If the second optional argument ALL is non-NIL (default),
all slots are returned, otherwise only the slots with
:allocation type :instance are returned."
  #-(or allegro clisp cmu lispworks)
  (error 'not-implemented :proc 'class-slot-list)
  #+(or allegro clisp cmu lispworks)
  (macrolet ((class-slots* (class)
               `(#+allegro clos:class-slots
                 #+clisp clos::class-slots
                 #+cmu pcl::class-slots
                 #+lispworks hcl::class-slots ,class))
             (slot-name (slot)
               #+allegro `(slot-value ,slot 'clos::name)
               #+clisp `(clos::slotdef-name ,slot)
               #+cmu `(slot-value ,slot 'pcl::name)
               #+lispworks `(hcl::slot-definition-name ,slot))
             (slot-alloc (slot)
               `(#+allegro clos::slotd-allocation
                 #+clisp clos::slotdef-allocation
                 #+cmu pcl::slot-definition-allocation
                 #+lispworks hcl::slot-definition-allocation ,slot)))
    (mapcan (if all (compose list slot-name)
                (lambda (slot)
                  (when (eq (slot-alloc slot) :instance)
                    (list (slot-name slot)))))
            (class-slots*
             (typecase class
               (class class) (symbol (find-class class))
               ((or structure-object standard-object) (class-of class))
               (t (error 'case-error :proc 'class-slot-list
                         :args (list 'class class 'class 'symbol
                                     'structure-object 'standard-object))))))))

;;;
;;; Environment
;;;

(defun probe-directory (filename)
  "Check whether the file name names an existing directory."
  #+allegro (excl::probe-directory filename)
  #+clisp (lisp:probe-directory filename)
  #+cmu (eq :directory (unix:unix-file-kind filename))
  #+lispworks (not (system::probe-file-not-directory-p filename))
  #-(or allegro clisp cmu lispworks)
  ;; From: Bill Schelter <wfs@fireant.ma.utexas.edu>
  ;; Date: Wed, 5 May 1999 11:51:19 -0500
  (let* ((path (pathname fn))
         (dir (pathname-directory path))
         (name (pathname-name path)))
    (when name (setq dir (append dir (list name))))
    (probe-file (make-pathname :directory dir))))

(defun default-directory ()
  "The default directory."
  #+allegro (excl:current-directory)
  #+clisp (lisp:default-directory)
  #+cmucl (ext:default-directory)
  #+lispworks (hcl:get-working-directory)
  #+lucid (working-directory)
  #-(or allegro clisp cmucl lispworks lucid) (truename "."))

(defun chdir (dir)
  #+allegro (ext:chdir dir)
  #+clisp (lisp:cd dir)
  #+cmu (setf (default-directory) dir)
  #+gcl (si:chdir dir)
  #+lispworks (hcl:change-directory dir)
  #+lucid (working-directory dir)
  #-(or allegro clisp cmu gcl lispworks lucid)
  (error 'not-implemented :proc (list 'chdir dir)))

(defsetf default-directory chdir "Change the current directory.")

(defun sysinfo (&optional (out *standard-output*))
  "Print the current environment to a stream."
  (declare (stream out))
  (format out "~&~%~75~~%~75,,,'-:@<<{[ The current environment ]}>~>~%~
Implementation:~20t~a~%~7tversion:~20t~a~%Machine:  type:~20t~a
~7tversion:~20t~a~%~6tinstance:~20t~a~%System:~19t"
          (lisp-implementation-type) (lisp-implementation-version)
          (machine-type) (machine-version) (machine-instance))
  #+win32
  (if (system::registry
       "SOFTWARE\\Microsoft\\Windows\\CurrentVersion" "ProductName")
      (flet ((env (str)
               (system::registry
                "SOFTWARE\\Microsoft\\Windows\\CurrentVersion" str)))
        (format out " ~a (~a - ~a; boot: ~a)~%Registered to: ~a, ~a [~a]"
                (env "ProductName") (env "Version") (env "VersionNumber")
                (env "BootCount") (env "RegisteredOwner")
                (env "RegisteredOrganization") (env "ProductId")))
      (flet ((env (str)
               (system::registry
                "SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion" str)))
        (format out " WinNT ~a (build ~a: ~a) ~a~%Registered to: ~a, ~a [~a]"
                (env "CurrentVersion") (env "CurrentBuildNUmber")
                (env "CSDVersion") (env "CurrentType") (env "RegisteredOwner")
                (env "RegisteredOrganization") (env "ProductId"))))
  #+os/2 (princ " OS/2")
  #+unix (princ " Unix")
  #+dos (princ " DOS")
  #+pc386 (princ " PC386")
  #+amiga (princ " Exec/AmigaDOS")
  (format out "~%Software: type:~20t~a~%~7tversion:~20t~a~%Site:~20t~a (~a)
User home:~20t~a~%Current directory:~20t~a~%Default pathname:~20t~a
Features:~10t~{~<~%~9t ~1,74:; ~a~>~^,~}.
Modules:~10t~{~<~%~9t ~1,74:; ~a~>~^,~}.~%Current package:~30t~a~%"
          (software-type) (software-version) (long-site-name)
          (short-site-name) (user-homedir-pathname) (default-directory)
          *default-pathname-defaults* *features* *modules* *package*)
  #+clisp (format out "[CLISP] Current language:~30t~a~%"
                  (system::current-language))
  (flet ((exdi (fl) (integer-length (nth-value 1 (decode-float fl)))))
    (format out "Fixnum length:~25t~3d bits
Short Floats:~25t~3d bits exponent, ~3d bits significand (mantissa)
Single Floats:~25t~3d bits exponent, ~3d bits significand (mantissa)
Double Floats:~25t~3d bits exponent, ~3d bits significand (mantissa)
Long Floats:~25t~3d bits exponent, ~3d bits significand (mantissa)~%"
            (integer-length most-positive-fixnum)
            (exdi most-positive-short-float)
            (float-digits most-positive-short-float)
            (exdi most-positive-single-float)
            (float-digits most-positive-single-float)
            (exdi most-positive-double-float)
            (float-digits most-positive-double-float)
            (exdi most-positive-long-float)
            (float-digits most-positive-long-float)))
  #+clisp (format out "[CLISP] long-float-digits:~44t~3d~%"
                  (lisp:long-float-digits))
  (dolist (sy '(array-total-size-limit array-rank-limit array-dimension-limit
                lambda-parameters-limit call-arguments-limit
                multiple-values-limit char-code-limit))
    (format out " ~a:~30t~15:d~%" sy (symbol-value sy)))
  (format out "lambda-list-keywords:~30t~{~<~%~30t~1,74:; ~a~>~}~%"
          lambda-list-keywords)
  (format out "Internal time unit:~25t~f sec~%*gensym-counter*:~25t~:d
Current time:~25t" (/ internal-time-units-per-second) *gensym-counter*)
  (current-time out) (format out "~%~75~~%") (room) (values))

(defconst +month-names+ (simple-array simple-string (12))
  (mk-arr 'simple-string '("Jan" "Feb" "Mar" "Apr" "May" "Jun" "Jul" "Aug"
                           "Sep" "Oct" "Nov" "Dec"))
  "*The names of the months.")

(defconst +week-days+ (simple-array simple-string (7))
  (mk-arr 'simple-string '("Mon" "Tue" "Wed" "Thu" "Fri" "Sat" "Sun"))
  "*The names of the days of the week.")

(defconst +time-zones+ list
  '((5 "EDT" . "EST") (6 "CDT" . "CST") (7 "MDT" . "MST") (8 "PDT" . "PST")
    (0 "GMT" . "GDT") (-2 "MET" . "MET DST"))
  "*The string representations of the time zones.")

(defconst +whitespace+ (simple-array character (*))
  (mk-arr 'character '(#\Space #\Newline #\Tab #\Linefeed #\Return #\Page))
  "*The whitespace characters.")

(defun tz->string (tz)
  "Convert the CL timezone (rational [-24;24], multiple of 3600) to a string."
  (declare (type rational tz))
  (multiple-value-bind (hr mm) (floor (abs tz))
    (let ((mi (floor (* 60 mm))))
      (format nil "~:[+~;-~]~2,'0d~2,'0d" (minusp tz) hr mi))))

(defun current-time (&optional (out t))
  "Print the current time to the stream (defaults to t)."
  (multiple-value-bind (se mi ho da mo ye dw dst tz) (get-decoded-time)
    (declare (fixnum se mi ho da mo ye dw tz))
    (format out "~4d-~2,'0d-~2,'0d ~a ~2,'0d:~2,'0d:~2,'0d ~a (~a)"
            ye mo da (aref +week-days+ dw) ho mi se
            (tz->string (- (if dst 1 0) tz))
            (funcall (if dst #'cadr #'cddr) (assoc tz +time-zones+)))))

;;; file sys.lisp ends here
