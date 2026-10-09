;;; init.el -*- lexical-binding: t; -*-

;; Package management: packages come from Nix (programs.emacs.extraPackages in
;; home.nix). package.el stays available for trying things out with
;; M-x package-install; add keepers to home.nix.
(setq native-comp-async-report-warnings-errors 'silent)
(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/"))
(package-initialize)

;; Modules
(add-to-list 'load-path (expand-file-name "lisp" user-emacs-directory))
(dolist (module '(editor projects langs latex-config org-config keybindings))
  (load (symbol-name module)))

;; Customize writes here instead of into this (versioned) file.
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(load custom-file t)
