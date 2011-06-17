;;; fill-column-indicator.el --- graphically indicate the fill column

;; Copyright (c) 2011 Alp Aker

;; Author: Alp Aker <alp.tekin.aker@gmail.com>
;; Version: 1.53
;; Keywords: convenience

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 2 of the
;; License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; A copy of the GNU General Public License can be obtained from the
;; Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
;; MA 02111-1307 USA

;;; Commentary:

;; Many modern editors and IDEs can graphically indicate the location of the
;; fill column by drawing a thin line (in design parlance, a `rule') down the
;; length of the editing window.  Fill-column-indicator implements this
;; facility in Emacs.

;; Installation and Usage
;; ======================

;; Put this file in your load path and put
;;
;;   (require 'fill-column-indicator)
;;
;; in your .emacs.

;; To toggle graphical indication of the fill column in a buffer, use the
;; command `fci-mode'.

;; Configuration
;; =============

;; The color of the fill-column rule is controlled by the variable
;; `fci-rule-color'.  Its value can be any valid color name.  If nil (the
;; default value), fci-mode tries to select an appropriate color
;; automatically.

;; On graphical displays, the rule is drawn using a bitmap image generated by
;; fci-mode.  The rule's width (in pixels) is determined by the variable
;; `fci-rule-width'.  The default value is 2.

;; On character terminals the rule is drawn using the character specified by
;; `fci-rule-character'; the default is `|' (ascii 124).  If you'd like the
;; rule to be drawn using fci-rule-character even on graphical displays, set
;; `fci-always-use-textual-rule' to a non-nil value.

;; The image formats used by fci-mode are XPM, PBM, and XBM.  By default, it
;; uses XPM images if Emacs has been compiled with the appropriate library;
;; if not, it uses PBM images, which are natively supported.  You can specify
;; a particular format by setting `fci-rule-image-format' to either 'xpm,
;; 'xpm, or 'xbm.

;; Other Options
;; =============

;; When `truncate-lines' is nil, the effect of drawing a fill-column
;; indicator is very odd looking. Indeed, in a window with continuation
;; lines, it makes little sense to indicate the position of the fill column
;; relative to the window edge (think about what it would mean to talk about
;; "the" location of the fill column in that case).  For this reason,
;; fci-mode sets truncate-lines to t in buffers in which it is enabled and
;; restores it to its previous value when disabled.  You can turn this
;; feature off by setting `fci-handle-truncate-lines' to nil.

;; If `line-move-visual' is t, then vertical navigation can behave oddly in
;; several edge cases while fci-mode is enabled (this is due to a bug in C
;; code).  Accordingly, fci-mode locally sets line-move-visual to nil when
;; enabled and restores it when disabled.  This can be suppressed by setting
;; `fci-handle-line-move-visual' to nil.  (But you shouldn't want to do
;; this.  There's no reason to use line-move-visual if truncate-lines is t,
;; and it doesn't make sense to use something like fci-mode when
;; truncate-lines is nil.)

;; Troubleshooting
;; ===============

;; o If the fill-column rule is misaligned on some lines but otherwise looks
;;   normal, then you're most likely not displaying the buffer contents with
;;   a monospaced font.  Check whether the lines in question contain
;;   non-ascii characters that are wider or shorter than the normal character
;;   width.  Also, be aware that certain font-lock themes set some faces so
;;   that they look monospaced but aren't quite so.

;; o Although the XBM format is natively supported by Emacs, the
;;   implementation on some ports is incomplete; the v23 and v24 Mac OS X
;;   ports are examples.  On these systems XBM images are always drawn in
;;   black, in which case one cannot control the color of the rule.  Use XPM
;;   or PBM images instead.

;; o Fci-mode needs free use of two characters (specifically, it needs the
;;   use of two characters whose display table entries it can change
;;   arbitrarily).  By default, it uses the first two characters of the
;;   Private Use Area of the Unicode BMP, viz. U+E000 and U+E001.  If you
;;   need to use those characters for some reason, set `fci-padding-char' and
;;   `fci-eol-char' to different values.

