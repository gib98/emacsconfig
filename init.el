;; Basics
(set-face-attribute 'default nil :height 140)
(setq-default visible-bell 1)
(setq-default indent-tabs-mode nil)
(setq-default show-paren-mode 1)
(if window-system (tool-bar-mode 0))
(if (boundp 'aquamacs-version) (tabbar-mode 0))
(setq-default linum-format "%4d ")
(set-scroll-bar-mode 'right)
(add-hook 'text-mode-hook 'turn-on-visual-line-mode)
(setq-default visual-line-fringe-indicators '(nil nil))
(setq-default word-wrap t)
(setq-default column-number-mode t)
(show-paren-mode 1)
(delete-selection-mode 1)
(setq-default ispell-program-name "/usr/local/bin/ispell")
(add-hook 'before-save-hook 'delete-trailing-whitespace)

;; UTF-8 everywhere
(prefer-coding-system 'utf-8)
(set-language-environment 'utf-8)
(set-default-coding-systems 'utf-8)
(set-terminal-coding-system 'utf-8)
(set-selection-coding-system 'utf-8)

;; linum-mode everywhere, except where it doesn't belong
(require 'linum)
(setq linum-disabled-modes-list '(eshell-mode
                                  wl-summary-mode
                                  compilation-mode
                                  dired-mode
                                  speedbar-mode
                                  doc-view-mode))
(defun linum-on ()
  (unless (or (minibufferp)
              (member major-mode linum-disabled-modes-list)
            (and (not (eq (buffer-name) "*scratch*"))
                 (string-match "*" (buffer-name))))
    (linum-mode 1)))
(global-linum-mode 1)
(setq linum-eager nil)

;; Keybindings
(global-set-key (kbd "M-j") 'join-line)
(global-set-key (kbd "M-g") 'goto-line)

;; From http://www.emacswiki.org/emacs/SmoothScrolling
;; Scroll one line at a time (less "jumpy" than defaults)
(setq-default mouse-wheel-scroll-amount '(1 ((shift) . 1)))
(setq-default mouse-wheel-progressive-speed nil) ;; don't accelerate scrolling
(setq-default mouse-wheel-follow-mouse 't) ;; scroll window under mouse
(setq-default scroll-step 1) ;; keyboard scroll one line at a time

;; Account for size of gutter and fringes
(add-to-list 'initial-frame-alist '(width . 88))
(add-to-list 'default-frame-alist '(width . 88))

;; Adds a duplicate function
(defun duplicate-line()
  (interactive)
  (move-beginning-of-line 1)
  (kill-line)
  (yank)
  (open-line 1)
  (next-line 1)
  (yank)
)
(global-set-key (kbd "C-D") 'duplicate-line)



;; Tell emacs where is your personal elisp lib dir
(add-to-list 'load-path "~/.emacs.d/lisp/")

;; load the packaged named xyz.
(load "smart-compile") ;; best not to include the ending “.el” or “.elc”


(add-to-list 'load-path
              "~/.emacs.d/lisp/yasnippet")
(require 'yasnippet)
(yas-global-mode 1)
