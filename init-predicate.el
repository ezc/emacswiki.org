;;; init-predicate.el --- Predicate configuration

;; Filename: init-predicate.el
;; Description: Predicate configuration
;; Author: Andy Stewart lazycat.manatee@gmail.com
;; Maintainer: Andy Stewart lazycat.manatee@gmail.com
;; Copyright (C) 2008, 2009, Andy Stewart, all rights reserved.
;; Created: 2008-10-20 09:51:58
;; Version: 0.1
;; Last-Updated: 2008-10-20 09:51:58
;;           By: Andy Stewart
;; URL:
;; Keywords: Predicate
;; Compatibility: GNU Emacs 23.0.60.1
;;
;; Features that might be required by this library:
;;
;;
;;

;;; This file is NOT part of GNU Emacs

;;; License
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth
;; Floor, Boston, MA 02110-1301, USA.

;;; Commentary:
;;
;; Predicate configuration
;;

;;; Installation:
;;
;; Put init-predicate.el to your load-path.
;; The load-path is usually ~/elisp/.
;; It's set in your ~/.emacs like this:
;; (add-to-list 'load-path (expand-file-name "~/elisp"))
;;
;; And the following to your ~/.emacs startup file.
;;
;; (require 'init-predicate)
;;
;; No need more.

;;; Change log:
;;
;; 2008/10/20
;;      First released.
;;

;;; Acknowledgements:
;;
;;
;;

;;; TODO
;;
;;
;;

;;; Require


;;; Code:

;;; ### Completion-ui ###
;;; --- 补全菜单
(setq completion-auto-show-delay 0.5)   ;补全菜单延迟

;;; ### Predicate ###
;;; --- 英语助手
(set-default 'predictive-auto-add-to-dict t) ;自动加入词典
(setq predictive-add-to-dict-ask nil)        ;加入词典不询问
(setq predictive-auto-learn t)               ;自动学习
(setq predictive-completion-speed 0.1)       ;查找补全的速度(秒)
(setq completion-auto-show-delay 0.5)        ;弹出补全tooltip的延迟(秒)
(dolist (hook (list
               'erc-mode-hook
               'rcirc-mode-hook
               'message-mode-hook
               'yaoddmuse-mode-hook
               ))
  (add-hook hook '(lambda () (predictive-mode 1))))

(provide 'init-predicate)

;;; init-predicate.el ends here
