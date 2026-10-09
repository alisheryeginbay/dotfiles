;;; org-config.el -*- lexical-binding: t; -*-

;; Org / GTD
(setq org-directory "~/org/")

;; LaTeX fragments. dvisvgm gives crisp previews at any zoom; the default
;; :scale 1.0 renders tiny against a 150-height default face, and
;; `org-format-latex-options' already inherits theme colours via the `default'
;; foreground/background, so scale is the only thing worth overriding.
(setq org-preview-latex-default-process 'dvisvgm)

(with-eval-after-load 'org
  (plist-put org-format-latex-options :scale 1.2))

;; cdlatex's math entry inside Org LaTeX fragments (` for symbols, TAB through
;; templates). Previews stay manual: `org-startup-with-latex-preview' is left
;; off, so only files declaring `#+STARTUP: latexpreview' render on open.
(add-hook 'org-mode-hook #'turn-on-org-cdlatex)

;; Soft-wrap prose instead of letting long paragraphs run off screen.
;; `evil-respect-visual-line-mode' (lisp/editor.el) is on, so j/k and $/0
;; move by screen line rather than by logical line.
(add-hook 'org-mode-hook #'visual-line-mode)

(defvar +gtd-directory (expand-file-name "gtd/" org-directory)
  "Directory holding the GTD org files (inbox, gtd, someday).")

(defun +gtd-file (name)
  "Return the absolute path of NAME inside `+gtd-directory'."
  (expand-file-name name +gtd-directory))

(setq org-archive-location (concat (+gtd-file "archive.org") "::* From %s"))

(unless (file-directory-p +gtd-directory)
  (make-directory +gtd-directory t))

(defvar my/reading-file (expand-file-name "reading.org" org-directory)
  "Org file tracking books, one top-level heading per book.")

(defconst my/reading-date-props '("DATE_ADDED" "DATE_STARTED" "DATE_READ")
  "Book properties holding an inactive date stamp like [2026-10-08 Thu].")

(defun my/reading-date-problem (value)
  "Return why VALUE isn't a valid book date, or nil if it's fine or empty."
  (unless (or (null value) (string-empty-p value))
    (if (not (string-match
              "\\`\\[\\([0-9]\\{4\\}\\)-\\([0-9]\\{2\\}\\)-\\([0-9]\\{2\\}\\)\\(?: [A-Za-z]+\\)?\\]\\'"
              value))
        "must look like [YYYY-MM-DD Day]"
      (let ((date (list (string-to-number (match-string 2 value))
                        (string-to-number (match-string 3 value))
                        (string-to-number (match-string 1 value)))))
        (unless (calendar-date-is-valid-p date)
          "is not a real calendar date")))))

