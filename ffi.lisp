;;; -*- show-trailing-whitespace: t; indent-tabs-mode: nil -*-

;;; Copyright (c) 2009 David Lichteblau. All rights reserved.

;;; Redistribution and use in source and binary forms, with or without
;;; modification, are permitted provided that the following conditions
;;; are met:
;;;
;;;   * Redistributions of source code must retain the above copyright
;;;     notice, this list of conditions and the following disclaimer.
;;;
;;;   * Redistributions in binary form must reproduce the above
;;;     copyright notice, this list of conditions and the following
;;;     disclaimer in the documentation and/or other materials
;;;     provided with the distribution.
;;;
;;; THIS SOFTWARE IS PROVIDED BY THE AUTHOR 'AS IS' AND ANY EXPRESSED
;;; OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
;;; WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
;;; ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
;;; DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
;;; DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
;;; GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
;;; INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
;;; WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
;;; NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
;;; SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

(in-package :qt)
#+sbcl (declaim (optimize (debug 2)))

(defvar *loaded* nil)
(defvar *library-loaded-p* nil)

(defun load-libcommonqt ()
  (cffi:load-foreign-library
   #-(or windows mswindows win32)
   (namestring (merge-pathnames "libcommonqt.so"
                                (asdf::component-relative-pathname
                                 (asdf:find-system :qt))))
   #+(or windows mswindows win32)
   (namestring (merge-pathnames "debug/commonqt.dll"
                                (asdf::component-relative-pathname
                                 (asdf:find-system :qt)))))
  (setf *library-loaded-p* t))

#-(or ccl
      (and sbcl
           ;; On SBCL/win32, :LINKAGE-TABLE is on *FEATURES*, but that's
           ;; a lie, it can't actually process FFI definitions before
           ;; the library has been loaded.
           (and linkage-table (not windows))))
(load-libcommonqt)

(defmacro defcfun (name ret &rest args)
  `(cffi:defcfun (,name ,(intern (string-upcase name) :qt)) ,ret ,@args))

(cffi:defcvar ("qt_Smoke" qt_Smoke) :pointer)
(cffi:defcvar ("qtwebkit_Smoke" qtwebkit_Smoke) :pointer)

(defcfun "sw_smoke" :void
  (smoke :pointer)
  (data :pointer)
  (deletion-callback :pointer)
  (method-callback :pointer)
  (child-callback :pointer))

(defcfun "sw_windows_version" :int)

(defcfun "sw_map_children" :void
  (obj :pointer)
  (cb :pointer))

(defcfun "sw_make_qpointer" :pointer
  (target :pointer))

(defcfun "sw_qpointer_is_null" :char
  (qp :pointer))

(defcfun "sw_delete_qpointer" :void
  (qp :pointer))

(defcfun "sw_make_qstring" :pointer
  (str :string))

(defcfun "sw_delete_qstring" :void
  (qstring :pointer))

(defcfun "sw_make_qstringlist" :pointer)

(defcfun "sw_delete_qstringlist" :void
  (qstringlist :pointer))

(defcfun "sw_qstringlist_append" :void
  (qstringlist :pointer)
  (str :string))

(defcfun "sw_make_metaobject" :pointer
  (parent :pointer)
  (str :pointer)
  (data :pointer))

(defcfun "sw_delete" :void
  (stack :pointer))

(defcfun "sw_qstring_to_utf8" :pointer
  (obj :pointer))

(defcfun "sw_qstring_to_utf16" :pointer
  (obj :pointer))

(defun qstring-pointer-to-lisp (raw-ptr)
  (declare (optimize speed))
  #+nil
  ;; fixme: babel doesn't get endianness right in utf-16.
  (cffi:foreign-string-to-lisp (sw_qstring_to_utf16 raw-ptr)
                               :encoding :utf-16)
  ;; handcode instead:
  (let* ((data (sw_qstring_to_utf16 raw-ptr))
         (nbytes (cffi::foreign-string-length data :encoding :utf-16))
         (res (make-string (truncate nbytes 2))))
    (iter (for i from 0 by 2 below nbytes)
          (for j from 0)
          (let ((code (cffi:mem-ref data :unsigned-short i)))
            (until (zerop code))
            (setf (char res j) (code-char code))))
    res))

(defcfun "sw_find_name" :short
  (smoke :pointer)
  (str :string))

(defcfun "sw_find_class" :void
  (name :string)
  (smoke** :pointer)
  (index** :pointer))

(defcfun "sw_id_method" :short
  (smoke :pointer)
  (class :short)
  (name :short))

(defcfun "sw_id_type" :short
  (smoke :pointer)
  (name :string))

(defcfun "sw_id_class" :short
  (smoke :pointer)
  (name :string)
  (external :char))                     ;bool

(defcfun "sw_qlist_variant_new" :pointer)
(defcfun "sw_qlist_variant_delete" :void (qlist :pointer))
(defcfun "sw_qlist_variant_size" :int (qlist :pointer))
(defcfun "sw_qlist_variant_at" :pointer (qlist :pointer) (index :int))
(defcfun "sw_qlist_variant_append" :void (qlist :pointer) (var :pointer))

(defcfun "sw_qlist_int_new" :pointer)
(defcfun "sw_qlist_int_delete" :void (qlist :pointer))
(defcfun "sw_qlist_int_size" :int (qlist :pointer))
(defcfun "sw_qlist_int_at" :int (qlist :pointer) (index :int))
(defcfun "sw_qlist_int_append" :void (qlist :pointer) (var :int))

(defcfun "sw_qlist_void_new" :pointer)
(defcfun "sw_qlist_void_delete" :void (qlist :pointer))
(defcfun "sw_qlist_void_size" :int (qlist :pointer))
(defcfun "sw_qlist_void_at" :pointer (qlist :pointer) (index :int))
(defcfun "sw_qlist_void_append" :void (qlist :pointer) (var :pointer))

(cffi:defcstruct |struct SmokeData|
  (name :string)
  (classes :pointer)
  (nclasses :short)
  (methods :pointer)
  (nmethods :short)
  (methodmaps :pointer)
  (nmethodmaps :short)
  (methodnames :pointer)
  (nmethodnames :short)
  (types :pointer)
  (ntypes :short)
  (inheritanceList :pointer)
  (argumentList :pointer)
  (ambiguousMethodList :pointer)
  (castFn :pointer)
  (thin :pointer)
  (fat :pointer))

(macrolet ((% (fun slot)
             `(progn
                (declaim (inline ,fun))
                (defun ,fun (data)
                  (cffi:foreign-slot-value data '|struct SmokeData| ',slot)))))
  (% data-name name)
  (% data-classes classes)
  (% data-nclasses nclasses)
  (% data-methods methods)
  (% data-nmethods nmethods)
  (% data-methodmaps methodmaps)
  (% data-nmethodmaps nmethodmaps)
  (% data-methodnames methodnames)
  (% data-nmethodnames nmethodnames)
  (% data-types types)
  (% data-ntypes ntypes)
  (% data-inheritanceList inheritanceList)
  (% data-argumentList argumentList)
  (% data-ambiguousMethodList ambiguousMethodList)
  (% data-castFn castFn)
  (% data-thin thin)
  (% data-fat fat))

