;;; latex-config.el -*- lexical-binding: t; -*-

;; AUCTeX. The major mode is AUCTeX's own `LaTeX-mode', not the built-in
;; `latex-mode'. `auto-mode-alist' still maps .tex to the built-in modes;
;; auctex's tex-site.el redirects them via `major-mode-remap-defaults', so
;; nothing here needs to touch `auto-mode-alist'.
;;
;; NB: do not rename this file to tex.el -- it would shadow auctex's own
;; tex.el on `load-path' and `(use-package tex)' would recursively load it.
(use-package tex
  :ensure auctex
  :demand t
  :custom
  ;; Parse the document (and its \usepackage'd styles) to drive completion,
  ;; folding and the reference/citation prompts.
  (TeX-auto-save t)
  (TeX-parse-self t)
  (TeX-PDF-mode t)
  ;; Ask once per new document instead of assuming every file is standalone;
  ;; the answer is written into the file's local variables.
  (TeX-master nil)
  (TeX-source-correlate-method 'synctex)
  (TeX-source-correlate-start-server t)
  :config
  ;; SyncTeX both ways. This also makes `%S' in the LaTeXMk command below
  ;; expand to `--synctex=1', so the .synctex.gz actually gets written.
  (TeX-source-correlate-mode 1)

  ;; AUCTeX 14.1 already ships a "LaTeXMk" entry in `TeX-command-list', so we
  ;; only need to prefer it over plain "LaTeX" -- latexmk re-runs the engine
  ;; and bibtex/biber as many times as the document needs. `TeX-command-default'
  ;; is `defvar-local' and `LaTeX-mode's body sets it to "LaTeX", so this has
  ;; to run from the hook, after the mode body.
  (add-hook 'LaTeX-mode-hook
            (lambda () (setq TeX-command-default "LaTeXMk")))

  ;; View in pdf-tools (configured in editor.el) rather than an external app.
  (setq TeX-view-program-selection '((output-pdf "PDF Tools")))
  ;; Refresh the pdf-tools buffer in place when a build finishes, instead of
  ;; leaving a stale page on screen.
  (add-hook 'TeX-after-compilation-finished-functions
            #'TeX-revert-document-buffer))

;; \ref / \cite / \label navigation, sharing the bibliography citar uses.
;; These have to be set from `:config' rather than `:custom': reftex is
;; autoloaded, so at init time the defcustoms do not exist yet, and
;; `reftex-mode' reads them while initialising.
(use-package reftex
  :hook (LaTeX-mode . turn-on-reftex)
  :config
  (setq reftex-plug-into-AUCTeX t
        reftex-default-bibliography '("~/org/references.bib")))

;; Fast math entry: ` for symbols, : for accents, TAB through templates.
(use-package cdlatex
  :ensure t
  :hook (LaTeX-mode . turn-on-cdlatex))

;; digestif (ships with MacTeX) as the LaTeX language server, alongside the
;; python/rust servers in langs.el. Picks up the eldoc-box and inlay-hint
;; hooks configured there for free.
(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs
               '((LaTeX-mode plain-TeX-mode ConTeXt-mode texinfo-mode)
                 . ("digestif"))))
(add-hook 'LaTeX-mode-hook #'eglot-ensure)

;; `apheleia-global-mode' is on globally (editor.el) and apheleia's default
;; alist maps every TeX mode to latexindent, which would reflow prose-heavy
;; .tex files on every save. Drop those entries; bibtex is left alone.
(with-eval-after-load 'apheleia
  (dolist (mode '(latex-mode LaTeX-mode TeX-latex-mode TeX-mode))
    (setf (alist-get mode apheleia-mode-alist nil t) nil)))

(provide 'latex-config)
