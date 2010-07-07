;;; mon-post-load-hooks.el --- fncns to perform after initializing MON Emacsen
;; -*- mode: EMACS-LISP; -*-

;;; ================================================================
;; Copyright © 2010 MON KEY. All rights reserved.
;;; ================================================================

;; FILENAME: mon-post-load-hooks.el
;; AUTHOR: MON KEY
;; MAINTAINER: MON KEY
;; CREATED: 2010-03-24T11:27:54-04:00Z
;; VERSION: 1.0.0
;; COMPATIBILITY: Emacs23.*
;; KEYWORDS: environment, installation, site, local,

;;; ================================================================

;;; COMMENTARY: 

;; =================================================================
;; DESCRIPTION:
;; mon-post-load-hooks provides fncns to perform after initializing MON Emacsen.
;;
;; FUNCTIONS:►►►
;; `mon-run-post-load-hooks'
;; `mon-purge-cl-symbol-buffers-on-load'
;; `mon-purge-emacs-temp-files-on-quit'
;; `mon-purge-doc-view-cache-directory'
;; `mon-purge-thumbs-directory'
;; `mon-purge-slime-swank-port-file'
;; `mon-purge-temporary-file-directory'
;; `mon-purge-tramp-persistency-file'
;; FUNCTIONS:◄◄◄
;;
;; MACROS:
;;
;; METHODS:
;;
;; CLASSES:
;;
;; CONSTANTS:
;;
;; FACES:
;;
;; VARIABLES:
;; `*mon-post-load-hook-trigger-buffer*', 
;; `*mon-purge-emacs-temp-file-dir-fncns*',
;; 
;; ALIASED/ADVISED/SUBST'D:
;;
;; DEPRECATED:
;;
;; RENAMED:
;;
;; MOVED:
;;
;; TODO:
;;
;; NOTES:
;;
;; SNIPPETS:
;;
;; REQUIRES:
;;
;; THIRD-PARTY-CODE:
;;
;; URL: http://www.emacswiki.org/emacs/mon-post-load-hooks.el
;; FIRST-PUBLISHED: <Timestamp: #{2010-03-27T22:59:00-04:00Z} - by MON>
;;
;; EMACSWIKI: { URL of an EmacsWiki describing mon-post-load-hooks. }
;;
;; FILE-CREATED:
;; <Timestamp: #{2010-03-24T11:27:54-04:00Z}#{10123} - by MON>
;;
;; =================================================================

;;; LICENSE:

;; =================================================================
;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 3, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth
;; Floor, Boston, MA 02110-1301, USA.
;; =================================================================
;; Permission is granted to copy, distribute and/or modify this
;; document under the terms of the GNU Free Documentation License,
;; Version 1.3 or any later version published by the Free Software
;; Foundation; with no Invariant Sections, no Front-Cover Texts,
;; and no Back-Cover Texts. A copy of the license is included in
;; the section entitled ``GNU Free Documentation License''.
;; 
;; A copy of the license is also available from the Free Software
;; Foundation Web site at:
;; (URL `http://www.gnu.org/licenses/fdl-1.3.txt').
;;; ==============================
;; Copyright © 2010 MON KEY 
;;; ==============================

;;; CODE:

(eval-when-compile (require 'cl))

;;; ==============================
;;; :TODO incorporate these:
;;; `mon-check-feature-for-loadtime', `mon-after-mon-utils-loadtime',
;;; `mon-set-register-tags-loadtime', `mon-bind-iptables-vars-at-loadtime',
;;; `mon-bind-cifs-vars-at-loadtime', `mon-CL-cln-colon-swap',
;;; `mon-bind-nefs-photos-at-loadtime', `mon-help-utils-loadtime',
;;; `mon-help-utils-CL-loadtime', `mon-bind-doc-help-proprietery-vars-at-loadtime'

;;; ==============================
;; :LOAD-EMACS
;;; ==============================

;;; ==============================
;;; :CREATED <Timestamp: #{2010-03-23T22:24:16-04:00Z}#{10122} - by MON KEY>
(defun mon-purge-cl-symbol-buffers-on-load ()
  "Remove buffers left by CL Hspec snarfage routines.\n
:NOTE Evaluated post Emacs init with `mon-run-post-load-hooks'.
:SEE-ALSO `mon-set-common-lisp-hspec-init',
`mon-purge-emacs-temp-files-on-quit',
`mon-check-feature-for-loadtime', `mon-after-mon-utils-loadtime',
`mon-set-register-tags-loadtime', `mon-bind-iptables-vars-at-loadtime',
`mon-bind-cifs-vars-at-loadtime', `mon-CL-cln-colon-swap',
`mon-bind-nefs-photos-at-loadtime', `mon-help-utils-loadtime',
`mon-help-utils-CL-loadtime', `mon-bind-doc-help-proprietery-vars-at-loadtime',
`mon-purge-doc-view-cache-directory', `mon-purge-thumbs-directory',
`mon-purge-temporary-file-directory', `mon-htmlfontify-dir-purge-on-quit',
`mon-its-all-text-purge-on-quit', `*mon-purge-emacs-temp-file-dir-fncns*',
`*mon-purge-emacs-temp-file-dir-fncns*', `*mon-post-load-hook-trigger-buffer*'.\n►►►"
  (dolist (gb '("Map_Sym.txt"
                "Map_IssX.txt"
                "*CL-EXT-PKG-MAP*"))
    (when (get-buffer gb)
      (kill-buffer (get-buffer gb)))))

