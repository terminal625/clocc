;;; -*- Mode: CLtL -*-

;;; env-package.lisp --
;;;
;;; Copyright (c) 2000 Marco Antoniotti, all rights reserved.
;;; This software is released under the terms of the GNU Lesser General
;;; Public License (LGPL, see file COPYRIGHT for details).

(defpackage "CL.ENVIRONMENT" (:use "COMMON-LISP")
  (:nicknames "CL.ENV"
	      "ORG.CONS.CLOCC/MARCOXA/CL-ENVIRONMENT")

  ;; Shadow symbols from Chapter 25 of the CLHS.
  (:shadow "SOFTWARE-TYPE"
	   "SOFTWARE-VERSION"
	   "MACHINE-TYPE"
	   "MACHINE-VERSION"
	   "MACHINE-INSTANCE"
	   )
  
  ;; Basic Classes.
  (:export "SOFTWARE"
	   "MACHINE"
	   "OPERATING-SYSTEM"
	   "COMMON-LISP-IMPLEMENTATION"
	   )

  ;; Basic Interface.
  (:export "SOFTWARE-TYPE"
	   "SOFTWARE-VERSION"
	   "MACHINE-TYPE"
	   "MACHINE-VERSION"
	   "MACHINE-INSTANCE"

	   "OPERATING-SYSTEM-TYPE"
	   "OPERATING-SYSTEM-VERSION"
	   "OPERATING-SYSTEM-FEATURE-TAG"
	   "OS-TYPE"		; Abbreviation.
	   "OS-VERSION"		; Abbreviation.
	   "OS-FEATURE-TAG"     ; Abbreviation.

	   "FIND-OPERATING-SYSTEM-CLASS"
	   "FIND-OS-CLASS"	; Abbreviation.

	   "OPERATING-SYSTEM-TAG-COMPATIBLE-P"
	   "OS-TAG-COMPATIBLE-P"	; Abbreviation
	   
	   "COMMON-LISP-IMPLEMENTATION-TYPE"
	   "COMMON-LISP-IMPLEMENTATION-VERSION"

	   "*COMMON-LISP-IMPLEMENTATION*"
	   "*OPERATING-SYSTEM*"
	   "*MACHINE*"

	   "VERSION"
	   "VERSION-CASE"

	   "SYSTEM-INFO"
	   )

  ;;---------------------------------------------
  ;; Exports related to known CL implementations.

  (:export "GENERIC-COMMON-LISP-IMPLEMENTATION")
  
  ;; Franz Inc. Allegro.
  (:export "ALLEGRO")

  ;; Harlequin LispWorks.
  (:export "LISPWORKS")

  ;; MCL.
  (:export "MCL")

  ;; CMUCL and SBCL.
  (:export "CMUCL" "SBCL")

  ;; CLisp.
  (:export "CLISP")

  ;; Kcl and derivatives.
  (:export "KCL" "IBCL" "AKCL" "GCL" "ECOLISP")

  ;; ECLipse
  (:export "ECLIPSE")

  ;; Lucid
  (:export "LUCID")

  ;; Corman
  (:export "CORMAN")

  ;; Genera Symbolics Common Lisp
  (:export "SCL")

  ;;--------------------------------------------
  ;; Exports related to known Operating Systems.

  ;; UNIX (generic).
  (:export "UNIX")

  ;; SunOS and Solaris.
  (:export "SUN-OS" "SOLARIS")

  ;; HP-UX.
  (:export "HP-UX")

  ;; IRIX.
  (:export "IRIX")

  ;; Linux.
  (:export "LINUX")

  ;; MS-DOS and Windows.
  (:export "MS-DOS"
	   "MS-WINDOWS"
	   "MS-WINDOWS-32"
	   "MS-WINDOWS-95"
	   "MS-WINDOWS-98"
	   "MS-WINDOWS-NT"
	   "MS-WINDOWS-NT-TSE"
	   "MS-WINDOWS-2000"
	   )

  ;; Mac.
  (:export "MAC-OS")

  ;; Genera.
  (:export "GENERA")
  )
	   


;;; end of file -- env-package.lisp
