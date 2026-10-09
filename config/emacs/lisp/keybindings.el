;;; keybindings.el -*- lexical-binding: t; -*-

(general-create-definer my/leader-def
  :states '(normal visual motion)
  :keymaps 'override
  :prefix "SPC")

(my/leader-def
  "."     '("find file" . find-file)
  ","     '("switch buffer" . consult-buffer)
  "b"     '(:ignore t :which-key "buffer")
  "b k"   '("kill buffer" . kill-buffer)
  "p"     '(:ignore t :which-key "project")
  "p f"   '("find file in project" . project-find-file)
  "p p"   '("switch project" . project-switch-project)
  "/"     '("search in project" . consult-ripgrep)
  "g"     '(:ignore t :which-key "git")
  "g g"   '("magit status" . magit-status)
  "x"     '("capture task" . my/gtd-capture-task)
  "X"     '("capture" . org-capture)
  "o"     '(:ignore t :which-key "open")
  "o a"   '("agenda" . org-agenda)
  "o g"   '(:ignore t :which-key "gtd")
  "o g w" '("week ahead" . my/gtd-week-ahead)
  "o g d" '("daily review" . my/gtd-daily-review)
  "o g i" '("inbox" . (lambda () (interactive) (find-file (+gtd-file "inbox.org"))))
  "o g n" '("next" . my/gtd-goto-next)
  "o g p" '("projects" . my/gtd-goto-projects)
  "o g r" '("recurrent" . my/gtd-goto-recurrent)
  "o g s" '("someday" . (lambda () (interactive) (find-file (+gtd-file "someday.org"))))
  "t"     '(:ignore t :which-key "toggle")
  "t z"   '("olivetti" . olivetti-mode)
  "s"     '(:ignore t :which-key "search")
  "s t"   '("thesaurus" . mw-thesaurus-lookup-dwim)
  "n"     '(:ignore t :which-key "notes")
  "n r"   '(:ignore t :which-key "roam")
  "n r f" '("find/create node" . org-roam-node-find)
  "n r i" '("insert node link" . org-roam-node-insert)
  "n j"   '("today's journal" . org-roam-dailies-goto-today)
  "n b"   '(:ignore t :which-key "bibliography")
  "n b n" '("open note" . citar-open-notes)
  "n b o" '("open resource" . citar-open)
  "n b i" '("insert citation" . citar-insert-citation))

(general-define-key
 :states '(normal visual)
 :keymaps 'LaTeX-mode-map
 :prefix "SPC m"
 "c" '("compile" . TeX-command-master)
 "v" '("view / forward search" . TeX-view)
 "e" '("insert environment" . LaTeX-environment)
 "s" '("insert section" . LaTeX-section)
 "r" '("reference" . reftex-reference)
 "b" '("citation" . citar-insert-citation)
 "l" '("show log" . TeX-recenter-output-buffer)
 "k" '("kill compilation" . TeX-kill-job))

(general-define-key
 :states '(normal visual)
 :keymaps 'org-mode-map
 :prefix "SPC m"
 "l" '("toggle latex preview" . org-latex-preview))

(general-define-key
 :states '(normal visual)
 :keymaps 'org-mode-map
 :prefix "SPC m"
 "t" '("set todo state" . org-todo)
 "d s" '("schedule" . org-schedule)
 "d d" '("deadline" . org-deadline)
 "q" '("set tags" . org-set-tags-command))

;; Restore vanilla Org's ; (evil would otherwise treat it as repeat-find-char)
(general-define-key
 :states '(normal motion)
 :keymaps 'org-agenda-mode-map
 ";" '("set timer" . org-timer-set-timer))

;; No arrow keys: show a reminder instead
(defun my/use-hjkl ()
  "Nudge away from the arrow keys."
  (interactive)
  (message "Arrows are disabled: use hjkl (or C-n / C-p)"))

(general-define-key
 :keymaps 'override
 "<up>"    #'my/use-hjkl
 "<down>"  #'my/use-hjkl
 "<left>"  #'my/use-hjkl
 "<right>" #'my/use-hjkl)

(provide 'keybindings)

;; Cmd-Q closes this client's frames (prompting to save its buffers)
;; rather than killing the launchd daemon; outside a client frame it
;; still quits Emacs. Dock "Quit" and logout go through `ns-power-off',
;; which is left alone so it can't block a macOS logout.
(global-set-key (kbd "s-q") #'save-buffers-kill-terminal)
