;;; thing-cmds.el --- Commands that use things, as defined by `thingatpt.el'.
;; 
;; Filename: thing-cmds.el
;; Description: Commands that use things, as defined by `thingatpt.el'.
;; Author: Drew Adams
;; Maintainer: Drew Adams
;; Copyright (C) 2006-2011, Drew Adams, all rights reserved.
;; Created: Sun Jul 30 16:40:29 2006
;; Version: 20.1
;; Last-Updated: Tue May 10 17:53:50 2011 (-0700)
;;           By: dradams
;;     Update #: 370
;; URL: http://www.emacswiki.org/cgi-bin/wiki/thing-cmds.el
;; Keywords: thingatpt, thing, region, selection
;; Compatibility: GNU Emacs: 20.x, 21.x, 22.x, 23.x
;; 
;; Features that might be required by this library:
;;
;;   `thingatpt', `thingatpt+'.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 
;;; Commentary:
;;
;;  You can use the commands defined here to select different kinds of
;;  text entities ("things").  They are especially useful in
;;  combination with Transient Mark mode.
;; 
;;
;;  Macros defined here:
;;
;;    `with-comments-hidden'.
;;
;;  Commands defined here:
;;
;;    `cycle-thing-region', `hide/show-comments',
;;    `mark-enclosing-sexp', `mark-enclosing-sexp-backward',
;;    `mark-enclosing-sexp-forward', `mark-thing',
;;    `next-visible-thing', `next-visible-thing-repeat',
;;    `previous-visible-thing', `previous-visible-thing-repeat',
;;    `select-thing-near-point', `thgcmd-bind-keys', `thing-region'.
;;
;;  User options defined here:
;;
;;    `ignore-comments-flag', `thing-types'.
;;
;;  Non-interactive functions defined here:
;;
;;    `next-visible-thing-1', `next-visible-thing-2',
;;    `thgcmd-repeat-command'.
;;
;;  Internal variables defined here:
;;
;;    `last-visible-thing-type', `mark-thing-type',
;;    `thing-region-index'.
;;
;;  Put this in your init file (`~/.emacs'):
;;
;;   (require 'thing-cmds)
;;   (thgcmd-bind-keys) ; Only if you want the key bindings it defines
;;
;;  See also the doc strings of `next-visible-thing' and
;;  `thgcmd-bind-keys', for more information about thing navigation
;;  keys.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 
;;; Change Log:
;;
;; 2011/05/10 dadams
;;     Added (copied here from icicles-cmd2.el):
;;      ignore-comments-flag, hide/show-comments, last-visible-thing-type, with-comments-hidden, 
;;      next-visible-thing(-1|-2), previous-visible-thing.
;;     Added: thgcmd-repeat-command, thgcmd-bind-keys, (next|previous)-visible-thing-repeat.
;;     Extended (next|previous)-visible-thing to work with thgcmd-repeat-command.
;; 2011/01/04 dadams
;;     Added autoload cookies for defcustom and commands.
;;     Added groups for defcustom.
;; 2010/12/17 dadams
;;     Added: mark-enclosing-sexp(-forward|-backward).
;; 2008/11/29 dadams
;;     mark-thing: Set point to beginning/end of thing, so whole thing gets marked.
;;                 Make completion default be the first element of thing-types.
;; 2007/07/15 dadams
;;     Added cycle-thing-region-point.
;;     cycle-thing-region: Save point in cycle-thing-region-point and reuse it.
;; 2006/07/30 dadams
;;     Created.
;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 2, or
;; (at your option) any later version.
;; 
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;; 
;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth
;; Floor, Boston, MA 02110-1301, USA.
;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 
;;; Code:

(require 'thingatpt+ nil t) ;; (no error if not found): bounds-of-thing-at-point
(require 'thingatpt) ;; bounds-of-thing-at-point

;; Quiet the byte-compiler
(defvar last-repeatable-command)        ; Defined in `repeat.el'.

;;;;;;;;;;;;;;;;;;;;;;;;

;;;###autoload
(defun thing-region (thing)
  "Set the region around a THING near the cursor.
You are prompted for the type of thing.  Completion is available for
some standard types of thing, but you can enter any type.
The cursor is placed at the end of the region.  You can return it to
the original location by using `C-u C-SPC' twice."
  (interactive (list (let ((icicle-sort-function  nil))
                       (completing-read "Type of thing: " (mapcar #'list thing-types)
                                        nil nil nil nil "sexp"))))
  (let* ((bds    (if (fboundp 'bounds-of-thing-nearest-point) ; In `thingatpt+.el'.
                     (bounds-of-thing-nearest-point (intern thing))
                   (bounds-of-thing-at-point (intern thing))))
         (start  (car bds))
         (end    (cdr bds)))
    (cond ((and start end)
           (push-mark (point) t)        ; Mark position, so can use `C-u C-SPC'.
           (goto-char end)
           (push-mark start t 'activate)
           (setq deactivate-mark  nil)
           thing)                       ; Return thing.
          (t
           (message "No `%s' near point" thing)
           (setq deactivate-mark  nil)
           nil))))                      ; Return nil: no thing found.

;;;###autoload
(defalias 'select-thing-near-point 'cycle-thing-region)
;;;###autoload
(defun cycle-thing-region ()
  "Select a thing near point.  Successive uses select different things.
The default thing type is the first element of option `thing-types'. 
In Transient Mark mode, you can follow this with `\\[mark-thing]' to select
successive things of the same type, but to do that you must first use
`C-x C-x': `\\[cycle-thing-region] C-x C-x \\[mark-thing]'"
  (interactive)
  (if (eq last-command this-command)
      (goto-char cycle-thing-region-point)
    (setq thing-region-index        0
          cycle-thing-region-point  (point)))
  (let* ((thing    (elt thing-types thing-region-index))
         (success  (thing-region thing)))
    (setq thing-region-index  (1+ thing-region-index))
    (when success
      (setq mark-thing-type  (intern thing)) ; Save it for `mark-thing'.
      (message "%s" (capitalize (elt thing-types (1- thing-region-index)))))
    (when (>= thing-region-index (length thing-types))
      (setq thing-region-index  0))))

;;;###autoload
(defcustom ignore-comments-flag t
  "Non-nil means macro `with-comments-hidden' hides comments."
  :type 'boolean :group 'matching)

;;;###autoload
(defcustom thing-types '("word" "symbol" "sexp" "list" "line" "sentence"
                         "paragraph" "page" "defun" "number" "form")
  "*List of thing types.  Used for completion and `cycle-thing-region'.
Each list element is a string that names a type of text entity for
which there is a either a corresponding `forward-'thing operation, or
corresponding `beginning-of-'thing and `end-of-'thing operations.
Examples include \"word\", \"sentence\", and \"defun\".

The first element is the default thing type used by `mark-thing' and
`cycle-thing-region'."
  :type '(repeat string) :group 'lisp :group 'editing)

(defvar thing-region-index 0 "Index of current thing in `thing-types'.")

(defvar mark-thing-type nil "Current thing type used by `mark-thing'.")

(defvar cycle-thing-region-point nil
  "Position of point before `cycle-thing-region'.")

;;;###autoload
(defun mark-thing (thing &optional arg allow-extend)
  "Set point at one end of THING and set mark ARG THINGs from point.
THING is a symbol that names a type of thing.  Interactively, the
symbol name is read: \"word\", \"sexp\", and so on.  See option
`thing-types' for more examples.

Put mark at the same place command `forward-'THING would put it with
the same prefix argument.

Put point at the beginning of THING, unless the prefix argument (ARG)
is negative, in which case put it at the end of THING.

Interactively:

You are prompted for THING.  Completion is available for the types of
thing in user option `thing-types', but you can enter any type.  The
default value is the first element of `thing-types'.

If `mark-thing' is repeated or if the mark is active (in Transient
Mark mode), then it marks the next ARG THINGs, after the ones already
marked.  The type of THING used is whatever was used the last time
`mark-thing' was called.

This region extension reusing the last type of THING happens even if
the active region is empty.  This means that you can, for instance,
just use `C-SPC' to activate an empty region and then use `mark-thing'
to select more THINGS of the last kind selected."
  (interactive "i\nP\np")               ; THING arg is nil (ignored) interactively.
  (let ((this-cmd  this-command)
        (last-cmd  last-command))
    (cond ((and allow-extend (or (and (eq last-cmd this-cmd) (mark t))
                                 (and transient-mark-mode mark-active)))
           (setq arg  (if arg
                          (prefix-numeric-value arg)
                        (if (< (mark) (point)) -1 1)))
           (set-mark (save-excursion
                       (goto-char (mark))
                       (forward-thing mark-thing-type arg)
                       (point))))
          (t
           (setq mark-thing-type
                 (or thing
                     (intern (prog1
                                 (let ((icicle-sort-function  nil))
                                   (completing-read "Type of thing: "
                                                    (mapcar #'list thing-types)
                                                    nil nil nil nil
                                                    (car thing-types)))
                               (setq this-command  this-cmd)))))
           (push-mark (save-excursion
                        (forward-thing mark-thing-type (prefix-numeric-value arg))
                        (point))
                      nil t)))
    (unless (memq this-cmd (list last-cmd 'cycle-thing-region))
      (forward-thing mark-thing-type (if (< (mark) (point)) 1 -1))))
  (setq deactivate-mark  nil))

;;;###autoload
(defun mark-enclosing-sexp (&optional arg allow-extend) ; `C-M-U'
  "Select a sexp surrounding the current cursor position.
If the mark is active (e.g. when the command is repeated), widen the
region to a sexp that encloses it.

The starting position is added to the mark ring before doing anything
else, so you can return to it (e.g. using `C-u C-SPC').

A prefix argument determines which enclosing sexp is selected: 1 means
the immediately enclosing sexp, 2 means the sexp immediately enclosing
that one, etc.

A negative prefix argument puts point at the beginning of the region
instead of the end.

In Lisp code, point is moved to (up-list ARG), and mark is at the
other end of the sexp.

This command does not work if point is in a string or a comment."
  (interactive "P\np")
  (cond ((and allow-extend
	      (or (and (eq last-command this-command) (mark t))
		  (and transient-mark-mode mark-active)))
	 (setq arg  (if arg (prefix-numeric-value arg)
                      (if (< (mark) (point)) 1 -1)))
	 (set-mark (save-excursion (up-list (- arg)) (point)))
         (up-list arg))
	(t
         (push-mark nil t)                     ; So user can get back.
	 (setq arg  (prefix-numeric-value arg))
         (push-mark (save-excursion (up-list (- arg)) (point)) nil t)
         (up-list arg))))

;;;###autoload
(defun mark-enclosing-sexp-forward (&optional arg) ; `C-M-F' or maybe `C-M-)'
  "`mark-enclosing-sexp' leaving point at region end."
  (interactive "P")
  (if (or (and (eq last-command this-command) (mark t))
		  (and transient-mark-mode mark-active))
      (mark-enclosing-sexp nil (prefix-numeric-value arg))
    (mark-enclosing-sexp (prefix-numeric-value arg) t)))

;;;###autoload
(defun mark-enclosing-sexp-backward (&optional arg) ; `C-M-B' or maybe `C-M-('
  "`mark-enclosing-sexp' leaving point at region start."
  (interactive "P")
  (if (or (and (eq last-command this-command) (mark t))
		  (and transient-mark-mode mark-active))
      (mark-enclosing-sexp nil (- (prefix-numeric-value arg)))
    (mark-enclosing-sexp (- (prefix-numeric-value arg)) t)))


;;;###autoload
(defun hide/show-comments (&optional hide/show start end)
  "Hide or show comments from START to END.
Interactively, hide comments, or show them if you use a prefix arg.
Interactively, START and END default to the region limits, if active.
Otherwise, including non-interactively, they default to `point-min'
and `point-max'.

Uses `save-excursion', restoring point.

Be aware that using this command to show invisible text shows *all*
such text, regardless of how it was hidden.  IOW, it does not just
show invisible text that you previously hid using this command.

From Lisp, a HIDE/SHOW value of `hide' hides comments.  Other values
show them.

This function does nothing in Emacs versions prior to Emacs 21,
because it needs `comment-search-forward'."
  (interactive
   (cons (if current-prefix-arg 'show 'hide)
         (if (or (not mark-active) (null (mark)) (= (point) (mark)))
             (list (point-min) (point-max))
           (if (< (point) (mark)) (list (point) (mark)) (list (mark) (point))))))
  (when (require 'newcomment nil t)     ; `comment-search-forward', Emacs 21+.
    (unless start (setq start  (point-min)))
    (unless end   (setq end    (point-max)))
    (unless (<= start end) (setq start  (prog1 end (setq end  start))))
    (let ((bufmodp           (buffer-modified-p))
          (buffer-read-only  nil)
          cbeg cend)
      (unwind-protect
           (save-excursion
             (goto-char start)
             (while (and (< start end) (setq cbeg  (comment-search-forward end 'NOERROR)))
               (setq cend  (if (string= "" comment-end)
                               (1+ (line-end-position))
                             (search-forward comment-end end 'NOERROR)))
               (when (and cbeg cend)
                 (if (eq 'hide hide/show)
                     (put-text-property cbeg cend 'invisible t)
                   (put-text-property cbeg cend 'invisible nil)))))
        (set-buffer-modified-p bufmodp)))))

(defvar last-visible-thing-type nil
  "Type of thing last used by `next-visible-thing', `previous-visibl-thing'.")

(defmacro with-comments-hidden (start end &rest body)
  "Evaluate the forms in BODY while comments are hidden from START to END.
But if `ignore-comments-flag' is nil, just evaluate BODY,
without hiding comments.  Show comments again when BODY is finished.

See `hide/show-comments', which is used to hide and show the comments.
Note that prior to Emacs 21, this never hides comments."
  (let ((result  (make-symbol "result"))
        (ostart  (make-symbol "ostart"))
        (oend    (make-symbol "oend")))
    `(let ((,ostart  ,start)
           (,oend    ,end)
           ,result)
      (unwind-protect
           (setq ,result  (progn (when ignore-comments-flag
                                   (hide/show-comments 'hide ,ostart ,oend))
                                 ,@body))
        (when ignore-comments-flag (hide/show-comments 'show ,ostart ,oend))
        ,result))))

;;;###autoload
(defun previous-visible-thing (thing start &optional end)
  "Same as `next-visible-thing', except it moves backward, not forward."
  (interactive (list (or (and (memq last-command '(next-visible-thing
                                                   previous-visible-thing))
                              last-visible-thing-type)
                         (if (or (not (boundp 'DO-NOT-USE-!@$%^&*+))
                                 (prog1 DO-NOT-USE-!@$%^&*+ (setq DO-NOT-USE-!@$%^&*+  nil)))
                             ;; Save state for `repeat'.
                             (let ((last-command-event       last-command-event)
                                   (last-repeatable-command  last-repeatable-command))
                               (intern (read-string "Thing: ")))
                           last-visible-thing-type))
                     (point)
                     (if mark-active (min (region-beginning) (region-end)) (point-min))))
  (if (interactive-p)
      (with-comments-hidden start end (next-visible-thing thing start end 'BACKWARD))
    (next-visible-thing thing start end 'BACKWARD)))

;;;###autoload
(defun next-visible-thing (thing &optional start end backward)
  "Go to the next visible THING.
Start at START.  If END is non-nil then look no farther than END.
Interactively:
 - START is point.
 - If the region is not active, END is the buffer end.  If the region
   is active, END is the region end: the greater of point and mark.

Ignores (skips) comments if `ignore-comments-flag' is non-nil.
If you also use Icicles then you can toggle this ignoring of comments,
using `C-M-;' in the minibuffer.

If you use this command or `previous-visible-thing' successively, even
mixing the two, you are prompted for the type of THING only the first
time.  You can thus bind these two commands to simple, repeatable
keys (e.g. `f11', `f12'), to navigate among things quickly.

If you do not want to sacrifice two simple, repeatable keys for this,
then you can instead use commands `next-visible-thing-repeat' and
`previous-visible-thing-repeat', binding them each to a less rare key
sequence that uses a prefix key.  Command `thgcmd-bind-keys' does
this: it binds them to `C-x down' and `C-x up', so you can repeat them
separately using `C-x down down...' etc.  However, unlike bindings for
`next-visible-thing' and `previous-visible-thing', switching from one
direction to the other requires you to again enter the THING type.

Non-interactively, optional arg BACKWARD means go to previous thing.

Return (THING THING-START . THING-END), with THING-START and THING-END
the bounds of THING.  Return nil if no such THING is found."
  (interactive (list (or (and (memq last-command '(next-visible-thing
                                                   previous-visible-thing))
                              last-visible-thing-type)
                         (if (or (not (boundp 'DO-NOT-USE-!@$%^&*+))
                                 (prog1 DO-NOT-USE-!@$%^&*+ (setq DO-NOT-USE-!@$%^&*+  nil)))
                             ;; Save state for `repeat'.
                             (let ((last-command-event       last-command-event)
                                   (last-repeatable-command  last-repeatable-command))
                               (intern (read-string "Thing: ")))
                           last-visible-thing-type))
                     (point)
                     (if mark-active (max (region-beginning) (region-end)) (point-max))))
  (setq last-visible-thing-type  thing)
  (unless start (setq start  (point)))
  (unless end   (setq end  (if backward (point-min) (point-max))))
  (cond ((< start end) (when backward (setq start  (prog1 end (setq end  start)))))
        ((> start end) (unless backward (setq start  (prog1 end (setq end  start))))))
  (if (interactive-p)
      (with-comments-hidden start end (next-visible-thing-1 thing start end backward))
    (next-visible-thing-1 thing start end backward)))

(defun next-visible-thing-1 (thing start end backward)
  "Helper for `next-visible-thing'.  Get thing past point."
  (let ((thg+bds  (next-visible-thing-2 thing start end backward)))
    (if (not thg+bds)
        nil
      ;; $$$$$$ Which is better, > or >=, for (> (cddr thg+bds) (point))?
      (while (and thg+bds  (if backward  (> (cddr thg+bds) (point))  (<= (cadr thg+bds) (point))))
        (if backward
            (setq start  (max end (1- (cadr thg+bds))))
          (setq start  (min end (1+ (cddr thg+bds)))))
        (setq thg+bds  (next-visible-thing-2 thing start end backward)))
      (when thg+bds (goto-char (cadr thg+bds)))
      thg+bds)))

(defun next-visible-thing-2 (thing start end &optional backward)
  "Helper for `next-visible-thing-1'.  Thing might not be past START."
  (and (not (= start end))
       (save-excursion
         (let ((bounds  nil))
           ;; If BACKWARD, swap START and END.
           (cond ((< start end) (when   backward (setq start  (prog1 end (setq end  start)))))
                 ((> start end) (unless backward (setq start  (prog1 end (setq end  start))))))
           (catch 'next-visible-thing-2
             (while (if backward (> start end) (< start end))
               (goto-char start)
               (when (and (if backward (> start end) (< start end))
                          (get-text-property start 'invisible))
                 (setq start  (if backward
                                  (previous-single-property-change start 'invisible nil end)
                                (next-single-property-change start 'invisible nil end)))
                 (goto-char start))
               (when (setq bounds  (bounds-of-thing-at-point thing))
                 (throw 'next-visible-thing-2
                   (cons (buffer-substring (car bounds) (cdr bounds)) bounds)))
               (setq start  (if backward (1- start) (1+ start))))
             nil)))))

(defun thgcmd-repeat-command (command)
  "Repeat COMMAND."
  (let ((repeat-message-function  'ignore))
    (setq last-repeatable-command  command)
    (repeat nil)))

;;;###autoload
(defun next-visible-thing-repeat () 
  "Go to and get the next visible THING.
This is a repeatable version of `next-visible-thing'."
  (interactive)
  (require 'repeat)
  (let ((DO-NOT-USE-!@$%^&*+  t))  (thgcmd-repeat-command 'next-visible-thing)))

;;;###autoload
(defun previous-visible-thing-repeat () 
  "Go to and get the previous visible THING.
This is a repeatable version of `previous-visible-thing'."
  (interactive)
  (require 'repeat)
  (let ((DO-NOT-USE-!@$%^&*+  t))  (thgcmd-repeat-command 'previous-visible-thing)))

;;;###autoload
(defun thgcmd-bind-keys (&optional msgp)
  "Bind some keys to commands defined in `thing-cmds.el'.
NOTE concerning the visible-thing navigation keys:

`C-x down' and `C-x up' are bound here (for Emacs 21 and later) to
`next-visible-thing-repeat' and `previous-visible-thing-repeat',
respectively.  This means you can use `C-x down down down...' etc. to
move forward to successive things, and similarly for `C-x up...' and
backward.  You are asked for the thing type only the first time you
hit `down' or `up' after `C-x'.

However, you cannot mix the directions forward/backward without
inputting the thing type again.  For example, If you do `C-x down up',
the `up' does not perform thing navigation (it probably does
`previous-line', the default `up' binding) .

To change direction without getting prompted for the thing type, you
need to bind, not commands `next-visible-thing-repeat' and
`previous-visible-thing-repeat', but commands `next-visible-thing' and
`previous-visible-thing' (no `-repeat' suffix).  Bind these to simple,
repeatable keys, such as `f11' and `f12'.  Because such keys are rare
\(mostly taken already), the only bindings made here for thing
navigation are `C-x down' and `C-x up'."
  (interactive "p")
  (when (or (not msgp) (y-or-n-p "Bind thing-command default keys?"))
    ;;   The first two replace the standard bindings for `mark-sexp' & `mark-word':
    (global-set-key [(control meta ? )] 'mark-thing) ; vs `mark-sexp'
    (global-set-key [(meta ?@)] 'cycle-thing-region) ; vs `mark-word'
    (global-set-key [(control meta shift ?u)] 'mark-enclosing-sexp)
    (global-set-key [(control meta shift ?b)] ; Alternative to consider: [(control meta ?()]
                    'mark-enclosing-sexp-backward)
    (global-set-key [(control meta shift ?f)] ; Alternative to consider: [(control meta ?))]
                    'mark-enclosing-sexp-forward)
    (when (> emacs-major-version 21)
      (define-key ctl-x-map [down]  'next-visible-thing-repeat)
      (define-key ctl-x-map [up]    'previous-visible-thing-repeat))
    (when msgp (message "Thing-command keys bound"))))

;;;;;;;;;;;;;;;;;;;;;;;;

(provide 'thing-cmds)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; thing-cmds.el ends here
