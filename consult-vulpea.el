;;; consult-vulpea.el --- Use Consult in tandem with Vulpea -*- lexical-binding: t -*-

;; Copyright (C) 2026

;; Author: Fabrizio Contigiani <fabcontigiani@gmail.com>
;; Maintainer: Fabrizio Contigiani <fabcontigiani@gmail.com>
;; URL: https://github.com/fabcontigiani/consult-vulpea
;; Version: 0.1.0
;; Package-Requires: ((emacs "28.1") (vulpea "2.0.0") (consult "2.2"))
;; Keywords: convenience, notes, vulpea

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This package integrates `vulpea' with `consult' to provide
;; enhanced minibuffer interactions, most notably live file previews
;; when selecting notes with `vulpea-find' and `vulpea-insert'.
;;
;; To enable, simply turn on `consult-vulpea-mode':
;;
;;   (consult-vulpea-mode 1)
;;
;; Features:
;;
;; 1. **Live previews**: When selecting notes via `vulpea-find' or
;;    `vulpea-insert', you get a live preview of the note file as you
;;    navigate through candidates.
;;
;; 2. **Consult-powered grep/find**: Use `consult-vulpea-grep' and
;;    `consult-vulpea-find' to search within your vulpea directories
;;    with live previews.

;;; Code:

(require 'consult)
(require 'vulpea)
(require 'vulpea-note)
(require 'vulpea-db)
(require 'vulpea-select)

(defgroup consult-vulpea ()
  "Use Consult with Vulpea for enhanced note selection."
  :group 'vulpea
  :group 'consult
  :group 'minibuffer
  :link '(url-link :tag "GitHub" "https://github.com/fabcontigiani/consult-vulpea"))

;;;; User options

(defcustom consult-vulpea-grep-command #'consult-ripgrep
  "Consult-powered grep command to use for `consult-vulpea-grep'.
Common choices are `consult-grep' and `consult-ripgrep'."
  :type 'function
  :group 'consult-vulpea)

(defcustom consult-vulpea-find-command #'consult-find
  "Consult-powered find command to use for `consult-vulpea-find'."
  :type 'function
  :group 'consult-vulpea)

;;;; Helper functions

(defun consult-vulpea--file-preview (note-table)
  "Create a preview function for vulpea notes.
NOTE-TABLE is a hash table mapping candidate strings to vulpea notes."
  (let ((preview (consult--file-preview)))
    (lambda (action cand)
      (let* ((note (and cand (gethash (substring-no-properties cand) note-table)))
             (file (and note (vulpea-note-path note))))
        (funcall preview action file)))))

;;;; Core selection function

(cl-defun consult-vulpea-select-from (prompt
                                       notes
                                       &key
                                       require-match
                                       initial-prompt
                                       expand-aliases)
  "Select a note from NOTES using consult with preview.

Returns a selected `vulpea-note'. If `vulpea-note-id' is nil, it
means that user selected a non-existing note.

This is a drop-in replacement for `vulpea-select-from' that adds
consult-style live previews.

PROMPT is the message to present.
REQUIRE-MATCH when non-nil means user must select an existing note.
INITIAL-PROMPT is the initial input for the prompt.
EXPAND-ALIASES when non-nil expands note aliases for completion."
  ;; Ensure consult is loaded (important when called via advice before
  ;; the package is fully loaded due to autoloads)
  (require 'consult)
  (let* ((expanded-notes (if expand-aliases
                             (seq-mapcat #'vulpea-note-expand-aliases notes)
                           notes))
         ;; Build hash table for fast lookup (avoids text property issues)
         (note-table (make-hash-table :test #'equal))
         (candidates
          (mapcar
           (lambda (note)
             (let ((key (vulpea-select-describe note)))
               (puthash (substring-no-properties key) note note-table)
               key))
           expanded-notes))
         ;; Set default-directory for file preview to work correctly
         ;; (following consult-denote's approach)
         (default-directory (or (car (bound-and-true-p vulpea-db-sync-directories))
                                (bound-and-true-p org-directory)
                                default-directory))
         (selected (consult--read
                    candidates
                    :prompt (concat prompt ": ")
                    :require-match require-match
                    :initial initial-prompt
                    :history 'vulpea-find-history
                    :state (consult-vulpea--file-preview note-table)
                    :category 'vulpea-note
                    :sort t)))
    (or (and selected (gethash (substring-no-properties selected) note-table))
        (make-vulpea-note
         :title (substring-no-properties (or selected initial-prompt ""))
         :level 0))))

;;;; Commands

;;;###autoload
(defun consult-vulpea-grep ()
  "Search vulpea notes using grep with live preview.
Uses `consult-vulpea-grep-command' (default: `consult-ripgrep')."
  (interactive)
  (let ((dir (car (or (bound-and-true-p vulpea-db-sync-directories)
                      (list org-directory)))))
    (funcall-interactively consult-vulpea-grep-command dir)))

;;;###autoload
(defun consult-vulpea-find ()
  "Find vulpea note files using find with live preview.
Uses `consult-vulpea-find-command' (default: `consult-find')."
  (interactive)
  (let ((dir (car (or (bound-and-true-p vulpea-db-sync-directories)
                      (list org-directory)))))
    (funcall-interactively consult-vulpea-find-command dir)))

;;;; Minor mode

;;;###autoload
(define-minor-mode consult-vulpea-mode
  "Use Consult in tandem with Vulpea.

When enabled, this mode replaces `vulpea-select-from' with a
consult-powered version that provides live previews when
selecting notes."
  :global t
  :lighter " cv"
  :group 'consult-vulpea
  (if consult-vulpea-mode
      (progn
        ;; Ensure consult and vulpea-select are fully loaded
        (require 'consult)
        (require 'vulpea-select)
        ;; Override vulpea-select-from with our consult version
        (advice-add #'vulpea-select-from
                    :override #'consult-vulpea-select-from))
    ;; Remove our advice
    (advice-remove #'vulpea-select-from #'consult-vulpea-select-from)))

(provide 'consult-vulpea)
;;; consult-vulpea.el ends here