;; Known Issues
;; ============

;; o The indicator extends only to end of the buffer contents (as opposed to
;;   running the full length of the editing window).

;; o When portions of a buffer are invisible, such as when outline mode is
;;   used to hide certain lines, the fill-column rule is hidden as
;;   well.  (Working around this would require either (a) rewriting a large
;;   part of xdisp.c, or (b) advising every function that might hide part of
;;   a buffer.)

;; o Fci-mode is generally fast:  Displaying the rule should be O(n) in the
;;   number of lines in a buffer, with a low constant.  (Activating the mode
;;   in a buffer with 30k lines should take under 0.5 sec on a modern
;;   machine.)  However, the presence of multibyte characters can slow down
;;   its performance, in proportion to the number of multibyte characters in
;;   the buffer.  (This problem stems from the fact that the performance of
;;   the primitive overlay commands is degraded by multibyte characters.)

;; o An issue specifc to the Mac OS X (NextStep) port, versions 23.0-23.2: On
;;   graphical displays, the cursor will disappear when positioned directly
;;   on top of the fill-column rule (i.e., when it is positioned at the end
;;   of a line that extends up to but not past the fill-column).  The best
;;   way to deal with this is to upgrade to 23.3 or to 24 (or downgrade to
;;   22).  If that isn't practical, a fix is available via the mini-package
;;   fci-osx-23-fix.el, which can be downloaded from either:
;;
;;     github.com/alpaker/Fill-Column-Indicator
;;
;;   or
;;
;;     emacswiki.org/emacs/FillColumnIndicator
;;
;;  Directions for its use are given in the file header.

;; Todo
;; ====

;; o Accomodate non-nil values of `hl-line-sticky-flag' and similar cases.

;;; Code:

;;; ---------------------------------------------------------------------
;;; Version Specifics
;;; ---------------------------------------------------------------------

(unless (< 21 emacs-major-version)
  (error "Fill-column-indicator requires version 22 or later"))

;; Needed for v22.
(if (fboundp 'characterp)
    (defalias 'fci-character-p 'characterp)
  (defun fci-character-p (c)
    (and (wholenump c)
         (/= 0 c)
         (<= c #x3FFFFF))))

;; Needed for v22.
(if (fboundp 'daemonp)
    (defalias 'fci-daemon-p 'daemonp)
  (defun fci-daemon-p ()
    nil))

;;; ---------------------------------------------------------------------
;;; User Options
;;; ---------------------------------------------------------------------

(defgroup fill-column-indicator nil
 "Graphically indicate the fill-column."
 :tag "Fill-Column Indicator"
 :group 'convenience
 :group 'fill)

(defcustom fci-rule-color nil
 "Color used to draw the fill-column rule.
If nil, fill-column-indicator tries to make a sensible choice.

Changes to this variable do not take effect until the mode
function `fci-mode' is run."
 :group 'fill-column-indicator
 :tag "Fill-column rule color"
 :type '(choice (const :tag "Let fci-mode choose" nil)
                (color :tag "Specify a color")))

