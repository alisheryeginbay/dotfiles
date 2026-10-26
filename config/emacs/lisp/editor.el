;;; editor.el -*- lexical-binding: t; -*-

(setq make-backup-files nil)
(setq auto-save-default nil)

;; UI
(setq display-line-numbers-type 'relative)
(global-display-line-numbers-mode 1)
(blink-cursor-mode -1)
(scroll-bar-mode -1)
(setq initial-scratch-message "")
(setq-default show-trailing-whitespace t)

;; Follow macOS light/dark. Runs at startup, and the appearance-watch
;; launchd agent (home.nix) calls it through emacsclient on every switch.
(defun my/apply-system-theme ()
  "Load Modus Vivendi or Operandi to match the macOS appearance."
  (interactive)
  (let ((theme (if (string-prefix-p
                    "Dark" (shell-command-to-string
                            "defaults read -g AppleInterfaceStyle 2>/dev/null"))
                   'modus-vivendi
                 'modus-operandi)))
    (unless (equal custom-enabled-themes (list theme))
      (mapc #'disable-theme custom-enabled-themes)
      (load-theme theme t))))
(my/apply-system-theme)

(set-face-attribute 'default nil :family "Aporetic Sans Mono" :height 150)
(set-face-attribute 'variable-pitch nil :family "Aporetic Sans" :height 1.0)
(set-face-attribute 'fixed-pitch nil :family "Aporetic Sans Mono" :height 1.0)

;; Olivetti: centred, distraction-free buffer (SPC t z)
(use-package olivetti
  :ensure t
  :custom
  (olivetti-body-width 80)
  :config
  ;; Narrow page for prose in org; other buffers keep the default (80)
  (add-hook 'org-mode-hook (lambda () (setq-local olivetti-body-width 60)))
  (defvar-local my/olivetti--line-numbers nil
    "Value of `display-line-numbers' before olivetti-mode was entered.")
  (add-hook 'olivetti-mode-hook
            (lambda ()
              (if olivetti-mode
                  (progn (setq my/olivetti--line-numbers display-line-numbers)
                         (setq-local display-line-numbers nil
                                     show-trailing-whitespace nil
                                     mode-line-format nil)
                         (text-scale-set 2))
                (text-scale-set 0)
                (setq-local display-line-numbers my/olivetti--line-numbers)
                (kill-local-variable 'show-trailing-whitespace)
                (kill-local-variable 'mode-line-format)))))

;; Evil
(use-package evil
  :init
  (setopt evil-want-keybinding nil        ; required by evil-collection
          evil-want-integration t
          evil-want-C-u-scroll t
          evil-want-Y-yank-to-eol t
          evil-undo-system 'undo-redo     ; Emacs 28+ native undo/redo
          evil-search-module 'evil-search
          evil-respect-visual-line-mode t)
  :config
  (evil-mode 1))

(use-package evil-collection
  :after evil
  :init (setopt evil-collection-setup-minibuffer t)
  :config (evil-collection-init))

(use-package evil-nerd-commenter
  :config
  (evil-define-key '(normal visual) 'global
    "gc" #'evilnc-comment-operator))

;; No mouse: clicks, drags and wheel/trackpad scrolling
(use-package disable-mouse
  :after evil
  :config
  (disable-mouse-global-mode 1)
  (mapc #'disable-mouse-in-keymap
        (list evil-motion-state-map evil-normal-state-map
              evil-visual-state-map evil-insert-state-map)))

;; Completion (vertico + orderless + marginalia + consult)
(require 'vertico)
(vertico-mode 1)

(require 'orderless)
(setq completion-styles '(orderless basic)
      completion-category-defaults nil
      completion-category-overrides '((file (styles basic partial-completion))))

(require 'marginalia)
(marginalia-mode 1)

(require 'consult)

(require 'which-key)
(which-key-mode 1)

(require 'general)
(general-evil-setup)
(general-override-mode 1)

;; Formatting
(use-package apheleia
  :ensure t
  :config
  (apheleia-global-mode +1)
  (dolist (mode '(js-json-mode json-mode json-ts-mode))
    (setf (alist-get mode apheleia-mode-alist) 'oxfmt)))

;; PDF
(use-package pdf-tools
  :ensure t
  :mode ("\\.pdf\\'" . pdf-view-mode)
  :config
  ;; epdfinfo is prebuilt by Nix, so this just activates pdf-tools.
  (pdf-tools-install :no-query)
  ;; Upstream bug: `pdf-links-read-link-action' (F) calls
  ;; `pdf-roll-page-overlay' unconditionally, but pdf-roll is only
  ;; autoloaded via `pdf-view-roll-minor-mode'. Load it eagerly; outside
  ;; roll mode it just finds the single-page overlay.
  (require 'pdf-roll)
  (setq-default pdf-view-display-size 'fit-page)
  (setq pdf-view-use-scaling t          ; sharp rendering on HiDPI/Retina
        pdf-view-resize-factor 1.1
        pdf-annot-activate-created-annotations t)

  ;; Link hints (F) are drawn by ImageMagick, whose Nix build finds no
  ;; fontconfig config and so has no default font; name one explicitly.
  ;; `magick' rather than the deprecated IMv7 `convert' alias.
  (setq pdf-util-convert-program (executable-find "magick")
        pdf-links-read-link-convert-commands
        '("-font" "/System/Library/Fonts/Menlo.ttc"
          "-pointsize" "%P" "-undercolor" "%f" "-fill" "%b"
          "-draw" "text %X,%Y '%c'"))

  ;; Upstream bug: `pdf-view-new-window-function' calls
  ;; `image-mode-window-put' without its WINPROPS arg, so the new
  ;; overlay can land in whatever window happens to be selected
  ;; (e.g. the frame's other pane) instead of the window it was just
  ;; created for. Symptom: opening a pdf-view buffer in a second
  ;; window, then switching that second window to another buffer,
  ;; leaves the original window's page-turning commands updating
  ;; `pdf-view-current-page'/the mode-line but never redisplaying.
  ;; Fixed upstream by passing WINPROPS through explicitly; not yet
  ;; merged (https://github.com/vedang/pdf-tools), so redefine here.
  (define-advice pdf-view-new-window-function (:override (winprops) fix-stale-overlay-window)
    (cl-assert (or (eq t (car winprops))
                   (eq (window-buffer (car winprops)) (current-buffer))))
    (let ((ol (image-mode-window-get 'overlay winprops)))
      (if ol
          (progn
            (setq ol (copy-overlay ol))
            (move-overlay ol (point-min) (point-max)))
        (setq ol (make-overlay (point-min) (point-max) nil t))
        (overlay-put ol 'pdf-view t))
      (overlay-put ol 'window (car winprops))
      (unless (windowp (car winprops))
        (cl-assert (eq t (car winprops)))
        (delete-overlay ol))
      (image-mode-window-put 'overlay ol winprops) ; <- the fix
      (dolist (ov (overlays-in (point-min) (point-max)))
        (when (and (windowp (overlay-get ov 'window))
                   (not (window-live-p (overlay-get ov 'window))))
          (delete-overlay ov)))
      (when (and (windowp (car winprops))
                 (null (image-mode-window-get 'image winprops)))
        (with-selected-window (car winprops)
          (pdf-view-goto-page
           (or (image-mode-window-get 'page t) 1))))))
  :hook (pdf-view-mode . (lambda () (display-line-numbers-mode -1))))

;; Misc.
(use-package exec-path-from-shell
  :ensure t
  :config
  ;; SSH_AUTH_SOCK points at Bitwarden's agent, for magit commit signing.
  (add-to-list 'exec-path-from-shell-variables "SSH_AUTH_SOCK")
  (when (or (memq window-system '(mac ns))
            (daemonp))
    (exec-path-from-shell-initialize)))

;; Spelling (American). jinx checks via enchant, whose en_US provider is
;; macOS's AppleSpell; Nix builds its C module against enchant.
(use-package jinx
  :ensure t
  :custom (jinx-languages "en_US")
  :hook (emacs-startup . global-jinx-mode)
  :bind ([remap ispell-word] . jinx-correct)   ; M-$ and evil's z=
  :config
  (evil-define-key 'normal 'global
    "]s" #'jinx-next
    "[s" #'jinx-previous))

;; Text-mode word completion (corfu popup) reads this list instead of
;; macOS's /usr/share/dict/web2. It is searched with `look -df',
;; so must be sorted in dictionary order. Regenerate with:
;;   aspell -d en_US dump master | aspell -l en expand \
;;     | tr ' ' '\n' | sort -df | uniq > dict/en_US.words
(setq ispell-alternate-dictionary
      (expand-file-name "dict/en_US.words" user-emacs-directory))

;; Merriam-Webster thesaurus: looks up the word at point (or the region)
;; and shows synonyms in an Org buffer. The API key lives in the
;; git-ignored secrets.el; without it the package's bundled key is used.
(use-package mw-thesaurus
  :ensure t
  :commands mw-thesaurus-lookup-dwim
  :config
  (load (expand-file-name "secrets.el" user-emacs-directory) t)
  ;; evil's normal-state `q' (macro record) would shadow the mode's own `q'
  (evil-define-key 'normal mw-thesaurus-mode-map "q" #'mw-thesaurus--quit))

(setq shell-file-name (executable-find "sh"))

(setq ring-bell-function 'ignore)

(use-package evil-mc :ensure t)

(provide 'editor)
