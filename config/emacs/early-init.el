;;; early-init.el -*- lexical-binding: t; -*-

(setq package-enable-at-startup nil)

(setq default-frame-alist
      '((tool-bar-lines . 0)
        (vertical-scroll-bars . nil)
        (horizontal-scroll-bars . nil)
        (ns-transparent-titlebar . t)
        (ns-appearance . dark)
        (internal-border-width . 8)
        (fullscreen . maximized)))

(setq frame-inhibit-implied-resize t
      inhibit-startup-screen t
      use-file-dialog nil
      use-dialog-box nil)

(tool-bar-mode -1)
(scroll-bar-mode -1)
