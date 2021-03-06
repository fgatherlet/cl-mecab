(in-package :cl-user)
(defpackage cl-mecab
  (:use :cl)
  (:import-from :cffi
                #:define-foreign-library
                #:defcstruct
                #:defcenum
                #:defcfun
                #:use-foreign-library)
  (:import-from :split-sequence
                #:split-sequence)
  (:export #:make-mecab
           #:load-tagger
           #:with-mecab
           #:with-mecab*
           #:parse
           #:parse*
           ))
(in-package :cl-mecab)


(define-foreign-library libmecab
  ;;#+macports
  (:darwin "/opt/local/lib/libmecab.dylib")
  (:darwin "libmecab.dylib")
  (:unix "libmecab.so")
  (:windows "libmecab.dll"))

(use-foreign-library libmecab)

(defcfun ("mecab_new2" mecab_new2) :pointer
  (arg :string))

(defcfun ("mecab_sparse_tostr" mecab_sparse_tostr) :string
  (mecab :pointer) ; mecab_t
  (str :string))

(defcfun ("mecab_destroy" mecab_destroy) :void
  (mecab :pointer)) ; mecab_t

(defcfun ("mecab_strerror" mecab_strerror) :string
  (m :pointer) #|mecab_t|#)
(defcfun ("mecab_version" mecab_version) :string)

(defvar *mecab*)

(defun make-mecab (&optional (option ""))
  (mecab_new2 option))

(defun load-tagger (&optional (option ""))
  (setf *mecab* (make-mecab option)))

(defmacro with-mecab ((&optional (option "")) &body body)
  `(let ((*mecab* (load-time-value (make-mecab ,option))))
     (mecab_sparse_tostr *mecab* "") ; avoiding MeCab bug
     nil
     ,@body))

(defmacro with-mecab* ((&optional (option "")) &body body)
  (let ((g!opt (gensym "OPT")))
    `(let* ((,g!opt ,option)
            (*mecab* (make-mecab ,g!opt)))
       (mecab_sparse_tostr *mecab* "") ; avoiding MeCab bug
       (unwind-protect
            (progn ,@body)
         (mecab_destroy *mecab*)))))

(defun parse (text &optional (*mecab* *mecab*))
  (mecab_sparse_tostr *mecab* text))

(defun parse* (text &optional (*mecab* *mecab*))
  (let* ((parse-result (mecab_sparse_tostr *mecab* text))
         (lines (split-sequence #\Newline parse-result)))

    (loop
       for line in lines
       for tab-splited = (split-sequence #\Tab line)
       while (= 2 (length tab-splited))
       collect (cons (first tab-splited)
                     (split-sequence #\, (second tab-splited))))))
