;;; evil-collection-vterm.el --- Bindings for `vterm' -*- lexical-binding: t -*-

;; Copyright (C) 2019 James Nguyen
;; Copyright (C) 2020 Alex Griffin <a@ajgrf.com>

;; Author: James Nguyen <james@jojojames.com>
;; Maintainer: James Nguyen <james@jojojames.com>
;; Pierre Neidhardt <mail@ambrevar.xyz>
;; URL: https://github.com/emacs-evil/evil-collection
;; Version: 0.0.1
;; Package-Requires: ((emacs "25.1"))
;; Keywords: evil, vterm, tools

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

;;; Commentary:
;;; Bindings for `vterm'.

;;; Code:
(require 'evil-collection)
(require 'vterm nil t)

(defconst evil-collection-vterm-maps '(vterm-mode-map))

(defvar vterm--process)

(defun evil-collection-vterm-escape-stay ()
  "Go back to normal state but don't move cursor backwards.
Moving cursor backwards is the default vim behavior but
it is not appropriate in some cases like terminals."
  (setq-local evil-move-cursor-back nil))

(defvar-local evil-collection-vterm-send-escape-to-vterm-p nil
  "Track whether or not we send ESC to `vterm' or `emacs'.")

(defun evil-collection-vterm-toggle-send-escape ()
  "Toggle where ESC is sent between `vterm' and `emacs'.

This is needed for programs that use ESC, e.g. vim or an ssh'd emacs that
also uses `evil-mode'."
  (interactive)
  (if evil-collection-vterm-send-escape-to-vterm-p
      (evil-collection-define-key 'insert 'vterm-mode-map (kbd "<escape>")
        (lookup-key evil-insert-state-map (kbd "<escape>")))
    (evil-collection-define-key 'insert 'vterm-mode-map
      (kbd "<escape>") 'vterm--self-insert))
  (setq evil-collection-vterm-send-escape-to-vterm-p
        (not evil-collection-vterm-send-escape-to-vterm-p))
  (message (format "Sending ESC to %s."
                   (if evil-collection-vterm-send-escape-to-vterm-p
                       "vterm"
                     "emacs"))))

(defun vterm-evil-insert ()
  (interactive)
  (vterm-goto-char (point))
  (call-interactively #'evil-insert))

(defun vterm-evil-insert-line ()
  (interactive)
  (vterm-goto-char (vterm--get-prompt-point))
  (call-interactively #'evil-insert))

(defun vterm-evil-append ()
  (interactive)
  (vterm-goto-char (1+ (point)))
  (call-interactively #'evil-append))

(defun vterm-evil-append-line ()
  (interactive)
  (vterm-goto-char (vterm--get-end-of-line))
  (call-interactively #'evil-append))

(defun vterm-evil-delete ()
  "Provide similar behavior as `evil-delete'."
  (interactive)
  (let ((inhibit-read-only t)
        )
    (cl-letf (((symbol-function #'delete-region) #'vterm-delete-region))
      (call-interactively 'evil-delete))))

(defun vterm-evil-delete-line ()
  "Provide similar behavior as `evil-delete'."
  (interactive)
  (let ((inhibit-read-only t)
        )
    (cl-letf (((symbol-function #'delete-region) #'vterm-delete-region))
      (call-interactively 'evil-delete-line))))

(evil-define-operator vterm-evil-delete-backward-char (beg end type register)
  "Delete previous character."
  :motion evil-backward-char
  (interactive "<R><x>")
  (let ((inhibit-read-only t)
        )
    (cl-letf (((symbol-function #'delete-region) #'vterm-delete-region))
      (evil-delete beg end type register))))

(defun vterm-evil-change ()
  "Provide similar behavior as `evil-change'."
  (interactive)
  (let ((inhibit-read-only t))
    (cl-letf (((symbol-function #'delete-region) #'vterm-delete-region))
      (call-interactively 'evil-change))))

;;;###autoload
(defun evil-collection-vterm-setup ()
  "Set up `evil' bindings for `vterm'."
  (evil-set-initial-state 'vterm-mode 'insert)

  (add-hook 'vterm-mode-hook #'evil-collection-vterm-escape-stay)

  ;; Open to a better binding...
  (evil-collection-define-key '(normal insert) 'vterm-mode-map
    (kbd "C-c C-z") 'evil-collection-vterm-toggle-send-escape)

  ;; Evil has some "C-" bindings in insert state that shadow regular terminal
  ;; bindings. Don't raw-send "C-c" (prefix key) nor "C-h" (help prefix).
  (evil-collection-define-key 'insert 'vterm-mode-map
    (kbd "C-a") 'vterm--self-insert
    (kbd "C-b") 'vterm--self-insert     ; Should not be necessary.
    (kbd "C-d") 'vterm--self-insert
    (kbd "C-e") 'vterm--self-insert
    (kbd "C-f") 'vterm--self-insert     ; Should not be necessary.
    (kbd "C-k") 'vterm--self-insert
    (kbd "C-l") 'vterm--self-insert     ; Should not be necessary.
    (kbd "C-n") 'vterm--self-insert
    (kbd "C-o") 'vterm--self-insert
    (kbd "C-p") 'vterm--self-insert
    (kbd "C-q") 'vterm--self-insert     ; Should not be necessary.
    (kbd "C-r") 'vterm--self-insert
    (kbd "C-s") 'vterm--self-insert     ; Should not be necessary.
    (kbd "C-t") 'vterm--self-insert
    (kbd "C-u") 'vterm--self-insert     ; Should not be necessary.
    (kbd "C-v") 'vterm--self-insert     ; Should not be necessary.
    (kbd "C-w") 'vterm--self-insert
    (kbd "C-y") 'vterm--self-insert
    (kbd "C-z") 'vterm--self-insert
    (kbd "<delete>") 'vterm-send-delete)

  (evil-collection-define-key 'normal 'vterm-mode-map
    "[[" 'vterm-previous-prompt
    "]]" 'vterm-next-prompt
    "p" 'vterm-yank
    "a" 'vterm-evil-append
    "A" 'vterm-evil-append-line
    ;; "d" 'vterm-evil-delete
    ;; "D" 'vterm-evil-delete-line
    ;; "x" 'vterm-evil-delete-char
    (kbd "RET") 'vterm-send-return
    "i" 'vterm-evil-insert
    "I" 'vterm-evil-insert-line
    ;; "c" 'vterm-evil-change
    "u" 'vterm-undo)

  (evil-collection-define-key 'visual 'vterm-mode-map
    ;; "d" 'vterm-evil-delete
    ;; "x" 'vterm-evil-delete
    ;; "c" 'vterm-evil-change
    ;; "c" 'vterm-evil-replace
    ))
(provide 'evil-collection-vterm)
;;; evil-collection-vterm.el ends here
