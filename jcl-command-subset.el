;;; jcl-command-subset.el --- Like M-x but with only a subset of commands.

;; Copyright (C) 2011 Johan Claesson
;; Author: Johan Claesson <johan.claesson@ericsson.com>
;; Keywords: menu
;; Created:    <2008-11-10>
;; Time-stamp: <2011-10-23 20:03:55 jcl>
;; Compatibility: GNU Emacs 23

;;; Commentary:

;; When hitting M-x there is a bazillion of commands to choose from.
;; With jcl-define-command-subset one can create a command that works
;; like M-x but the completion only consider a subset of available
;; commands.  Which commands are part of that subset is determined by
;; a regex passed to jcl-define-command-subset.

;; Example usage:

;; ;; Define a subset with all commands that starts with "jcl-".
;; (jcl-define-command-subset jcl-command-subset "M-z " "^jcl-" "jcl-")
;; 
;; ;; Define a subset with all commands which have the string "toggle"
;; ;; in their name.
;; (jcl-define-command-subset jcl-toggle-command-subset "M-Z " "toggle")
;; 
;; ;; Define a subset with all monkey related commands.
;; (jcl-define-command-subset jcl-monkey-command-subset
;;                            "Select monkey business: "
;;                            "monkey\\|ape\\|chimp\\|gorilla")
;; 
;; (define-key global-map [(meta ?z)] 'jcl-command-subset)
;; (define-key global-map [(meta ?Z)] 'jcl-toggle-command-subset)
;; (defalias 'monkey 'jcl-monkey-command-subset)
;;
;; (jcl-command-subset-setup)


;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Code:


(eval-when-compile
  (require 'cl))

(require 'ido)
(require 'advice)



(defvar jcl-command-subset-alist ()
  "List of defined command subsets.
Each element have the form (list-variable . regex).
Use `jcl-define-command-subset' to add to this list.")

(defvar jcl-consecutive-calls-lambda-alist ())




(defmacro jcl-define-command-subset (symbol prompt regex &optional initial-input)
  "Define a command subset.

A command SYMBOL will be defined.  This command will enter the
minibuffer and let the user select a command in the subset.  It
will be read using `ido-completing-read' with the prompt PROMPT.
All commands that matches the REGEX will be part of the command
subset.

Argument INITIAL-INPUT is a string that will be passed to
`ido-completing-read'.

If the created command is called 2 times in a row then the list
of commands will be updated.

If the command is called 3 times in a row it will display a list
of all the commands in the subset along with their documentation."
  (let* ((name (symbol-name symbol))
         (history (intern (concat name "-history")))
         (doc-command (intern (concat name "-doc")))
         (post-function (intern (concat name "-post"))))
    `(progn
       (add-to-list 'jcl-command-subset-alist '(,symbol . ,regex))
       (defvar ,symbol (when after-init-time
                         (jcl-compile-command-subset ,regex)))
       (defvar ,history nil)
       (defun ,symbol ()
         "Command subset command created by `jcl-define-command-subset'.

Call this command 2 times in a row and the the list
of commands will be updated.

Call this command 3 times in a row and it will display a list of
all the commands in the subset along with their documentation."
         (interactive)
         (case (jcl-consecutive-calls)
           (1 (let ((cmd (let ((ido-confirm-unique-completion t)
                               ;; During ido-completing-read the local map
                               ;; ido-completion-map is active.  If this command
                               ;; was bound only to a local map it will not be
                               ;; in ido-completion-map.  Therefore temporarily
                               ;; bind this command.  Note that
                               ;; ido-completion-map is rebuilt for every call
                               ;; to ido-completing-read.  Therefore do the
                               ;; rebind in ido-setup-hook.
                               ;; (Must assign ido-setup-hook in a
                               ;; separate let in case cmd in turn
                               ;; will call ido-something.)
                               (ido-setup-hook (cons (lambda ()
                                                       (define-key ido-completion-map
                                                         [??] ',doc-command)
                                                       (define-key ido-completion-map
                                                         (this-command-keys-vector) ',symbol))
                                                     ido-setup-hook)))
                           (intern-soft (ido-completing-read ,prompt
                                                             ,symbol
                                                             nil
                                                             nil
                                                             ,initial-input
                                                             ,history)))))
                (and cmd
                     (commandp cmd)
                     (setq this-command cmd)
                     (call-interactively cmd))))
           (2 (progn
                (message "Rebuilding command subset %s" ,name)
                (setq ,symbol (jcl-compile-command-subset ,regex))
                (message "Rebuilding command subset %s...found %s commands"
                         ,name
                         (length ,symbol))
                (setq ido-matches nil
                      ido-exit 'done)
                (exit-minibuffer)))
           (3 (let ((inside-minibuffer-p (minibufferp (current-buffer))))
                (,doc-command)
                (when inside-minibuffer-p
                  ;; Called from inside ido-completing-read.
                  ;; Exit from minibuffer will restore windows.
                  ;; Install temporary hook that goes to created window.
                  (add-hook 'post-command-hook
                            (defun ,post-function ()
                              (switch-to-buffer "*Command Subset*")
                              (remove-hook 'post-command-hook
                                           ',post-function)))
                  (setq ido-matches nil
                        ido-exit 'done)
                  (exit-minibuffer))))))
       (defun ,doc-command ()
         (interactive)
         (let ((inside-minibuffer-p (minibufferp (current-buffer))))
           (switch-to-buffer "*Command Subset*")
           (erase-buffer)
           (insert "Commands in " ,name ":\n\n")
           (insert "Undocumented commands:\n\n"
                   (loop for command in ,symbol
                         for doc = (documentation (intern-soft command))
                       if doc
                       do (insert (upcase command) "\n" doc "\n\n\n")
                       else concat (concat command "\n")))
           (goto-char (point-min))
           (when inside-minibuffer-p
                  ;; Called from inside ido-completing-read.
                  ;; Exit from minibuffer will restore windows.
                  ;; Install temporary hook that goes to created window.
                  (add-hook 'post-command-hook
                            (defun ,post-function ()
                              (switch-to-buffer "*Command Subset*")
                              (remove-hook 'post-command-hook
                                           ',post-function)))
                  (setq ido-matches nil
                        ido-exit 'done)
                  (exit-minibuffer)))))))





(defun jcl-compile-command-subset (regex)
  "Return all commands in the symbol table that match REGEX."
  (sort (loop for symbol being the symbols
              for name = (symbol-name symbol)
              when (and (commandp symbol)
                        (string-match regex name))
              collect name)
        'string-lessp))

(defun jcl-compile-command-subsets ()
  "Update all command subset lists."
  (interactive)
  (loop for (list-variable . regex) in jcl-command-subset-alist
        do (set list-variable (jcl-compile-command-subset regex))))

(defun jcl-consecutive-calls ()
  "Return the number of times the current command have been called in a row.

This function is designed to be called a single time from a
command.  If it is called multiple times it's return value will
be increased for each call."
  (let* ((symbol (if (symbolp this-command)
                     ;; Command is stored in a interned symbol.
                     this-command
                   ;; Command is a lambda expression.
                   (or (cdr-safe (assq this-command
                                       jcl-consecutive-calls-lambda-alist))
                       (let ((new-symbol (make-symbol "my-name-is-not-important")))
                         (add-to-list 'jcl-consecutive-calls-lambda-alist
                                      (cons this-command new-symbol))
                         new-symbol))))
         (n (get symbol 'jcl-consecutive-calls))
         (again (eq this-command last-command)))
    (if n
        (put symbol 'jcl-consecutive-calls (if again
                                               (1+ n)
                                             1))
      (if again
          (put symbol 'jcl-consecutive-calls 2)
        1))))


(defun jcl-command-subset-setup (&optional enable-slow-and-dangerous-advice)
  "Setup things to re-compile command subset lists when needed.

The default is to compile everything once at the end of Emacs
startup and also insert individual commands evaluated with
`eval-defun'.

Calling this function is optional.  It is also possible to
compile the subset list of a particular command by executing that
command twice in a row.

If ENABLE-SLOW-AND-DANGEROUS-ADVICE is non-nil a number of
primitives will be adviced.  According to the elisp manual (17.9
Advising Primitives) this is dangerous.  The author have never
experienced any problems with this but have only tested it on GNU
Emacs 23.3.  Also note that the advices will slow down these
primitives a lot."
  (if after-init-time
      ;; Emacs startup is finished.  Compile command subsets now.
      (jcl-compile-command-subsets)
    ;; Emacs is in the process of starting up.
    (add-hook 'emacs-startup-hook
              (defun jcl-command-subset-compile ()
                (jcl-compile-command-subsets)
                (remove-hook 'pre-command-hook 'jcl-command-subset-compile-again))))
  (defadvice eval-defun (around jcl-add-command-subset activate)
    (let* ((symbol ad-do-it))
      (when (and (symbolp symbol)
                 (commandp symbol))
        (let ((name (symbol-name symbol)))
          (loop for (list-variable . regex) in jcl-command-subset-alist
                when (string-match regex name)
                do (add-to-list list-variable name))
          symbol))))
  (when enable-slow-and-dangerous-advice
    ;; It would be nice to advice only the function intern instead of all
    ;; these eval commands.  But my attempts to advice intern have all
    ;; messed up emacs completely.
    (macrolet ((advice (f)
                       `(defadvice ,f (after
                                       jcl-compile-command-subsets-after-eval
                                       activate)
                          "Update the lists of command subsets."
                          (jcl-compile-command-subsets))))
      (advice eval-region)
      (advice eval-buffer))

    (if after-init-time
        ;; Emacs startup is finished.  Advice load and require now.
        (jcl-command-subset-compile-at-load)
      ;; Emacs is in the process of starting up.  We want to rebuild
      ;; lists when load or require is called.  But do not activate this
      ;; until after all startup is finished.
      (add-hook 'emacs-startup-hook 'jcl-command-subset-compile-at-load)
      ;; If emacs init fails emacs-startup-hook will not be runned.  But
      ;; pre-command-hook will be.
      (add-hook 'pre-command-hook
                (defun jcl-command-subset-compile-again ()
                  (jcl-compile-command-subsets)
                  (remove-hook 'pre-command-hook 'jcl-command-subset-compile-again))))))

(defun jcl-command-subset-compile-at-load ()
  "Advice `load' and `require' to recompile command subsets."
  (ad-define-subr-args 'load '(file
                               &optional
                               noerror
                               nomessage
                               nosuffix
                               must-suffix))
  (defadvice load (after jcl-compile-command-subsets-after-load activate)
    (jcl-compile-command-subsets))
  ;; (ad-define-subr-args 'require '(feature filename noerror))
  (defadvice require (around jcl-compile-command-subsets-after-require activate)
    (let ((jcl-been-there-done-that (featurep (ad-get-arg 0)))
          (rc ad-do-it))
      (unless jcl-been-there-done-that
        (jcl-compile-command-subsets))
      rc)))

(provide 'jcl-command-subset)

;;; jcl-command-subset.el ends here