;; We should be using :validate instead of :match, but that seems not to
;; work with defcustom widgets.
(defcustom fci-rule-width 2
  "Width, in pixels, of the fill-column rule on graphical displays.
The value must be less than the default character width of the 
selected frame.

Changes to this variable do not take effect until the mode
function `fci-mode' is run."
  :tag "Fill-Column Rule Width"
  :group 'fill-column-indicator
  :type  '(integer :match (lambda (w val) (<= val (frame-char-width)))))

;; PBM images are natively supported, so this should be safe.
(defcustom fci-rule-image-format
  (if (image-type-available-p 'xpm) 'xpm 'pbm)
  "Image format used for the fill-column rule on graphical displays.

Changes to this variable do not take effect until the mode
function `fci-mode' is run."
  :tag "Fill-Column Rule Image Format"
  :group 'fill-column-indicator
  :type '(choice (symbol :tag "XPM" 'xpm)
                 (symbol :tag "PBM" 'pbm)
                 (symbol :tag "XBM" 'xbm)))

(defcustom fci-rule-character ?|
  "Character use to draw the fill-column rule on character terminals.
This is also used when the chosen image format isn't supported.

Changes to this variable do not take effect until the mode
function `fci-mode' is run."
  :tag "Fill-Column Rule Character"
  :group 'fill-column-indicator
  :type 'character)

(defcustom fci-always-use-textual-rule nil
  "When non-nil, the rule is always drawn using textual characters.
Specifically, fci-mode will use `fci-rule-character' intead of
bitmap images to draw the rule on graphical displays.

Changes to this variable do not take effect until the mode
function `fci-mode' is run."
  :tag "Don't Use Image for Fill-Column Rule"
  :group 'fill-column-indicator
  :type 'boolean)

(defcustom fci-handle-line-move-visual (< 22 emacs-major-version)
 "Whether fci-mode should set line-move-visual to nil while enabled.
If non-nil, fci-mode will set line-move-visual to nil in buffers
in which it is enabled, and restore t to its previous value when
disabled.

Leaving this option set to the default value is recommended."
 :group 'fill-column-indicator
 :tag "Locally set line-move-visual to nil during fci-mode"
 :type 'boolean)

(defcustom fci-handle-truncate-lines t
 "Whether fci-mode should set truncate-lines to t while enabled.
If non-nil, fci-mode will set truncate-lines to t in buffers in
which it is enabled, and restore it to its previous value when
disabled.

Leaving this option set to the default value is recommended."
 :group 'fill-column-indicator
 :tag "Locally set truncate-lines to t during fci-mode"
 :type 'boolean)

;;; ---------------------------------------------------------------------
;;; Internal Variables and Constants
;;; ---------------------------------------------------------------------

;; Stores the value of fill-column so we can detect changes to it.
(defvar fci-column nil)

;; Stores the display table entry for the newline character so we can detect
;; changes to it.
(defvar fci-newline-sentinel nil)

;; Stores the value of tab-width so we can detect changes to it.
(defvar fci-tab-width nil)

;; If we nix line-move-visual in a buffer, we save its prior state here.
(defvar fci-saved-line-move-visual nil)

;; If we turn on truncate-lines in a buffer, we save its prior state here.
(defvar fci-saved-truncate-lines nil)

;; If we change the display table entry for newlines, we save its prior state
;; here.
(defvar fci-saved-eol nil)

;; Flag recording whether fci-mode created a new display table in a buffer.
(defvar fci-made-display-table nil)

;; Flag recording whether the display table has been analyzed already.
(defvar fci-dt-processed nil)

;; Flag recording whether hooks, etc. have been set in this buffer.
(defvar fci-local-vars-set nil)

;; Flag recording whether initialization in this buffer took place on a
;; character terminal used by an Emacs instance running in daemon mode.  If
;; the same instance then displays the same buffer on a window frame, we need
;; to regenerate the rule.
(defvar fci-daemon-init-on-tty nil)

;; Column that demarcates the transition from padding to rule (usually but
;; not always equal to fill-column).
(defvar fci-limit nil)

;; Overlay before string used for newlines that fall before fci-limit.
(defvar fci-pre-limit-string nil)

;; Overlay before string used for newlines that fall at fci-limit.
(defvar fci-at-limit-string nil)

;; Overlay before string used for newlines that fall at fci-limit.
(defvar fci-post-limit-string nil)

;; The preceding internal variables need to be buffer local.
(dolist (var '(fci-column
               fci-newline-sentinel
               fci-tab-width
               fci-saved-line-move-visual
               fci-saved-truncate-lines
               fci-saved-eol
               fci-made-display-table
               fci-dt-processed
               fci-local-vars-set
               fci-daemon-init-on-tty
               fci-limit
               fci-pre-limit-string
               fci-at-limit-string
               fci-post-limit-string))
  (make-variable-buffer-local var))

;; Character used for "fake" eol indications when fci-mode is running
;; concurrently with a mode that sets the display-table entry for newlines to
;; non-nil (typically whitespace mode).  This character is the first
;; character in the Private Use Area of the Unicode BMP.  On v22, given in
;; mule-unicode encording; on later versions, given in utf-8.
(defconst fci-eol-char (if (= 22 emacs-major-version) 315425 #xE000))

;; Character used to create the appearance whitespace in certain edge cases
;; without being treated syntactically as whitespace by, e.g., whitespace
;; mode.  On v22, given in mule-unicode encording; on later versions, given
;; in utf-8.
(defconst fci-padding-char (if (= 22 emacs-major-version) 315426 #xE001))

;; The display spec used in overlay before strings to pad out the rule to the
;; fill-column.
(defconst fci-padding-display
  '((when (fci-overlay-check buffer-position)
      . (space :align-to fci-column))
    (space :width 0)))

;; Hooks we add to.
(defconst fci-hook-assignments
  (append `((after-change-functions . ,#'fci-after-change-function)
            (post-command-hook . ,#'fci-post-command-check)
            (change-major-mode-hook . ,#'(lambda () (fci-mode -1))))))

;;; ---------------------------------------------------------------------
;;; Mode Definition
;;; ---------------------------------------------------------------------

(define-minor-mode fci-mode
  "Toggle fci mode on and off.
Fci-mode indicates the location of the fill column, either by
shading the area of the window past the fill column or by
drawing a thin line (a `rule') at the fill column.

With prefix ARG, turn fci-mode on if and only if ARG is positive.

The following options control the appearance of the fill-column
indicator: ``fci-rule-width', `fci-rule-color', and
`fci-rule-character'.  For further options, see the Customization
menu or the package file.  (See the latter for tips on
troubleshooting.)"

  nil nil nil

  (if fci-mode
  ;; Enabling.
  (progn
    (fci-process-display-table)
    (setq fci-column fill-column
          fci-tab-width tab-width
          fci-limit (if fci-newline-sentinel
                        (1+ (- fill-column (length fci-saved-eol)))
                      fill-column))
    (fci-make-before-strings)
    ;; In case we were already in fci-mode and are resetting the
    ;; indicator, clear out any existing overlays.
    (when fci-local-vars-set
      (fci-delete-overlays-buffer))
    (fci-set-local-vars)
    (fci-put-overlays-buffer))

  ;; Disabling.
  (fci-delete-overlays-buffer)
  (fci-restore-display-table)
  (fci-restore-local-vars)
  (setq fci-column nil
        fci-limit nil
        fci-tab-width nil
        fci-pre-limit-string nil
        fci-at-limit-string nil
        fci-post-limit-string nil)))

;;; ---------------------------------------------------------------------
;;; Initialization and Clean Up: Display Table
;;; ---------------------------------------------------------------------

(defun fci-process-display-table ()
  (unless fci-dt-processed
    (unless buffer-display-table
      (setq buffer-display-table (make-display-table)
            fci-made-display-table t))
    (aset buffer-display-table fci-padding-char [32])
    (setq fci-saved-eol (aref buffer-display-table 10))
    ;; Assumption: the display-table entry for character 10 is either nil or
    ;; a vector whose last element is the newline glyph.
    (let ((glyphs (butlast (append fci-saved-eol nil)))
          eol)
      (if glyphs
          (setq fci-newline-sentinel [10]
                eol (vconcat glyphs))
        (setq fci-newline-sentinel nil
              eol [32]))
      (aset buffer-display-table 10 fci-newline-sentinel)
      (aset buffer-display-table fci-eol-char eol))
    (setq fci-dt-processed t)))

(defun fci-restore-display-table ()
  (aset buffer-display-table 10 fci-saved-eol)
  ;; Don't set buffer-display-table to nil even if we created it; only do so
  ;; if it's also empty.
  (when (and fci-made-display-table
             (equal buffer-display-table (make-display-table)))
    (setq buffer-display-table nil))
  (setq fci-dt-processed nil
        fci-made-display-table nil
        fci-newline-sentinel nil
        fci-saved-eol nil))

;;; ---------------------------------------------------------------------
;;; Initialization and Clean Up: Hooks and Other Variables
;;; ---------------------------------------------------------------------

(defun fci-set-local-vars ()
  (unless fci-local-vars-set
    (dolist (hook fci-hook-assignments)
      (add-hook (car hook) (cdr hook) nil t))
     (when (and fci-handle-line-move-visual
                (boundp 'line-move-visual))
       (setq fci-saved-line-move-visual line-move-visual)
       (set (make-local-variable 'line-move-visual) nil))
    (when fci-handle-truncate-lines
      (setq fci-saved-truncate-lines truncate-lines)
      (set (make-local-variable 'truncate-lines) t))
    (when (and (fci-daemon-p) (not (display-graphic-p)))
      (setq fci-daemon-init-on-tty t))
    (setq fci-local-vars-set t)))

(defun fci-restore-local-vars ()
  (dolist (hook fci-hook-assignments)
    (remove-hook (car hook) (cdr hook) t))
  (when (and fci-handle-line-move-visual
             (boundp 'line-move-visual))
    (setq line-move-visual fci-saved-line-move-visual
          fci-saved-line-move-visual nil))
  (when fci-handle-truncate-lines
    (setq truncate-lines fci-saved-truncate-lines
          fci-saved-truncate-lines nil))
  (setq fci-local-vars-set nil
        fci-daemon-init-on-tty nil))

;;; ---------------------------------------------------------------------
;;; Initialization:  Overlay Strings for Padding and Rule
;;; ---------------------------------------------------------------------

(defun fci-eol-display (blank eol)
  (propertize blank 'display (propertize eol 'cursor 1)))

(defun fci-overlay-check (pos)
  (not (memq t (mapcar #'(lambda (x)
                           (and (not (overlay-get x 'fci))
                                (overlay-get x 'face)
                                (not (eq (face-attribute
                                          (overlay-get x 'face)
                                          :background nil t)
                                         'unspecified))))
                       (overlays-at pos)))))

(defun fci-rule-display (blank spec str pre)
  (let ((cursor (if (and (not pre) (not fci-newline-sentinel)) 1)))
    (propertize blank
                'cursor cursor
                'display
                (if spec
                    `((when (and (not (display-images-p)) 
                                 (fci-overlay-check buffer-position))
                        . ,(propertize str 'cursor cursor))
                      (when (fci-overlay-check buffer-position)
                        . ,spec)
                      (space :width 0))
                  `((when (fci-overlay-check buffer-position)
                      . ,(propertize str 'cursor cursor))
                    (space :width 0))))))

(defun fci-make-before-strings ()
  (let* ((color (fci-get-rule-color))
         (rule-str (fci-make-rule-string color))
         (rule-spec (fci-make-rule-spec fci-rule-width color))
         (blank (char-to-string fci-padding-char))
         (end-cap (propertize blank 'display '(space :width 0)))
         (eol (fci-eol-display blank (char-to-string fci-eol-char)))
         (padding (propertize blank 'display fci-padding-display))
         (before-rule (fci-rule-display blank rule-spec rule-str nil))
         (at-rule (fci-rule-display blank rule-spec rule-str fci-newline-sentinel))
         (at-eol (if fci-newline-sentinel eol "")))
    (setq fci-pre-limit-string (concat eol padding before-rule end-cap)
          fci-at-limit-string (concat at-eol padding at-rule end-cap)
          fci-post-limit-string (concat eol end-cap))))

;;; ---------------------------------------------------------------------
;;; Initialization:  Create Rule Bitmap and Propertize Rule String
;;; ---------------------------------------------------------------------

(defun fci-make-rule-string (color)
  (if (fci-character-p fci-rule-character)
      (propertize (char-to-string fci-rule-character)
                  'face
                  ;; Make sure we don't pick up weight or slant from font-lock.
                  `(:foreground ,color :weight normal :slant normal))
    (fci-mode -1)
    (error "Value of `fci-rule-character' must be a character")))

(defun fci-make-rule-spec (rule-width color)
  (cond
   ((or (not (display-images-p)) fci-always-use-textual-rule)
    nil)
   ((eq fci-rule-image-format 'xbm)
    (fci-make-xbm-spec rule-width color))
   ((eq fci-rule-image-format 'pbm)
    (fci-make-pbm-spec rule-width color))
   ((eq fci-rule-image-format 'xpm)
    (fci-make-xpm-spec rule-width color))
   (t
    (fci-mode -1)
    (error "Unrecognized value of `fci-rule-image-format'"))))

(defun fci-get-rule-color ()
  (let ((light-bg (eq (frame-parameter (selected-frame) 'background-mode)
                      'light))
        (grays (display-grayscale-p))
        (planes (display-planes))
        (color (display-color-p)))
    (cond
     ((and light-bg grays) "#cccccc")
     ((and (not light-bg) grays) "#7f7f7f")
     ((and color (> 3 planes)) "lightgray")
     ((and color (> 2 planes)) "yellow")
     (light-bg "black")
     (t "white"))))

;; The following three functions each create an image descriptor for the rule
;; bitmap.

(defun fci-make-xbm-spec (rule-width color)
  (let* ((fcw (frame-char-width))
         (img-width (+ fcw (- 8 (% fcw 8))))
         (img-height (frame-char-height))
         (row-pixels (make-bool-vector img-width nil))
         (raster (make-vector img-height row-pixels))
         (left-margin (/ (- fcw rule-width) 2)))
    (dotimes (i rule-width)
      (aset row-pixels (+ i left-margin) t))
    `(image :type xbm
            :data ,raster
            :foreground ,color
            :mask heuristic
            :ascent center
            :height ,img-height
            :width ,img-width)))

(defun fci-make-pbm-spec (rule-width color)
  (let* ((img-height (frame-char-height))
         (img-height-str (number-to-string img-height))
         (img-width (frame-char-width))
         (img-width-str (number-to-string img-width))
         (margin (/ (- img-width rule-width) 2.0))
         (left-margin (floor margin))
         (right-margin (ceiling margin))
         (identifier "P1\n")
         (dimens (concat img-width-str " " img-height-str "\n"))
         (left-pixels (mapconcat #'identity (make-list left-margin "0") " "))
         (rule-pixels (mapconcat #'identity (make-list rule-width "1") " "))
         (right-pixels (mapconcat #'identity (make-list right-margin "0") " "))
         (row-pixels (concat left-pixels " " rule-pixels " " right-pixels))
         (raster (mapconcat #'identity (make-list img-height row-pixels) "\n"))
         (data (concat identifier dimens raster)))
    `(image :type pbm
            :data ,data
            :mask heuristic
            :foreground ,color
            :ascent center)))

(defun fci-make-xpm-spec (rule-width color)
  (let* ((img-height  (frame-char-height))
         (img-height-str (number-to-string img-height))
         (img-width (frame-char-width))
         (img-width-str (number-to-string img-width))
         (margin (/ (- img-width rule-width) 2.0))
         (left-margin (floor margin))
         (right-margin (ceiling margin))
         (identifier "/* XPM */\nstatic char *rule[] = {\n")
         (dimens (concat "\"" img-width-str " " img-height-str " 2 1\",\n"))
         (color-spec (concat "\"1 c " color "\",\n \"0 c None\",\n"))
         (row-pixels (concat "\""
                             (make-string left-margin ?0)
                             (make-string rule-width ?1)
                             (make-string right-margin ?0)
                             "\",\n"))
         (raster (mapconcat #'identity (make-list img-height row-pixels) ""))
         (end "};")
         (data (concat identifier dimens color-spec raster end)))
    `(image :type xpm
            :data ,data
            :ascent center)))

;;; ---------------------------------------------------------------------
;;; Core Drawing/Undrawing Functions
;;; ---------------------------------------------------------------------

(defun fci-delete-overlays-region (start end)
  (mapc #'(lambda (o) (if (overlay-get o 'fci) (delete-overlay o)))
        (overlays-in start end)))

(defun fci-put-overlays-region (start end)
  (goto-char start)
  (let (o cc)
    (while (search-forward "\n" end t)
      (goto-char (match-beginning 0))
      (setq cc (current-column))
      (setq o (make-overlay (match-beginning 0) (match-beginning 0)))
      (overlay-put o 'fci t)
      (cond 
       ((< cc fci-limit)
        (overlay-put o 'before-string fci-pre-limit-string))
       ((= cc fci-limit)
        (overlay-put o 'before-string fci-at-limit-string))
        (t
         (overlay-put o 'before-string fci-post-limit-string)))
      (goto-char (match-end 0)))))

(defun fci-get-col (pos)
  (save-excursion
    (goto-char pos)
    (current-column)))

;;; ---------------------------------------------------------------------
;;; Entry Points to Drawing/Undrawing
;;; ---------------------------------------------------------------------

(defmacro fci-sanitize-actions (&rest body)
  `(save-match-data
     (save-excursion
       (save-restriction
         (widen)
         ,@body))))

;; The main entry point.  This is put in after-change-functions and locally
;; redraws the indicator after each buffer change.  Note that we redraw an
;; extra preceding line.  Motivation: at the beginning of a line,
;; insert-before-markers will grab the end marker of the overlay on the
;; previous line, in which case we need to reset the previous line's overlay
;; as well.  Unconditionally redoing the previous line is the fastest way to
;; handle that case.  (Using a hook on the overlay is conceptually tidier
;; but incurs the overhead of multiple extra Lisp function calls.)
(defun fci-after-change-function (start end unused)
  (fci-sanitize-actions
   ;; Make sure our bounds span at least whole lines.
   (goto-char start)
   (setq start (line-beginning-position 0))
   (goto-char end)
   (setq end (line-beginning-position 2))
   ;; Clear any existing overlays.
   (fci-delete-overlays-region start end)
   ;; Then set the fill-column indicator in that region.
   (fci-put-overlays-region start end)))

(defun fci-put-overlays-buffer ()
  (fci-sanitize-actions
   (overlay-recenter (point-min))
   (fci-put-overlays-region (point-min) (point-max))))

(defun fci-delete-overlays-buffer ()
  (save-restriction
    (widen)
    (overlay-recenter (point-max))
    (fci-delete-overlays-region (point-min) (point-max))))

;;; ---------------------------------------------------------------------
;;; Workarounds
;;; ---------------------------------------------------------------------

(defadvice vertical-motion (around fci)
  (if fci-mode
      (let (truncate-lines)
        ad-do-it)
    ad-do-it))

(ad-activate 'vertical-motion)

(defun fci-post-command-check ()
  (cond
   ((and fci-daemon-init-on-tty (display-graphic-p))
    (setq fci-daemon-init-on-tty nil)
    (fci-mode 1))
   ((or (null buffer-display-table)
        (not (equal (aref buffer-display-table 10) fci-newline-sentinel)))
    (setq fci-dt-processed nil)
    (fci-mode 1))
   ((or (not (= fill-column fci-column))
        (not (= tab-width fci-tab-width)))
    (fci-mode 1))
   ((and (< 0 (window-hscroll))
         auto-hscroll-mode
         (<= (current-column) (window-hscroll)))
    ;; Fix me:  Rather than setting hscroll to 0, this should reproduce the
    ;; relevant part of the auto-hscrolling algorithm.  Most people won't
    ;; notice the difference in behavior, though.
    (set-window-hscroll (selected-window) 0))))

(provide 'fill-column-indicator)

;;; fill-column-indicator.el ends here
