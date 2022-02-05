;;; apropos-toc.el --- An alternative to M-x apropos -*- lexical-binding: t -*-

;; Copyright (C) 2005-2022 Claus Brunzema <mail@cbrunzema.de>


;; Author: Claus Brunzema <mail@cbrunzema.de>
;; Homepage: https://github.com/replrep/apropos-toc
;; or http://www.cbrunzema.de/software.html#apropos-toc

;; Version: 1.1.0
;; License: GPL-2.0 License
;; Package-Requires: ((emacs "26.3"))
;; Keywords: help

;; apropos-toc.el is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 2, or
;; (at your option) any later version.
;;
;; It is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
;; or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public
;; License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with apropos-toc.el; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.


;;; Commentary:

;; I never liked the mixed function/command/variable output style of
;; the original apropos commands in GNU emacs. This looks more like
;; the apropos output in XEmacs with separate sections for functions
;; and variables.
;;
;; apropos-toc.el was implemented with lots of stuff taken from GNU
;; emacs' apropos.el and XEmacs' hyper-apropos.el.
;;


;;; Installation:

;; Put apropos-toc.el in your load-path and add the following lines to
;; your .emacs:

;; (when (require 'apropos-toc nil 'noerror)
;;   (global-set-key (kbd "C-h a") #'apropos-toc))


;;; Code:
(require 'apropos)
(require 'cl-lib)

(defvar apropos-toc-buffername "*apropos-toc*"
  "Buffer name for the apropos-toc buffer.")

(defvar apropos-toc-mode-map
  (let ((keymap (make-sparse-keymap)))
    (define-key keymap (kbd "<RET>") #'apropos-toc-doc-this-line)
    (define-key keymap (kbd "<SPC>") #'apropos-toc-doc-this-line)
    (define-key keymap (kbd "<mouse-2>") #'apropos-toc-doc-this-mousepos)
    (define-key keymap (kbd "q") #'kill-this-buffer)
    keymap)
  "Keymap used in the apropos-toc buffer.")

(defvar apropos-toc-mode-hook nil
  "Hook run when apropos-toc-mode is turned on in the result buffer.")

(define-derived-mode apropos-toc-mode special-mode "Apropos-toc"
  "Major mode for following hyperlinks in output of apropos-toc commands.")

(defun apropos-toc (regexp)
  "Show bound symbols whose names match REGEXP."
  (interactive "sapropos-toc (regexp): ")
  (switch-to-buffer (get-buffer-create apropos-toc-buffername))
  (setq buffer-read-only nil)
  (erase-buffer)
  (let ((flist (apropos-internal regexp #'fboundp))
        (vlist (apropos-internal regexp #'boundp)))
    (insert (format "Apropos search for: %S\n\nFunctions:\n" regexp))
    (apropos-toc-display-functions flist)
    (insert "\nVariables:\n")
    (apropos-toc-display-variables vlist))
  (setq buffer-read-only t)
  (set-buffer-modified-p nil)
  (apropos-toc-mode)
  (setq truncate-lines t)
  (goto-char (point-min))
  (forward-line 3))

(defun apropos-toc-insert-table (table-data row-type)
  "Insert entries in TABLE-DATA into the current buffer.

TABLE-DATA is a list of entries. Every entry is a list of two strings,
a symbol name and a documentation string. The symbol ROW-TYPE is set
as overlay property 'type' for the output lines."
  (let ((max-symbol-len (cl-loop for entry in table-data
                                 maximize (length (cl-first entry)))))
    (dolist (entry table-data)
      (insert (cl-first entry))
      (insert-char ?\  (1+ (- max-symbol-len (length (cl-first entry)))))
      (insert (cl-second entry))
      (let ((overlay (make-overlay (point-at-bol)
                                   (point-at-eol))))
        (overlay-put overlay 'mouse-face 'highlight)
        (overlay-put overlay 'type row-type))
      (insert "\n"))))

(defun apropos-toc-display-functions (funcs)
  "Collect and display documentation lines for function symbols in FUNCS."
  (apropos-toc-insert-table
   (cl-loop for func in funcs collect
            (let ((doc (condition-case nil
                           (documentation func t)
                         (void-function "(alias for undefined function)"))))
              (list (symbol-name func)
                    (if doc
                        (substring doc 0 (string-match "\n" doc))
                      "(not documented)"))))
   'function))

(defun apropos-toc-display-variables (vars)
  "Collect and display documentation lines for variable symbols in VARS."
  (apropos-toc-insert-table
   (cl-loop for var in vars collect
            (let ((doc (documentation-property var 'variable-documentation t)))
              (list (symbol-name var)
                    (if doc
                        (substring doc 0 (string-match "\n" doc))
                      "(not documented)"))))
   'variable))

(defun apropos-toc-doc-this-line ()
  "Show full documentation for the item on the current line."
  (interactive)
  (beginning-of-line)
  (let ((overlay (cl-first (overlays-at (point)))))
    (when overlay
      (if (eq (overlay-get overlay 'type) 'function)
          (describe-function (function-called-at-point))
        (describe-variable (variable-at-point))))))

(defun apropos-toc-doc-this-mousepos ()
  "Show full documentation for the item at the current mouse position."
  (interactive)
  (mouse-set-point last-input-event)
  (apropos-toc-doc-this-line))

(provide 'apropos-toc)
;;; apropos-toc.el ends here