;;; ==============================
;;; :CREATED <Timestamp: #{2010-03-23T22:58:12-04:00Z}#{10122} - by MON KEY>
(defvar *mon-post-load-hook-trigger-buffer* nil
  "A buffer with a local kill-buffer-hook bound to 
`mon-run-post-load-hooks'. When this buffer is killed that run the hooks.
:SEE-ALSO `mon-run-post-load-hooks', `mon-purge-cl-symbol-buffers-on-load'
`mon-check-feature-for-loadtime', `mon-after-mon-utils-loadtime',
`mon-set-register-tags-loadtime', `mon-bind-iptables-vars-at-loadtime',
`mon-bind-cifs-vars-at-loadtime', `mon-CL-cln-colon-swap',
`mon-bind-nefs-photos-at-loadtime', `mon-help-utils-loadtime',
`mon-help-utils-CL-loadtime', `mon-bind-doc-help-proprietery-vars-at-loadtime'.\n►►►")
;;
(unless (bound-and-true-p *mon-post-load-hook-trigger-buffer*)
  (setq *mon-post-load-hook-trigger-buffer*
        (upcase (symbol-name '*mon-post-load-hook-trigger-buffer*))))
;;;(progn
;;; (makunbound '*mon-post-load-hook-trigger-buffer*)
;;; (unintern '*mon-post-load-hook-trigger-buffer*) )

;;; ==============================
;;; :CREATED <Timestamp: #{2010-03-23T22:53:41-04:00Z}#{10122} - by MON KEY>
(defun mon-run-post-load-hooks ()
  "Kill the buffer named by the variable `*mon-post-load-hook-trigger-buffer*'.
Killing this buffer will run that buffers local `kill-buffer-hook'.\n
:SEE-ALSO `mon-run-post-load-hooks', `mon-purge-cl-symbol-buffers-on-load'
`mon-check-feature-for-loadtime', `mon-after-mon-utils-loadtime',
`mon-set-register-tags-loadtime', `mon-bind-iptables-vars-at-loadtime',
`mon-bind-cifs-vars-at-loadtime', `mon-CL-cln-colon-swap',
`mon-bind-nefs-photos-at-loadtime', `mon-help-utils-loadtime',
`mon-help-utils-CL-loadtime', `mon-bind-doc-help-proprietery-vars-at-loadtime'.\n►►►"
(when (get-buffer *mon-post-load-hook-trigger-buffer*)
  (kill-buffer (get-buffer *mon-post-load-hook-trigger-buffer*))))
;;
(with-current-buffer 
    (get-buffer-create *mon-post-load-hook-trigger-buffer*)
  (when IS-MON-P-GNU
    (add-hook 'kill-buffer-hook 'mon-purge-cl-symbol-buffers-on-load nil t)
    (add-hook 'kill-buffer-hook 'mon-update-tags-tables nil t))
  (when (and IS-W32-P (fboundp  'mon-maximize-frame-w32))
    (add-hook 'kill-buffer-hook 'mon-maximize-frame-w32 nil t)))
;;
(eval-after-load "mon-utils"
  '(progn 
    (mon-after-mon-utils-loadtime)
    (mon-run-post-load-hooks)))

;;; ==============================
;; :KILL-EMACS
;;; ==============================

;;; ==============================
;; :TODO Relocate/reorganize `*emacs2html-temp*' and subdirs.
;;; Right now `mon-htmlfontify-buffer-to-firefox' writes to top-level.
;;; That dir should be partitioned as per those in other fncns below.

;;; ==============================
;;; (declare-function 'mon-remove-if "mon-utils" '(rmv-if-predicate rmv-list))
;;; :CREATED <Timestamp: #{2010-04-01T15:58:59-04:00Z}#{10134} - by MON KEY>
(defun mon-purge-doc-view-cache-directory ()
  "Remove all files in `doc-view-cache-directory'.\n
:NOTE When `IS-MON-SYSTEM-P', this function is evaluated by
`mon-purge-emacs-temp-files-on-quit' on the `kill-emacs-hook'.\n
:SEE-ALSO `doc-view-current-cache-dir', `mon-run-post-load-hooks',
`mon-purge-doc-view-cache-directory', `mon-purge-thumbs-directory',
`mon-purge-temporary-file-directory', `mon-htmlfontify-dir-purge-on-quit',
`mon-its-all-text-purge-on-quit', `mon-purge-cl-symbol-buffers-on-load',
`*mon-purge-emacs-temp-file-dir-fncns*'.\n►►►"
  (when (and IS-MON-SYSTEM-P
             (file-exists-p doc-view-cache-directory)
             (file-directory-p doc-view-cache-directory))
    ;;; (delete-directory doc-view-cache-directory)))
    (dired-delete-file doc-view-cache-directory 'always)))

;;; (eval-when (compile load eval) (require 'doc-view))
;;; when (intern-soft "slime-swank-port-file")
;;; ==============================
;; :CREATED <Timestamp: #{2010-04-01T15:59:12-04:00Z}#{10134} - by MON KEY>
(defun mon-purge-thumbs-directory ()
  "Remove all files in `thumbs-thumbsdir' with `thumbs-cleanup-thumbsdir'.\n
:NOTE When `IS-MON-SYSTEM-P', this function is evaluated by
`mon-purge-emacs-temp-files-on-quit' on  the `kill-emacs-hook'.\n
:SEE-ALSO `mon-run-post-load-hooks', `mon-purge-doc-view-cache-directory',
`mon-purge-thumbs-directory', `mon-purge-temporary-file-directory',
`mon-htmlfontify-dir-purge-on-quit', `mon-its-all-text-purge-on-quit',
`*mon-purge-emacs-temp-file-dir-fncns*' `mon-purge-cl-symbol-buffers-on-load',
`*mon-purge-emacs-temp-file-dir-fncns*'.\n►►►"
  (when IS-MON-SYSTEM-P
    (eval-when (compile load eval)
      (require 'thumbs))
    (let ((thumbs-thumbsdir-max-size 1))
      (thumbs-cleanup-thumbsdir))))

;;; ==============================
;;; :CHANGESET 1704
;;; :CREATED <Timestamp: #{2010-04-07T15:05:41-04:00Z}#{10143} - by MON KEY>
(defun mon-purge-slime-swank-port-file ()
  "Delete any `slime-swank-port-file's in `slime-temp-directory'.\n
:SEE-ALSO `slime-delete-swank-port-file'.\n►►►" 
  (let ((sspf (when (intern-soft "slime-swank-port-file")
                (slime-swank-port-file)))
        (when (and sspf (file-exists-p sspf))
          (delete-file sspf)))))

;;; ==============================
;;; :CHANGESET 1721
;;; :CREATED <Timestamp: #{2010-05-07T15:05:49-04:00Z}#{10185} - by MON KEY>
(defun mon-purge-tramp-persistency-file ()
  "Delete the file with `tramp-persistency-file-name'.\n
:SEE info node `(tramp)Connection caching'.\n
:SEE-ALSO .\n►►►"
  (when (and (intern-soft "tramp-persistency-file-name")
             tramp-persistency-file-name)
    (when (file-exists-p tramp-persistency-file-name)
      (delete-file tramp-persistency-file-name))))

;;; ==============================
;;; :CREATED <Timestamp: #{2010-04-01T16:10:45-04:00Z}#{10134} - by MON KEY>
(defun mon-purge-temporary-file-directory ()
  "Remove all files in `temporary-file-directory'.\n
:NOTE When `IS-MON-SYSTEM-P', this function is evaluated by
`mon-purge-emacs-temp-files-on-quit' on the `kill-emacs-hook'.\n
:SEE-ALSO `null-device', `small-temporary-file-directory',
`monb-purge-doc-view-cache-directory', `mon-purge-thumbs-directory',
`mon-purge-temporary-file-directory', `mon-htmlfontify-dir-purge-on-quit',
`mon-its-all-text-purge-on-quit', `*mon-purge-emacs-temp-file-dir-fncns*',
`mon-run-post-load-hooks'.\n►►►"
  (when IS-MON-SYSTEM-P
    (let ((tfd (mon-remove-if 
                #'(lambda (f-chk) 
                    (string-match-p (concat temporary-file-directory "/\.\.?$") f-chk))
                (directory-files temporary-file-directory t))))
      (dolist (is-fl tfd tfd)
        (if (car (file-attributes is-fl))
            ;; (delete-directory is-fl t)
            (delete-directory is-fl)
            (delete-file is-fl))))))

;;; ==============================
;;; :CREATED <Timestamp: #{2010-04-01T18:17:55-04:00Z}#{10134} - by MON KEY>
(defvar *mon-purge-emacs-temp-file-dir-fncns* nil
  "A list of functions evald by `mon-purge-emacs-temp-files-on-quit'.\n
:NOTE When `IS-MON-SYSTEM-P' these are run on the `kill-emacs-hook'.\n
:SEE-ALSO `mon-purge-doc-view-cache-directory' `mon-purge-thumbs-directory',
`mon-purge-temporary-file-directory', `mon-htmlfontify-dir-purge-on-quit',
`mon-its-all-text-purge-on-quit'.\n►►►")
;;
(unless (bound-and-true-p *mon-purge-emacs-temp-file-dir-fncns*)
  (setq *mon-purge-emacs-temp-file-dir-fncns*
        `(mon-purge-doc-view-cache-directory
          mon-purge-thumbs-directory
          mon-htmlfontify-dir-purge-on-quit
          ,(when (fboundp 'slime-swank-port-file)
                 'mon-purge-temporary-file-directory)
          mon-purge-tramp-persistency-file
          mon-its-all-text-purge-on-quit)))
;;
;;;(progn (makunbound '*mon-purge-emacs-temp-file-dir-fncns*)
;;;       (unintern  '*mon-purge-emacs-temp-file-dir-fncns*) )

;;; ==============================
;;; :CREATED <Timestamp: #{2010-03-29T20:46:44-04:00Z}#{10132} - by MON KEY>
(defun mon-purge-emacs-temp-files-on-quit ()
  "Purge various Emacs temporary files and directories.\n
Empty/Delete the following when the `kill-emacs-hook' is run:\n
:SEE-ALSO `mon-purge-doc-view-cache-directory', `mon-purge-thumbs-directory',
`mon-purge-temporary-file-directory', `mon-htmlfontify-dir-purge-on-quit',
`mon-its-all-text-purge-on-quit', `*mon-purge-emacs-temp-file-dir-fncns*'
`*mon-purge-emacs-temp-file-dir-fncns*', `mon-purge-slime-swank-port-file'.\n►►►"
  (when IS-MON-SYSTEM-P
    (dolist (p-o-q *mon-purge-emacs-temp-file-dir-fncns*)
      (unless (null p-o-q)
        (funcall p-o-q)))))
;;
;; Now, add-hook to purge the directory on quit.
(when (and IS-MON-SYSTEM-P (file-directory-p *emacs2html-temp*))
  (add-hook 'kill-emacs-hook 'mon-purge-emacs-temp-files-on-quit))
;;
;;; (remove-hook 'kill-emacs-hook 'mon-purge-emacs-temp-files-on-quit)

;;; ==============================
(provide 'mon-post-load-hooks)
;;; ==============================

;;; ====================================================================
;;; mon-post-load-hooks.el ends here
;;; EOF