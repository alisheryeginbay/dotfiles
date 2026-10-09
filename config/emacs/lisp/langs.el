;;; langs.el -*- lexical-binding: t; -*-

;; Programming
(use-package eglot
  :ensure t
  :hook (((python-mode python-ts-mode) . eglot-ensure)
         (rust-ts-mode . eglot-ensure)
         (eglot-managed-mode . eglot-inlay-hints-mode)
         (eglot-managed-mode . (lambda ()
                                 (when (derived-mode-p 'python-base-mode)
                                   (add-hook 'before-save-hook #'eglot-format-buffer nil t))))
         (rust-ts-mode . (lambda ()
                           (add-hook 'before-save-hook #'eglot-format-buffer nil t))))
  :config
  (add-to-list 'eglot-server-programs
               '((python-mode python-ts-mode) . ("ty" "python")))
  (add-to-list 'eglot-server-programs
               '((rust-ts-mode rust-mode) . ("rust-analyzer")))
  (setq-default eglot-workspace-configuration
                '(:rust-analyzer (:check (:command "clippy")
                                         :cargo (:features "all")))))

(use-package eldoc-box
  :ensure t
  :hook (eglot-managed-mode . eldoc-box-hover-at-point-mode))

;; In-buffer completion popup (pairs with the vertico/orderless minibuffer stack)
(use-package corfu
  :ensure t
  :init (global-corfu-mode)
  :custom
  (corfu-auto t)
  (corfu-auto-delay 0.15)
  (corfu-auto-prefix 2)
  (corfu-cycle t)
  (corfu-popupinfo-delay '(0.5 . 0.2))
  :config
  (corfu-popupinfo-mode 1)
  ;; Let RET insert a newline; use TAB to confirm a candidate.
  (keymap-unset corfu-map "RET" t))

(use-package cape
  :ensure t
  :init
  (add-hook 'completion-at-point-functions #'cape-file))

(use-package code-cells
  :ensure t
  :hook ((python-mode python-ts-mode) . code-cells-mode-maybe)
  :config
  (define-key code-cells-mode-map (kbd "C-c C-<return>") #'code-cells-eval))

(use-package rust-ts-mode
  :custom (rust-ts-mode-indent-offset 4))

(use-package pet
  :ensure t
  :config
  (add-hook 'python-base-mode-hook 'pet-mode -10))

;; R: ESS provides R-mode, inferior R sessions, and the editing mode
;; for R src blocks in org (C-c ')
(use-package ess
  :ensure t
  :defer t
  :custom
  (ess-ask-for-ess-directory nil)
  (ess-use-flymake nil))

(provide 'langs)
