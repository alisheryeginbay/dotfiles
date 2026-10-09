;;; projects.el -*- lexical-binding: t; -*-

(setq project-prompter #'project-prompt-project-name)  ; pick by name, not path
(setq project-mode-line t)                             ; project name in mode line
(setq project-file-history-behavior 'relativize)
(setq project-kill-buffers-display-buffer-list t)

(setq xref-search-program 'ripgrep)  ; fast project-wide grep

(keymap-global-set "C-x p b" #'consult-project-buffer)  ; consult beats the built-in switcher

;; Tab per project — the fix for window clutter
(setq tab-bar-show 1)
(defun my/project-switch-tab (dir)
  (interactive (list (funcall project-prompter)))
  (let* ((name (project-name (project-current nil dir)))
         (existing (seq-find (lambda (tab) (equal (alist-get 'name tab) name))
                             (tab-bar-tabs))))
    (if existing
        (tab-bar-switch-to-tab name)
      (tab-bar-new-tab)
      (tab-bar-rename-tab name)
      (project-switch-project dir))))
(keymap-global-set "C-x p p" #'my/project-switch-tab)

(provide 'projects)
