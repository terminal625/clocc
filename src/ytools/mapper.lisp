;-*- Mode: Common-lisp; Package: ytools; Readtable: ytools; -*-
(in-package :ytools)

;;; Copyright (C) 1976-2003 
;;;     Drew McDermott and Yale University.  All rights reserved
;;; This software is released under the terms of the Modified BSD
;;; License.  See file COPYING for details.

(depends-on %ytools/ setter)

(eval-when (:load-toplevel :compile-toplevel :execute :slurp-toplevel)
   (export '(<# <! <$ <& <v << </ <? mappend mapeltreduce neg mapmac)))

(defmacro <# (&rest l) `(mapcar ,@(mapmacify l)))
(defmacro <! (&rest l) `(mapcan ,@(mapmacify l)))
(defmacro <$ (&rest l) `(mappend ,@(mapmacify l)))
(defmacro <& (&rest l) `(every ,@(mapmacify l)))
(defmacro <v (&rest l) `(some ,@(mapmacify l)))
(defmacro << (&rest l) `(apply ,@(mapmacify l)))
(defmacro </ (&rest l) `(mapeltreduce ,@(mapmacify l)))

(defmacro <? (&rest l)
   (match-cond (mapmacify l)
      ?( (?fcn ?larg)
	(let ((negfcn
		 (match-cond fcn
		    ?( #'(lambda ?args ?@lbody ?res)
		      `#'(lambda ,args ,@lbody (not ,res)))
		    ?( (\\ ?args ?@lbody ?res)
		      `(\\ ,args ,@lbody (not ,res)))
		    ((consp fcn)
		     (let ((fvar (gensym)))
			`(let ((,fvar ,fcn))
			    (\\ (x) (not (funcall ,fvar x))))))
		    ?( #'sym
		      `(\\ (x) (not (,sym x))))
		    ?( ?sym
		      `(\\ (x) (not (,sym x)))))))
	   `(remove-if ,negfcn ,larg)))
      (t
       (error "Ill-formed: " `(<? ,@l)))))

(defun mappend (fcn &rest lists)
   (repeat :for (cross-section :collector res)
    :until (some #'null lists)
    :result res
       (!= cross-section (mapcar #'car lists))
       (!= lists (mapcar #'cdr lists))
    :append (apply fcn cross-section)))

(define-compiler-macro mappend (fcn &rest lists)
   (let ((listvars (mapcar (\\ (_) (gensym)) lists))
	 (colvar (gensym)))
      `(repeat :for (,@(mapcar (\\ (var listexp)
				  `(,var :in ,listexp))
			       listvars lists)
		     :collector ,colvar)
	:append (funcall ,fcn ,@listvars))))


(defmacro mapeltreduce (proc ident &rest lists)
   (let ((listvars (mapcar (\\ (_) (gensym)) lists))
	 (resvar (gensym)))
      `(repeat :for (,@(mapcar (\\ (v l) `(,v :in ,l))
			       listvars lists)
		     (,resvar
		      = ,ident
		      :then ,(cons-funcall proc (cons resvar listvars))))
	:result ,resvar)))

(defun cons-funcall (f argl)
   (cond ((and (is-Pair f) (memq (car f) '(function funktion quote)))
          `(,(cadr f) . ,argl))
         ((and (is-Pair f) (eq (car f) '\\))
          `((lambda . ,(cdr f)   ) . ,argl))
         (t `(funcall ,f . ,argl))   ))


;; An example of a mapmac would be a pseudo-function NEG,
;; such that (<& NEG ATOM Z) became (<& (\\ (X) (NOT (ATOM X))   ) Z).
;; The MAPMAC property of NEG would return
;;                ((FUNCTION (\\ (X) (NOT (ATOM X))   )) Z)
;; in this case.
(defun mapmacify (l)
   (let ((mapmac-expander
	    (and (is-Symbol (car l))
		 (get (car l) 'mapmac))))
      (cond (mapmac-expander
	     (funcall mapmac-expander l))
	    (t
	     `(,(cond ((is-Symbol (car l))
		       `#',(car l))
		      (t (car l)))
	       ,@(cdr l))))))

(datafun mapmac neg
 (defun :^ (l)
   (cond ((not (eq (car l) 'neg))
          (setq l (append (car l) (cdr l))))   )
   (let ((ff (mapmacify (cdr l))))
       `((\\ (\!v1) 
	      (not (,(unfquot (car ff)) 
		   \!v1))   )
         . ,(cdr ff))   )))

(defun unfquot (ff)
   (cond ((atom ff) ff)
	 ((memq (car ff) '(function quote)) 
	  (cadr ff))
	 (t ff)   )) 

