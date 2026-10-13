;;; typst-config.el -*- lexical-binding: t; -*-

;; typst-ts-mode. The tree-sitter grammar comes from home.nix
;; (treesit-grammars), and typst/tinymist/typstyle from home.packages.
;; apheleia already maps `typst-ts-mode' to typstyle, so formatting on
;; save needs no setup here.
;;
;; NB: do not rename this file to typst-ts-mode.el -- it would shadow the
;; package on `load-path' (same trap as latex-config.el).

(defun my/typst-preview-pdf (file)
  "Show FILE in pdf-tools in another window, keeping point in the source.
Auto-revert keeps the page current while `typst-ts-watch-mode' rebuilds."
  (let ((buf (find-file-noselect file)))
    (with-current-buffer buf
      (auto-revert-mode 1))
    (display-buffer buf '(display-buffer-reuse-window
                          display-buffer-use-some-window
                          (inhibit-same-window . t)))))

(use-package typst-ts-mode
  :ensure t
  :mode "\\.typ\\'"
  :custom
  (typst-ts-preview-function #'my/typst-preview-pdf)
  ;; Highlight ```lang blocks with their own grammar where one is installed.
  (typst-ts-enable-raw-blocks-highlight t))

;; tinymist as the Typst language server (eglot has no built-in entry).
;; Picks up the eldoc-box and inlay-hint hooks from langs.el.
(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs
               '(typst-ts-mode . ("tinymist"))))
(add-hook 'typst-ts-mode-hook #'eglot-ensure)

(provide 'typst-config)