(cffi:defcunion |union StackItem|
  (ptr :pointer)
  (bool :char)
  (char :char)
  (uchar :unsigned-char)
  (short :short)
  (ushort :unsigned-short)
  (int :int)
  (uint :uint)
  (long :long)
  (ulong :ulong)
  (float :float)
  (double :double)
  (enum :int)
  (class :pointer))

(cffi:defcstruct |struct Method|
  (classid :short)
  (name :short)
  (args :short)
  (numargs :unsigned-char)
  (flags :unsigned-short)
  (ret :short)
  (methodForClassFun :short))

(cffi:defcstruct |struct MethodMap|
  (classid :short)
  (name :short)
  (methodid :short))

(cffi:defcstruct |struct Class|
  (className :string)
  (external :char)
  (parents :short)
  (classfn :pointer) ;; void (*classfn)(Index method, void *obj, Stack args)
  (enumfn :pointer)
  (flags :short)
  (size :unsigned-int))

(cffi:defcstruct |struct Type|
  (name :string)
  (classid :short)
  (flags :short))

(defvar *callbacks* (make-hash-table :test 'equal))

(defmacro defcallback (name ret (&rest args) &body body)
  `(cffi:defcallback (,name #+commonqt-use-stdcall :calling-convention
                            #+commonqt-use-stdcall :stdcall)
       ,ret ,args ,@body))

(defcallback deletion-callback
    :void
    ((smoke :pointer)
     (obj :pointer))
  ;; Just dispatch to an ordinary function for debugging purposes.
  ;; Redefinition of a callback wouldn't affect the existing C++ code,
  ;; redefinition of the function does.
  (%deletion-callback obj))

(defcallback method-invocation-callback
    :char
    ((smoke :pointer)
     (method :short)
     (obj :pointer)
     (args :pointer)
     (abstractp :char))
  ;; Just dispatch to an ordinary function for debugging purposes.
  ;; Redefinition of a callback wouldn't affect the existing C++ code,
  ;; redefinition of the function does.
  (%method-invocation-callback smoke method obj args abstractp))

(defcallback child-callback
    :void
    ((smoke :pointer)
     (added :char)                      ;bool
     (obj :pointer))
  ;; Just dispatch to an ordinary function for debugging purposes.
  ;; Redefinition of a callback wouldn't affect the existing C++ code,
  ;; redefinition of the function does.
  (%child-callback added obj))

(defvar *ptr-callback*)

(defcallback ptr-callback
    :void
    ((obj :pointer))
  (funcall *ptr-callback* obj))
