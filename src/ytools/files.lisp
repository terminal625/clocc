;-*- Mode: Common-lisp; Package: ytools; Readtable: ytools; -*-
(in-package :ytools)
;;;$Id: files.lisp,v 1.14.2.35 2005/03/18 15:19:32 airfoyle Exp $
	     
;;; Copyright (C) 1976-2004
;;;     Drew McDermott and Yale University.  All rights reserved
;;; This software is released under the terms of the Modified BSD
;;; License.  See file COPYING for details.

(eval-when (:load-toplevel)
   (export '(fload-versions postponed-files-update
	     always-slurp
	     debuggable debuggability* def-sub-file-type)))

;;; The name of a File-chunk is always its yt-pathname if non-nil,
;;; else its pathname.
;;; This represents a primitive file, not one whose contents are
;;; managed by the file/chunk system itself (e.g., an object file
;;; whose compilation is handled by a Compiled-file-chunk).
(defclass File-chunk (Chunk)
  ((pathname :reader File-chunk-pathname
	     :initarg :pathname
	     :type pathname)
   (yt-pathname :reader File-chunk-yt-pathname
		:initarg :yt-pathname
		:initform false)
   ;;  -- Either false or a YTools pathname, in which case
   ;; 'pathname' is its resolution
   (kind :reader File-chunk-kind
	 :initarg :kind)
   ;; -- :source, :object, :data (":data" can include files of
   ;; of source code that won't be compiled).
   (readtable :accessor File-chunk-readtable
	      :initarg :readtable
	      :initform false)
   (alt-version :accessor File-chunk-alt-version
		:initarg :alt-version
		:initform false)
   ;; - If not nil, the File-chunk for the alternative version.
   ;; Perhaps the next two should be associated with this file's
   ;; Loaded-chunk, because they don't make sense for a data file.--
   ;; Files that must be loaded when this one is --
   (callees :accessor File-chunk-callees
	    :initform !())
   ;; Inverse of 'callees' --
   (callers :accessor File-chunk-callers
	    :initform !())
   ;; Files that must be loaded when this one is read
   ;;  (not currently used) --
   (read-basis :accessor File-chunk-read-basis
	       :initform false))
)
;; -- Files are the finest grain we allow.  If a file is out of date,
;; then every chunk associated with the file is assumed to be out of
;; date.  More than one chunk can be associated with a file.  For now,
;; don't allow a chunk to be associated with more than one file.

;; These two methods ensure that 'callers' is the inverse of 'callees' --
(defmethod (setf File-chunk-callees) :before (_ file-ch)
   (dolist (clee (File-chunk-callees file-ch))
      (setf (File-chunk-callers clee)
	    (remove file-ch (File-chunk-callers clee)))))

(defmethod (setf File-chunk-callees) :after (_ file-ch)
   (dolist (clee (File-chunk-callees file-ch))
      (setf (File-chunk-callers clee)
	    (adjoin file-ch (File-chunk-callers clee)))))

(defmethod derive-date ((fc File-chunk))
   (let ((v (File-chunk-alt-version fc)))
      (cond (v (derive-date v))
	    (t
	     (let ((pn (File-chunk-pathname fc)))
	        (cond ((probe-file pn)
		       (file-write-date pn))
		      (t
		       (error "File-chunk corresponds to nonexistent file: ~s"
			      fc))))))))

(defmethod derive ((fc File-chunk))
   false)

(defun File-chunk-pn (file-ch)
   (or (File-chunk-yt-pathname file-ch)
       (File-chunk-pathname file-ch)))

(defun file-chunk-is-source (file-ch)
   (eq (File-chunk-kind file-ch) ':source))

(defun file-chunk-is-object (file-ch)
   (eq (File-chunk-kind file-ch) ':object))

;;; 'pn' could be a Pseudo-pathname (see module.lisp)
(defgeneric pathname-denotation-chunk (pn))

(defmethod pathname-denotation-chunk ((ytpn YTools-pathname))
   (pathname-denotation-chunk (pathname-resolve ytpn false)))

(defmethod pathname-denotation-chunk ((pn pathname))
   (cond ((null (Pathname-type pn))
	  (let ((source-pn (pathname-source-version pn)))
	  (cond ((not source-pn)
		 (error "No source file corresponding to ~s"
			pn)))
	  (setq pn source-pn))))
   (place-File-chunk pn))

(defun place-File-chunk (pn &key kind)
   (multiple-value-bind (yt-pathname l-pathname)
			(cond ((is-YTools-pathname pn)
			       (values pn (pathname-resolve pn true)))
			      (t
			       (values false (pathname pn))))
      (cond ((not kind)
	     (setq kind
	       (cond ((pathname-is-source l-pathname)
		      ':source)
		     ((pathname-is-object l-pathname)
		      ':object)
		     (t
		      ':data)))))
      (chunk-with-name
	 `(:file ,(or yt-pathname l-pathname))
	 (\\ (e)
	    (make-instance 'File-chunk
	       :name e
	       :kind kind
	       :yt-pathname yt-pathname
	       :pathname l-pathname
	       :alt-version false)))))

;;; Represents a source file having an up-to-date compiled version.
;;; Actually, an attempt to compile is good enough, because we wouldn't
;;; want to try to recompile before a basis chunk changes.
(defclass Compiled-file-chunk (File-chunk)
  ((source-file :initarg :source-file
		:reader Compiled-file-chunk-source-file
		:type File-chunk)
   (object-file :initarg :object-file
		 :accessor Compiled-file-chunk-object-file
		 :type File-chunk)
   (last-compile-time :accessor Compiled-file-chunk-last-compile-time
		      :initform -1)))

;;; There are two sorts of strings attached to loadable files: what files
;;; they depend on in order to be compiled and loaded; and what version of
;;; is to be loaded (source, object, or some other file entirely).  The 
;;; latter is controlled directly by user requests, using 'fload' and 'fcompl',
;;; or some other facility (simple 'load', for instance).  The former is
;;; knottier.  YTFM wants to figure out dependencies by slurping, but 
;;; 'fload'/'fcompl' should be able to decipher dependencies declared by
;;; some version of 'defsystem.'  That's where Loadable-chunks come in (qv).

;;; An entity as (having the appropriate variant) loaded into primary
;;; memory --
(defclass Loaded-chunk (Chunk)
   (;; The entity this one governs --
    (loadee :accessor Loaded-chunk-loadee
	    :initarg :loadee)
    ;; The final basis is these plus those obtained by scanning
    ;; dependencies from whatever places are appropriate --
    (principal-bases :accessor Loaded-chunk-principal-bases
		     :initform !())
    ;; The Loadable-chunk that computes the basis of this one --
    (controller :accessor Loaded-chunk-controller
		:initarg :controller)))

(defgeneric place-Loaded-chunk (ch variant)
   (:method ((ch t) variant)
	    (declare (ignore variant))
      (error "No way to make a Loaded-chunk for ~s" ch)))

(defclass Loaded-file-chunk (Loaded-chunk)
   (;; The variant currently selected, either a File-chunk, or
    ;; a Loaded-file-chunk if we're indirecting through an alt-version --
    (selection :accessor Loaded-file-chunk-selection
	  :initform false)
    ;; The criterion (supplied by user) for how to make the selection --
    (manip :accessor Loaded-file-chunk-manip
	   :initarg :manip
	   :type (member :compile :source :object
			 :ask-once :ask-every :ask-ask :defer))
    ;; -- Meanings:
    ;;   :source -> don't compile, load source;
    ;;   :object -> compile only if no object; load object
    ;;   :compile -> compile and then load object;
    ;;   :ask-once -> ask user which to do and record result;
    ;;   :ask-every -> ask user every time basis is recomputed;
    ;;   :ask-ask -> ask once and ask if it should keep asking;
    ;;   :defer -> refer to value of fload-compile*;
    ;;   :follow -> replace 'manip' value with value of fload-compile*

    (source :reader Loaded-file-chunk-source
	    :initarg :source)
    (compiled :reader Loaded-file-chunk-compiled
	      :initarg :compiled)
    (object :reader Loaded-file-chunk-object
	    :initarg :object)))

(defmethod initialize-instance :after ((lc Loaded-chunk )
				       &key &allow-other-keys)
   (setf (Chunk-basis lc)
         (list (Loaded-chunk-loadee lc))))

(defun loaded-chunk-augment-basis (loaded-ch added-bases)
  (let ((non-prin-bases (loaded-chunk-verify-basis loaded-ch)))
     ;; Avoid calling the Chunk-basis setter if possible
     ;; so as not to trigger chunks-update that might interrupt
     ;; another already in progress.--
     (cond ((some (\\ (ab)
		     (not (member ab non-prin-bases)))
		  added-bases)
	    (setf (Chunk-basis loaded-ch)
		  (append (Loaded-chunk-principal-bases loaded-ch)
			  (union non-prin-bases
				 added-bases)))))))

;;; The first elements of the basis are always the principal-bases.
;;; Use this to change the rest --
(defun loaded-chunk-change-basis (loaded-ch revised-basis)
  (let ((non-prin-bases (loaded-chunk-verify-basis loaded-ch)))
     (cond ((some (\\ (rb)
		     (not (member rb non-prin-bases)))
		  revised-basis)
	    (setf (Chunk-basis loaded-ch)
		  (append (Loaded-chunk-principal-bases loaded-ch)
			  revised-basis))))))

;;; Returns excess basis elements beyond the principal ones --
(defun loaded-chunk-verify-basis (loaded-ch)
   (let ((loaded-basis (Chunk-basis loaded-ch)))
      (do ((pl (Loaded-chunk-principal-bases loaded-ch)
	       (cdr pl))
	   (bl loaded-basis (cdr bl)))
	  ((or (null pl)
	       (null bl)
	       (not (eq (car bl) (car pl))))
	   (cond ((null pl) bl)
		 (t
		  (error !"Chunk for loaded entity ~s~%~
                           has bogus basis ~s~%~
                           which differs from principal basis ~s"
			 loaded-ch loaded-basis
			 (Loaded-chunk-principal-bases loaded-ch))))))))

;;; This is a "meta-chunk," which keeps the network of Loaded-chunks 
;;; up to date.
;;; Corresponds to information gleaned from file header (or elsewhere)
;;; about what
;;; other files (and modules, ...) are necessary in order to load or
;;; compile and load, the given file.  This information forms the basis
;;; of the corresponding Loaded-chunk.
;;; This is a rudimentary chunk, which has no basis or derivees.  The only
;;; reason to use the chunk apparatus is to keep track of the date, which
;;; uses the file-op-count* instead of actual time.
(defclass Loadable-chunk (Chunk)
   ((controllee :reader Loadable-chunk-controllee
	  :initarg :controllee
	  :type Loaded-chunk))
   (:default-initargs :basis !()))
;;; -- The basis of this chunk is the empty list because it's a
;;; meta-chunk, which can't be connected to any chunk whose basis it
;;; might affect.

;;; Creates a Loadable-chunk to act as a controller for this filoid
;;; and the chunk corresponding to its being loaded.
;;; In depend.lisp we'll supply the standard controller for ordinary files
;;; following YTools rules.  
(defgeneric create-loaded-controller (filoid loaded)
  (:method ((x t) y)
     (declare (ignore y))
     (error "No way supplied to create controllers for objects of type ~s~%"
	    (type-of x))))

(defvar all-loaded-file-chunks* !())

(defmethod derive ((lc Loadable-chunk))
   (error "No method supplied for figuring out what entities ~s depends on"
	  (Loadable-chunk-controllee lc)))
;;; -- We must subclass Loadable-chunk to supply methods for figuring
;;; out file dependencies.  See depend.lisp for the YTFM approach.


(defmethod place-Loaded-chunk ((file-ch File-chunk) manip)
   (place-Loaded-file-chunk file-ch manip))

(defun place-Loaded-file-chunk (file-chunk file-manip)
   (let ((lc (chunk-with-name `(:loaded ,(File-chunk-pathname file-chunk))
		(\\ (name)
		  (let ((is-source (file-chunk-is-source file-chunk))
			(is-object (file-chunk-is-object file-chunk)))
		     (let ((compiled-chunk
			      (and is-source
				   (place-compiled-chunk file-chunk))))
			(let ((new-lc
				 (make-instance 'Loaded-file-chunk 
				    :name name
				    :loadee file-chunk
				    :manip (or file-manip ':follow)
				    :source (cond (is-object false)
						  (t file-chunk))
				    :compiled (cond (is-source compiled-chunk)
						    (is-object file-chunk)
						    (t false))
				    :object (cond (is-source
						   (place-File-chunk
						      (File-chunk-pathname
							 compiled-chunk)))
						  (is-object file-chunk)
						  (t false)))))
;;;;			   (setq cc* compiled-chunk)
;;;;			   (loaded-file-chunk-set-basis new-lc)
			   (push new-lc all-loaded-file-chunks*)
			   new-lc))))
		:initializer
		   (\\ (new-lc)
		      (cond ((not (slot-truly-filled new-lc 'controller))
			     (setf (Loaded-chunk-controller new-lc)
				   (create-loaded-controller
				      file-chunk new-lc))))))))
      (cond ((eq file-manip ':noload)
	     (chunk-terminate-mgt lc ':ask))
	    ((and file-manip
		  (not (eq file-manip (Loaded-file-chunk-manip lc))))
	     (setf (Loaded-file-chunk-manip lc) file-manip)))
      lc))

;;; Given the names, one might think this should be a subclass of 
;;; Loaded-file-chunk.  However, Loaded-file-chunks are complex entities
;;; that can map into different versions depending on user decisions.
;;; This class is just a simple loaded-or-not-loaded affair.
;;; The file doesn't have to be a source file (!?)
(defclass Loaded-source-chunk (Chunk)
   ((file-ch :accessor Loaded-source-chunk-file
	     :initarg :file)))
	  
(defun place-Loaded-source-chunk (file-ch)
   (chunk-with-name `(:loaded ,(Chunk-name file-ch))
      (\\ (name)
	 (make-instance 'Loaded-source-chunk
	    :name name
	    :file file-ch))))

(defmethod derive-date ((l-source Loaded-source-chunk))
   false)

(defun loadeds-check-bases ()
   (let ((loadeds-needing-checking !()))
      (dolist (lc all-loaded-file-chunks*)
	 (cond ((memq (Loaded-file-chunk-manip lc)
		      '(:defer :follow))
		(on-list lc loadeds-needing-checking))))
;;;;      (dolist (lc loadeds-needing-checking)
;;;;	 (monitor-filoid-basis lc)
;;;;	 (cond ((not (chunk-up-to-date lc))
;;;;		(on-list lc loadeds-needing-update))))
      (chunks-update (cons fload-compile-flag-chunk*
			   loadeds-needing-checking)
		     false false)))

(defvar loaded-manip-dbg* false)

(defgeneric loaded-chunk-set-basis (loaded-ch)
   (:method ((lch t)) nil))

(defun place-compiled-chunk (source-file-chunk)
   (let* ((filename (File-chunk-pathname source-file-chunk))
	  (ov (pathname-object-version filename false))
	  (real-ov (and (not (eq ov ':none))
			(pathname-resolve ov false))))
      (let ((compiled-chunk
	       (chunk-with-name
		   `(:compiled ,filename)
		   (\\ (exp)
		      (let ((new-chunk
			       (make-instance 'Compiled-file-chunk
				  :source-file source-file-chunk
				  :object-file (place-File-chunk
						  real-ov
						  :kind ':object)
				  :pathname (pathname-object-version
					       filename
					       false)
				  :kind ':object
				  :name exp
				  ;; This will be changed when we
				  ;; derive the Loaded-basis-chunk
				  ;; for the source file, but
				  ;; it must always include the
				  ;; source-file chunk --
				  :basis (list source-file-chunk))))
			 (setf (Chunk-basis new-chunk)
			       (list source-file-chunk))
			 new-chunk)))))
	 compiled-chunk)))
	    
(defvar debuggability* 1)

(defmethod derive-date ((cf-ch Compiled-file-chunk))
   (let ((pn (File-chunk-pn
		(Compiled-file-chunk-source-file cf-ch))))
      (let ((ov (pathname-object-version pn false)))
	 (let ((real-ov (and (not (eq ov ':none))
			     (pathname-resolve ov false)))
	       (prev-time (Compiled-file-chunk-last-compile-time cf-ch)))
	    (let  ((old-obj-write-time
		      (and real-ov
			   (probe-file real-ov)
			   (pathname-write-time real-ov))))
	       (cond ((and old-obj-write-time
			   (>= prev-time 0)
			   (< prev-time old-obj-write-time))
		      (format *error-output*
			 !"Warning -- file ~s apparently compiled outside ~
                           control of ~s~%"
			 real-ov cf-ch)))
	       (or old-obj-write-time
		   prev-time))))))
(eval-when (:compile-toplevel :load-toplevel)

(defvar sub-file-types* !())

;;; A "sub-file" is a chunk of data that is a subset (usually proper)
;;; of a file, with the property that when the file is loaded the subset
;;; is sure to be loaded, so that (:loaded f) obviates (:slurped (S f)),
;;; where S is the kind of subfile.  (S is :macros, :nisp-type-decls, or
;;; the like.)
;;; We need 3 Chunk subclasses for sub-file-type N:
;;; Class name: N-chunk         Chunk name: (N f)            - the contents 
;;;                                                            of the sub-file
;;;             Slurped-N-chunk             (slurped (N f)) - as slurped
;;;             Loaded-N-chunk              (loaded (N f))  - Or-chunk
;;;							       (see below)
;;; Plus one or more existing classes L, typically (loaded f), that trump
;;; (slurped (N f))
;;; The Or-chunk has disjuncts (union L {(slurped (N f))}), default
;;; (slurped (N f)).

(defstruct (Sub-file-type)
   name
   chunker
   ;; -- Function to produce chunk (N F) for file F (N= name of Sub-file-type)
   slurp-chunker
   ;; -- Function to produce chunk (:slurped (N F))
   load-chunker
   ;; -- Function to produce chunk (:loaded (N F)) 
)

(defmacro def-sub-file-type (sym
			     &key
			     ((:default default-handler^)
			      'nil)
			     ((:file->state-fcn file->state-fcn^)
			      '(\\ (_) nil)))
   (let  ((sym-name (Symbol-name sym)))
      (let ((subfile-class-name (build-symbol (:< (string-capitalize sym-name))
					      -chunk))
	    (slurped-sym-class-name
	       (build-symbol Slurped- (:< sym-name) -chunk))
	    (loaded-sym-class-name
	       (build-symbol Loaded- (:< sym-name) -chunk)))
	 (let* ((sub-pathname-read-fcn (build-symbol (:< subfile-class-name)
						     -pathname))
		(slurped-subfile-read-fcn
		   (build-symbol (:< slurped-sym-class-name)
				 -subfile))
		(subfile-placer-fcn (build-symbol place- (:< sym-name) -chunk))
		(slurped-subfile-placer-fcn
		   (build-symbol place-slurped- (:< sym-name) -chunk))
		(ld-pathname-read-fcn (build-symbol (:< loaded-sym-class-name)
						    -pathname))
		(loaded-class-loaded-file-acc
		   (build-symbol (:< loaded-sym-class-name)
				 -loaded-file))
		(loaded-subfile-placer-fcn
		   (build-symbol place-loaded- (:< sym-name) -chunk))
		(slurp-task-name (build-symbol (:package :keyword)
				    slurp- (:< sym-name)))
		(sub-file-type-name (build-symbol (:< sym-name)
					     -sub-file-type*)))
	    `(progn
		(defclass ,subfile-class-name (Chunk)
		   ((pathname :reader ,sub-pathname-read-fcn
			      :initarg :pathname
			      :type pathname)))

		(defmethod derive-date ((ch ,subfile-class-name))
		   (file-write-date (,sub-pathname-read-fcn ch)))

		;; There's nothing to derive for the subfile; as long as the
		;; underlying file is up to date, so is the subfile.	     
		(defmethod derive ((ch ,subfile-class-name))
		   false)

		(defmethod initialize-instance :after
				     ((ch ,subfile-class-name)
				      &rest _)
		   (setf (Chunk-basis ch)
			 (list (place-File-chunk
				  (,sub-pathname-read-fcn ch)))))

		(defclass ,slurped-sym-class-name (Chunk)
		  ((subfile :reader ,slurped-subfile-read-fcn
			    :initarg :subfile
			    :type Chunk)))

		(defmethod initialize-instance :after
					       ((ch ,slurped-sym-class-name)
						&rest _)
		   (setf (Chunk-basis ch)
			 (list (,slurped-subfile-read-fcn ch))))

		(defun ,subfile-placer-fcn (pn)
		   (chunk-with-name
		      `(,',sym ,pn)
		      (\\ (sub-name-exp)
			 (make-instance
			    ',subfile-class-name
			   :name sub-name-exp
			   :pathname pn))))

		(defun ,slurped-subfile-placer-fcn (pn)
		   (chunk-with-name
		      `(:slurped (,',sym ,pn))
		      (\\ (name-exp)
			 (make-instance ',slurped-sym-class-name
			    :name name-exp
			    :subfile (,subfile-placer-fcn pn)))))

		(defclass ,loaded-sym-class-name (Or-chunk)
		   ((pathname :reader ,ld-pathname-read-fcn
			      :initarg :pathname
			      :type pathname)
		    (loaded-file :accessor ,loaded-class-loaded-file-acc
				 :type Loaded-chunk)))

		(defun ,loaded-subfile-placer-fcn (pn)
      ;;;;		(format t "Placing new loaded chunk for ~s subfile
      ;;;;		chunk of ~s~%" ',sym pn)
		   (chunk-with-name
		       `(:loaded (,',sym ,pn))
		       (\\ (name-exp)
   ;;;;		       (format t !"Creating new loaded chunk for ~
   ;;;;                                   ~s subfile chunk of ~s~%"
   ;;;;			       ',sym pn)
			  (let ()
			     (make-instance ',loaded-sym-class-name
				 :name name-exp
				 :pathname pn)))
		       :initializer
			  (\\ (new-ch)
			     (let* ((file-ch (place-File-chunk pn))
				    (loaded-file-chunk
				       (place-Loaded-chunk file-ch false)))
				(setf (,loaded-class-loaded-file-acc new-ch)
				      loaded-file-chunk)
				(setf (Chunk-basis new-ch)
				      (list file-ch))
				(setf (Or-chunk-disjuncts new-ch)
				      (list loaded-file-chunk
					    (,slurped-subfile-placer-fcn
					        pn)))))))

		(def-slurp-task ,slurp-task-name
		   :default ,default-handler^
		   :file->state-fcn ,file->state-fcn^)

 		(defmethod derive ((x ,slurped-sym-class-name))
		   (let ((file (,sub-pathname-read-fcn
				  (,slurped-subfile-read-fcn
				     x))))
   ;;;;		   (setq slurp-ch* x)
   ;;;;		   (break "About to slurp ~s~%" file)
		      (file-slurp file
				  (list ,(build-symbol (:< slurp-task-name)
						       *))
				  false)
		      (get-universal-time)))

		(defparameter ,sub-file-type-name
		   (make-Sub-file-type
		      :name ',sym
		      :chunker #',subfile-placer-fcn
		      :slurp-chunker #',slurped-subfile-placer-fcn
		      :load-chunker #',loaded-subfile-placer-fcn))

		(setq sub-file-types*
		      (cons ,sub-file-type-name
			    (remove-if
			       (\\ (sfty)
				  (eq (Sub-file-type-name sfty)
				      ',sym))
			       sub-file-types*))))))))
)

(defun lookup-sub-file-type (name)
   (dolist (sfty
	    sub-file-types*
	    (error "Undefined sub-file-type ~s" name))
      (cond ((eq (Sub-file-type-name sfty) name)
	     (return sfty)))))

(defun compiled-ch-sub-file-link (compiled-ch callee-ch sub-file-type load)
      (pushnew (funcall
		  (Sub-file-type-chunker sub-file-type)
		  (File-chunk-pathname callee-ch))
	       (Chunk-basis compiled-ch))
      (pushnew (funcall (cond (load
			       (Sub-file-type-load-chunker
				  sub-file-type))
			      (t
			       (Sub-file-type-slurp-chunker
				  sub-file-type)))
			 (File-chunk-pathname callee-ch))
	       (Chunk-update-basis compiled-ch)))

(eval-when (:compile-toplevel :load-toplevel)
   (def-sub-file-type :macros)

;;;;   (defparameter standard-sub-file-types* (list macros-sub-file-type*))

   (defun macros-slurp-eval (e _) (eval e) false))

(datafun :slurp-macros defmacro #'macros-slurp-eval)

(defmacro needed-by-macros (&body l)
   `(progn ,@l))

(datafun :slurp-macros needed-by-macros
   (defun :^ (exp _)
      (dolist (e exp) (eval e))
      false))

(datafun :slurp-macros defsetf  #'macros-slurp-eval)

(datafun :slurp-macros defstruct #'macros-slurp-eval)

(datafun :slurp-macros defvar
   (defun :^ (form _)
      (eval `(defvar ,(cadr form)))
      false))

(datafun :slurp-macros defconstant
   (defun :^ (form _)
      (cond ((not (boundp (cadr form)))
	     (eval form)))
      false))

(datafun :slurp-macros subr-synonym #'macros-slurp-eval)

(datafun :slurp-macros datafun
  (defun :^ (e _)
    (cond ((eq (cadr e) 'attach-datafun)
	   (eval e)))
    false))

(datafun :slurp-macros eval-when
   (defun :^ (form _)
      (cond ((memq ':slurp-toplevel (cadr form))
	     (dolist (e (cddr form))
	        (eval e))))
      false))

(datafun :slurp-macros eval-when-slurping
   (defun :^ (form _)
      (dolist (e (cdr form))
	 (eval e))
      false))

(datafun :slurp-macros needed-by-macros eval-when-slurping)

;;;;(defun compilable (pathname)
;;;;   (member (Pathname-type pathname) source-suffixes* :test #'equal))

;;; For debugging --
(defun flchunk (pn)
   (let ((pn (->pathname pn)))
      (place-Loaded-file-chunk (place-File-chunk pn)
			       false)))