(defun my/reading-normalize ()
  "Give every book AUTHOR and RATING properties; flag bad ratings and dates.
Missing properties are added empty.  A rating outside 1-10 or a malformed
DATE_ADDED / DATE_STARTED / DATE_READ moves point to the first offending
book and raises a warning (errors in `before-save-hook' are demoted, so
the save itself can't be blocked)."
  (let (bad)
    (org-map-entries
     (lambda ()
       (dolist (prop '("AUTHOR" "RATING"))
         (unless (org-entry-get nil prop)
           (org-entry-put nil prop "")))
       (unless bad
         (let ((rating (org-entry-get nil "RATING")))
           (unless (or (string-empty-p rating)
                       (string-match-p "\\`\\([1-9]\\|10\\)\\'" rating))
             (setq bad (list (point) "RATING must be 1-10 or empty, got %S" rating)))))
       (dolist (prop my/reading-date-props)
         (let* ((value (org-entry-get nil prop))
                (problem (my/reading-date-problem value)))
           (when (and problem (not bad))
             (setq bad (list (point) (concat prop " %S " problem) value))))))
     "LEVEL=1")
    (when bad
      (goto-char (car bad))
      (display-warning 'reading
                       (concat (org-get-heading t t t t) ": "
                               (apply #'format (cdr bad)))))))

(defun my/reading-today-stamp ()
  "Return today's date as an inactive Org stamp.
Uses `org-today', so like capture's %u it honours `org-extend-today-until'."
  (let ((today (calendar-gregorian-from-absolute (org-today))))
    (format-time-string
     (org-time-stamp-format nil t)
     (encode-time 0 0 0 (nth 1 today) (nth 0 today) (nth 2 today)))))

(defun my/reading-on-state-change ()
  "Stamp book dates as the TODO state changes.
READING stamps DATE_STARTED, unless the book already has one (pausing
and resuming keeps the first start).  READ and ABANDONED ask for a
RATING and stamp DATE_READ, the date the book was finished with either
way."
  (pcase org-state
    ("READING"
     (when (string-empty-p (or (org-entry-get nil "DATE_STARTED") ""))
       (org-entry-put nil "DATE_STARTED" (my/reading-today-stamp))))
    ((or "READ" "ABANDONED")
     (let ((rating (completing-read "Rating (1-10, empty to skip): "
                                    (mapcar #'number-to-string (number-sequence 1 10))
                                    nil t)))
       (unless (string-empty-p rating)
         (org-entry-put nil "RATING" rating))
       (org-entry-put nil "DATE_READ" (my/reading-today-stamp))))))

(defun my/reading-setup ()
  "Normalize book properties on save and stamp dates on state changes when visiting
`my/reading-file'."
  (when (and buffer-file-name (file-equal-p buffer-file-name my/reading-file))
    ;; Book tags describe the book, not its Review / Close Reading
    ;; subheadings, so they shouldn't leak into tag searches.
    (setq-local org-use-tag-inheritance nil)
    (add-hook 'before-save-hook #'my/reading-normalize nil t)
    (add-hook 'org-after-todo-state-change-hook #'my/reading-on-state-change nil t)))

(add-hook 'org-mode-hook #'my/reading-setup)

(defvar my/movies-file (expand-file-name "movies.org" org-directory)
  "Org file tracking movies, one top-level heading per movie.")

(defun my/movies-on-state-change ()
  "Ask for a RATING and stamp DATE_WATCHED when a movie becomes WATCHED."
  (when (equal org-state "WATCHED")
    (let ((rating (completing-read "Rating (1-10, empty to skip): "
                                   (mapcar #'number-to-string (number-sequence 1 10))
                                   nil t)))
      (unless (string-empty-p rating)
        (org-entry-put nil "RATING" rating))
      (org-entry-put nil "DATE_WATCHED" (my/reading-today-stamp)))))

(defun my/movies-setup ()
  "Stamp dates on state changes when visiting `my/movies-file'."
  (when (and buffer-file-name (file-equal-p buffer-file-name my/movies-file))
    (setq-local org-use-tag-inheritance nil)
    (add-hook 'org-after-todo-state-change-hook #'my/movies-on-state-change nil t)))

(add-hook 'org-mode-hook #'my/movies-setup)

;; Capture: everything lands unsorted in inbox.org (books and movies go
;; straight to reading.org / movies.org) and gets triaged during review with `org-refile'.
;; %U stamps when it was captured, %i pulls in the active region, %a links
;; back to wherever capture was invoked from.
(setq org-capture-templates
      `(("t" "Task" entry (file ,(+gtd-file "inbox.org"))
         "* TODO %?\n%U\n%i")
        ("l" "Task linked to here" entry (file ,(+gtd-file "inbox.org"))
         "* TODO %?\n%U\n%a\n%i")
        ("i" "Idea")
        ("ie" "Personal essay" entry
         (file+headline ,(expand-file-name "ideas.org" org-directory) "Personal essay")
         "* %?\n%U\n%i")
        ("is" "Science fiction" entry
         (file+headline ,(expand-file-name "ideas.org" org-directory) "Science fiction")
         "* %?\n%U\n%i")
        ("io" "Other" entry
         (file+headline ,(expand-file-name "ideas.org" org-directory) "Other")
         "* %?\n%U\n%i")
        ("r" "Reading")
        ("rb" "New book" entry (file ,(expand-file-name "reading.org" org-directory))
         "* TO-READ %^{Title}\n:PROPERTIES:\n:AUTHOR:   %^{Author}\n:RATING:   \n:DATE_ADDED: %u\n:END:\n** Review\n** Close Reading"
         :immediate-finish t)
        ("m" "New movie" entry (file ,my/movies-file)
         "* TO-WATCH %^{Title}\n:PROPERTIES:\n:RATING:   \n:DATE_ADDED: %u\n:END:\n** Review"
         :immediate-finish t)))

;; Start typing immediately in the capture buffer instead of in normal state.
(add-hook 'org-capture-mode-hook #'evil-insert-state)

(defun my/gtd-capture-task ()
  "Capture a TODO into the inbox, skipping the template menu."
  (interactive)
  (org-capture nil "t"))

(defun my/gtd-goto-section (section)
  "Open gtd.org and narrow to the SECTION headline."
  (find-file (+gtd-file "gtd.org"))
  (widen)
  (goto-char (or (org-find-exact-headline-in-buffer section) (point-min)))
  (org-narrow-to-subtree))

(defun my/gtd-goto-next () (interactive) (my/gtd-goto-section "Next"))
(defun my/gtd-goto-projects () (interactive) (my/gtd-goto-section "Projects"))
(defun my/gtd-goto-recurrent () (interactive) (my/gtd-goto-section "Recurrent"))
(defun my/gtd-habits () (interactive) (org-agenda nil "h"))
(defun my/gtd-week-ahead () (interactive) (org-agenda nil "w"))
(defun my/gtd-daily-review () (interactive) (org-agenda nil "d"))

(defun +gtd-files ()
  "Return every org file under `+gtd-directory'."
  (directory-files +gtd-directory t "\\.org\\'"))

(with-eval-after-load 'org
  ;; Entries with `:STYLE: habit' get a consistency graph in the agenda.
  (add-to-list 'org-modules 'org-habit)
  (require 'org-habit)
  (setq org-agenda-files (mapcar #'+gtd-file '("inbox.org" "gtd.org")))
  ;; Refile anywhere in the GTD directory, not just the agenda files, so
  ;; anything added later is a target without extra config.
  (setq org-refile-targets '((+gtd-files :maxlevel . 3))
        org-refile-use-outline-path 'file
        org-outline-path-complete-in-steps nil
        org-refile-allow-creating-parent-nodes 'confirm)
  (setq org-todo-keywords
        '((sequence "TODO(t)" "NEXT(n)" "PROJ(p)" "WAIT(w@/!)" "|" "DONE(d!)" "KILL(k@)")))
  ;; State-change notes and timestamps (the ! and @ above, repeater resets on
  ;; habits) go into a folded :LOGBOOK: drawer instead of cluttering the entry.
  (setq org-log-into-drawer t)
  ;; A parent can't be marked DONE while it has open children, and under an
  ;; :ORDERED: t parent each child is blocked until its earlier siblings are done.
  (setq org-enforce-todo-dependencies t)
  ;; Chime when a timer ends or a clocked task hits its effort estimate.
  ;; Emacs on macOS has no sound support, so play the file with afplay.
  (setq org-clock-sound "/System/Library/Sounds/Glass.aiff")
  (advice-add 'org-clock-play-sound :before-until
              (lambda (&optional clock-sound)
                (let ((sound (or clock-sound org-clock-sound)))
                  (when (and (stringp sound) (executable-find "afplay"))
                    (start-process "org-clock-sound" nil "afplay"
                                   (expand-file-name sound))))))
  ;; The day ends at 4am: late-night agenda views and DONE timestamps (and so
  ;; habit streaks) still count toward the previous day.
  (setq org-extend-today-until 4
        org-use-effective-time t))

(with-eval-after-load 'org-agenda
  (require 'org-super-agenda)
  (add-hook 'org-agenda-mode-hook (lambda () (display-line-numbers-mode -1)))
  ;; A PROJ is stuck when nothing beneath it is a NEXT action or a WAIT.
  (setq org-stuck-projects '("/PROJ" ("NEXT" "WAIT") nil ""))
  (setq org-agenda-custom-commands
	'(("d" "Daily review"
	   ((agenda "" ((org-agenda-span 1)
			(org-agenda-overriding-header "")))
	    (todo "NEXT" ((org-agenda-overriding-header "Next actions")))
	    (tags-todo "+PRIORITY=\"A\""
                       ((org-agenda-overriding-header "High priority")
			(org-agenda-skip-function
			 '(org-agenda-skip-entry-if 'todo '("DONE" "CANCELLED")))))
	    (stuck "" ((org-agenda-overriding-header "Stuck projects"))))
	   ;; Unprocessed inbox items wait for triage instead of cluttering the day.
	   ((org-agenda-files (remove (+gtd-file "inbox.org") org-agenda-files))))
	  ("w" "This week"
	   ((agenda "" ((org-agenda-span 7)
			(org-agenda-overriding-header "The week ahead")))))))

  ;; Window behaviour
  (setq org-agenda-window-setup 'current-window
        org-agenda-restore-windows-after-quit t
        org-agenda-sticky t

        ;; Time range
        org-agenda-span 'day
        org-agenda-start-on-weekday nil
        org-agenda-start-day nil

        ;; Line format
        org-agenda-prefix-format '((agenda . "  %-12c%?-12t% s")
                                   (todo   . "  %-12c")
                                   (tags   . "  %-12c")
                                   (search . "  %-12c"))
        org-agenda-tags-column 'auto
        org-agenda-block-separator ?─
        org-agenda-scheduled-leaders '("" "%2dx: ")

        ;; Time grid
        org-agenda-time-grid '((daily today require-timed)
                               (800 1000 1200 1400 1600 1800 2000)
                               "      "
                               "──────────────")
        org-agenda-current-time-string "  ← now ────────────"
        org-agenda-timegrid-use-ampm nil

        ;; What to hide
        org-agenda-skip-scheduled-if-done t
        org-agenda-skip-deadline-if-done t
        org-agenda-skip-timestamp-if-done t
        org-agenda-skip-scheduled-if-deadline-is-shown t
        org-agenda-skip-deadline-prewarning-if-scheduled 'pre-scheduled
        ;; Hide blocked tasks (open children, ORDERED siblings, edna BLOCKERs)
        org-agenda-dim-blocked-tasks 'invisible
        org-deadline-warning-days 7

        ;; Sorting
        org-agenda-sorting-strategy '((agenda habit-down time-up deadline-up priority-down category-keep)
                                      (todo   priority-down category-keep)
                                      (tags   priority-down category-keep)
                                      (search category-keep))

        ;; Logging
        org-agenda-start-with-log-mode nil
        org-agenda-log-mode-items '(closed clock)

        ;; Performance
        org-agenda-inhibit-startup t
        org-agenda-use-tag-inheritance '(search)))

;; Bibliography (citar)
(setq citar-bibliography '("~/org/references.bib")
      citar-notes-paths '("~/org/roam/references/")
      citar-library-paths '("~/org/pdfs/"))

;; Org-roam
(setq org-roam-directory (expand-file-name "roam/" org-directory))
(org-roam-db-autosync-mode 1)

;; Org-edna: BLOCKER/TRIGGER properties for richer task dependencies
(use-package org-edna
  :ensure t
  :after org
  :config (org-edna-mode 1))

;; Org-noter
(use-package org-noter
  :ensure t
  :after org
  :config
  (setq org-noter-notes-search-path (list org-directory)
        org-noter-always-create-frame nil
        org-noter-auto-save-last-location t))

(with-eval-after-load 'org
  (org-babel-do-load-languages
   'org-babel-load-languages
   '((python . t)
     (R . t))))

(defun my/org-archive-finished ()
  "Archive all DONE and KILL entries in the current file."
  (interactive)
  (org-map-entries
   (lambda ()
     (org-archive-subtree)
     (setq org-map-continue-from
           (org-element-property :begin (org-element-at-point))))
   "/DONE|KILL" 'file))

(provide 'org-config)
