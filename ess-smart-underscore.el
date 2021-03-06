;;; ess-smart-underscore.el --- Ess Smart Underscore
;; 
;; Filename: ess-smart-underscore.el
;; Description: ess-smart-underscore
;; Author: Matthew L. Fidler
;; Maintainer: Matthew Fidler
;; Created: Thu Jul 14 11:04:42 2011 (-0500)
;; Version: 0.72
;; Last-Updated: Wed Aug  3 15:05:44 2011 (-0500)
;;           By: Matthew L. Fidler
;;     Update #: 114
;; URL: http://www.emacswiki.org/emacs/ess-smart-underscore.el
;; Keywords: ESS, underscore
;; Compatibility:
;; 
;; Features that might be required by this library:
;;
;;   None
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 
;;; Commentary: 
;; 
;;  To use, put (require 'ess-smart-underscore) in your ~/.emacs file
;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Change Log:
;; 03-Aug-2011    Matthew L. Fidler  
;;    Last-Updated: Wed Aug  3 15:05:15 2011 (-0500) #112 (Matthew L. Fidler)
;;    Bug fix for parenthetical statement
;; 20-Jul-2011    Matthew L. Fidler  
;;    Last-Updated: Wed Jul 20 15:20:10 2011 (-0500) #101 (Matthew L. Fidler)

;;    Changed to allow underscore instead of assign when inside a
;;    parenthetical statement.

;; 15-Jul-2011    Matthew L. Fidler
;;    Last-Updated: Fri Jul 15 11:34:52 2011 (-0500) #90 (Matthew L. Fidler)
;;    Bug fix for d[d$CMT == 2,"DV"] _ to produce d[d$CMT == 2,"DV"] <-
;; 
;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 3, or
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
(require 'ess)

(defcustom ess-S-underscore-after-$ t
  "Should underscore produce an underscore if it is an element of a list/data structure?

 Used by \\[ess-smart-underscore]."
 :group 'ess-S
 :type 'boolean)

(defcustom ess-S-underscore-after-defined t
  "Should underscore produce an underscore if it is after a variable has been defined?

 Used by \\[ess-smart-underscore]."
  :group 'ess-S
  :type 'boolean)

(defcustom ess-S-underscore-after-<-or-= t
  "Should underscore produce an underscore if it is after a \"<-\" or \"=\"?

 Used by \\[ess-smart-underscore]."
  :group 'ess-S
  :type 'boolean)

(defcustom ess-S-space-underscore-is-assignment t
  "Should underscore produce `ess-S-assign' when a space is right before the cursor.

Used by \\[ess-smart-underscore]."
  :group 'ess-S
  :type 'boolean)

(defcustom ess-S-underscore-when-inside-paren t
  "Should an underscore be produced instead of `ess-S-assign' when inside a parenthetical expression?"
  :group 'ess-S
  :type 'boolean)

;;;###autoload
(defun ess-smart-underscore ()
  "Smart \"_\" key: insert `ess-S-assign', unless:
  1. in string/comment
  2. after a $ (like d$one_two) (toggle with `ess-S-underscore-after-$')
  3. when the underscore is part of a variable definition previously defined.
     (toggle with `ess-S-underscore-after-defined')
  4. when the underscore is after a \"=\" or \"<-\" on the same line.
     (toggle with `ess-S-underscore-after-<-or-=')
  5. inside a parenthetical statement () or [].
     (toggle with `ess-S-underscore-when-inside-paren')

An exception to #4 is in the following situation:

a <- b |

pressing an underscore here would produce

a <- b <-

However when in the following situation

a <- b|

pressing an underscore would produce

a <- b_

This behavior can be toggled by `ess-S-space-underscore-is-assignment'

If the underscore key is pressed a second time, the assignment
operator is removed and replaced by the underscore.  `ess-S-assign',
typically \" <- \", can be customized.  In ESS modes other than R/S,
an underscore is always inserted. "
  (interactive)
  ;;(insert (if (ess-inside-string-or-comment-p (point)) "_" ess-S-assign))
  (if (or
       (not (equal ess-language "S"))
       (ess-inside-string-or-comment-p (point))
       ;; Data
       (and ess-S-underscore-after-$ (save-match-data (save-excursion (re-search-backward "\\([$]\\)[A-Za-z0-9.]+\\=" nil t))))
       (and ess-S-underscore-after-<-or-=
	    (let ((ret (save-match-data (and (not (looking-back ess-S-assign))
					     (looking-back "\\(<-\\|\\<=\\>\\).*")))))
              (if (and ret ess-S-space-underscore-is-assignment
                       (looking-back "[ \t]"))
                  (setq ret nil))
	      (symbol-value 'ret)))
       ;; Look for variable
       (and ess-S-underscore-after-defined
            (not (looking-back ess-S-assign)) ; Hack to fix bug
	    (save-match-data
	      (save-excursion
		(let (word)
		  (when (looking-back "\\<[A-Za-z0-9.]+[ \t]*")
		    (setq word (match-string 0))
		    (setq ret
			  (or (re-search-backward (format "^[ \t]*%s_[A-Za-z0-9.]*[ \t]*\\(<-\\|=\\)" word) nil t)
			      (re-search-backward (format "->[ \t]*%s_[A-Za-z0-9.]*[ \t]*$" word) nil t)))
		    (symbol-value 'ret))))))
       (and ess-S-underscore-when-inside-paren
	    (save-match-data
	      (save-excursion
		(let ((pt (point))
		      ret)
		  (when (re-search-backward "\\((\\|\\[\\).*\\=" nil t)
		    (forward-sexp)
		    (when (> (point) pt)
		      (setq ret t)))
		  (symbol-value 'ret))))))
      (insert "_")
    ;; Else one keypress produces ess-S-assign; a second keypress will delete
    ;; ess-S-assign and instead insert _
    ;; Rather than trying to count a second _ keypress, just check whether
    ;; the current point is preceded by ess-S-assign.
    (let ((assign-len (length ess-S-assign)))
      (if (and
	   (>= (point) (+ assign-len (point-min))) ;check that we can move back
	   (looking-back ess-S-assign))
	  ;; If we are currently looking at ess-S-assign, replace it with _
	  (progn
	    (replace-match "")
	    (insert "_"))
	(delete-horizontal-space)
	(insert ess-S-assign)))))

;;;###autoload
(add-hook 'ess-mode-hook
          '(lambda ()
             (require 'ess-smart-underscore)))

(provide 'ess-smart-underscore)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; ess-smart-underscore.el ends here
