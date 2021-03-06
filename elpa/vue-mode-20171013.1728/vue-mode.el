;;; vue-mode.el --- Major mode for vue component based on mmm-mode  -*- lexical-binding: t; -*-

;; Copyright (C) 2016 codefalling, Adam Niederer

;; Author: codefalling <code.falling@gmail.com>
;; Keywords: languages
;; Package-Version: 20171013.1728

;; Version: 0.3.1
;; Package-Requires: ((mmm-mode "0.5.4") (vue-html-mode "0.1") (ssass-mode "0.1") (edit-indirect "0.1.4"))

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

;;

;;; Code:

(require 'mmm-mode)
(require 'vue-html-mode)
(require 'ssass-mode)
(require 'edit-indirect)

(defgroup vue nil
  "Group for vue-mode"
  :prefix "vue-"
  :group 'languages
  :link '(url-link :tag "Github" "https://github.com/CodeFalling/vue-mode")
  :link '(emacs-commentary-link :tag "Commentary" "vue-mode"))

(defcustom vue-modes
  '((:type template :name nil :mode vue-html-mode)
    (:type template :name html :mode vue-html-mode)
    (:type template :name jade :mode jade-mode)
    (:type template :name pug :mode pug-mode)
    (:type template :name slm :mode slim-mode)
    (:type template :name slim :mode slim-mode)
    (:type script :name nil :mode js-mode)
    (:type script :name js :mode js-mode)
    (:type script :name es6 :mode js-mode)
    (:type script :name babel :mode js-mode)
    (:type script :name coffee :mode coffee-mode)
    (:type script :name ts :mode typescript-mode)
    (:type script :name typescript :mode typescript-mode)
    (:type style :name nil :mode css-mode)
    (:type style :name css :mode css-mode)
    (:type style :name stylus :mode stylus-mode)
    (:type style :name less :mode less-css-mode)
    (:type style :name scss :mode css-mode)
    (:type style :name sass :mode ssass-mode))
  "A list of vue component languages, their type, and their corresponding major modes."
  :type '(list (plist :type 'symbol :name 'symbol :mode 'function))
  :group 'vue)

(defvar vue-mode-map
  (let ((map (make-keymap)))
    (define-key map (kbd "C-c C-l") 'vue-mode-reparse)
    (define-key map (kbd "C-c C-k") 'vue-mode-edit-indirect-at-point)
    map)
  "Keymap for `vue-mode'.")

(defvar vue-initialized nil
  "If false, `vue-mode' still needs to prepare `mmm-mode' before being activated.")

(defconst vue--not-lang-key
  (concat
   "\\(?:"
   "\\w*[^l]\\w\\w\\w=" ; Anything not starting with a lowercase l, or
   "\\|"
   "\\w*[^a]\\w\\w=" ; Anything without a in the second position, or
   "\\|"
   "\\w*[^n]\\w=" ; Anything without n in the third position, or
   "\\|"
   "\\w*[^g]=" ; Anything not ending with g, or
   "\\|"
   "g=" ; Just g, or
   "\\|"
   "\\w\\{5,\\}=" ; A 5+-character word
   "\\)")
  "Matches anything but 'lang'. See `vue--front-tag-regex'")

(defconst vue--front-tag-lang-regex
  (concat "<%s"                        ; The tag name
          "\\(?: +\\w+=\".*?\" *?\\)*" ; Any optional key-value pairs like type="foo/bar"
          " +lang=\"%s\""              ; The language specifier
          "\\(?: +\\w+=\".*?\" *?\\)*" ; More optional key-value pairs
          "\\(?: +scoped\\)?"          ; The optional "scoped" attribute
          "\\(?: +module\\)?"          ; The optional "module" attribute
          " *>\n")                     ; The end of the tag
  "A regular expression for the starting tags of template areas with languages.
To be formatted with the tag name, and the language.")

(defconst vue--front-tag-regex
  (concat "<%s"                        ; The tag name
          "\\(?: +" vue--not-lang-key "\"[^\"]*?\" *?\\)*" ; Any optional key-value pairs like type="foo/bar".
          ;; ^ Disallow "lang" in k/v pairs to avoid matching regions with non-default languages
          "\\(?: +scoped\\)?"          ; The optional "scoped" attribute
          "\\(?: +module\\)?"          ; The optional "module" attribute
          " *>\n")                     ; The end of the tag
  "A regular expression for the starting tags of template areas.
To be formatted with the tag name.")

(defun vue--setup-mmm ()
  "Add syntax highlighting regions to mmm-mode, according to `vue-modes'."
  (dolist (mode-binding vue-modes)
    (let* ((type (plist-get mode-binding :type))
           (name (plist-get mode-binding :name))
           (mode (plist-get mode-binding :mode))
           (class (make-symbol (format "vue-%s" name)))
           (front (if name (format vue--front-tag-lang-regex type name)
                    (format vue--front-tag-regex type)))
           (back (format "^</%s *>" type)))
      (mmm-add-classes `((,class :submode ,mode :front ,front :back ,back)))
      (mmm-add-mode-ext-class 'vue-mode nil class)))
  (setq vue-initialized t))

(defun vue-mode-reparse ()
  "Reparse the buffer, reapplying all major modes."
  (interactive)
  (mmm-parse-buffer))

(defun vue-mode-edit-indirect-at-point ()
  "Open the section of the template at point with `edit-indirect-mode'."
  (interactive)
  (if mmm-current-overlay
      (let ((indirect-mode mmm-current-submode))
        (setq-local edit-indirect-after-creation-hook (list (lambda () (funcall indirect-mode))))
        (edit-indirect-region (overlay-start mmm-current-overlay)
                              (1- (overlay-end mmm-current-overlay)) ;; Work around edit-indirect-mode bug
                              (current-buffer)))
    (user-error "Not in a template subsection")))

;;;###autoload
(defun vue-mode-edit-all-indirect (&optional keep-windows)
  "Open all subsections with `edit-indirect-mode' in seperate windows.
If KEEP-WINDOWS is set, do not delete other windows and keep the root window
open in a window."
  (interactive "P")
  (when (not keep-windows)
    (delete-other-windows))
  (save-selected-window
    (dolist (ol (mmm-overlays-contained-in (point-min) (point-max)))
      (let* ((window (split-window-below))
             (mode (overlay-get ol 'mmm-mode))
             (buffer (edit-indirect-region (overlay-start ol) (overlay-end ol))))
        (maximize-window)
        (with-current-buffer buffer
          (funcall mode))
        (set-window-buffer window buffer)))
    (balance-windows))
  (when (not keep-windows)
    (delete-window)
    (balance-windows)))

;;;###autoload
(define-derived-mode vue-mode html-mode "vue"
  (when (not vue-initialized)
    (vue--setup-mmm)))

;;;###autoload
(setq mmm-global-mode 'maybe)

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.vue\\'" . vue-mode))

(provide 'vue-mode)
;;; vue-mode.el ends here
