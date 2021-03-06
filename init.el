;;; init.el --- Gas Init -*- lexical-binding: t -*-
;; This is your Emacs init file, it's where all initialisation happens. You can
;; open it any time with `SPC f e i' (file-emacs-init)

;;; Code:
(defmacro with-message! (message &rest body)
  "Execute BODY, with MESSAGE.
      If body executes without errors, ** MESSAGE... terminé will be displayed."
  (declare (indent 1))
  (let ((msg (gensym)))
    `(let ((,msg ,message))
       (unwind-protect (progn (message "%s..." ,msg)
			      ,@body)
	 (message "** %s... terminé!!" ,msg)))))

;;; Emacs load PATH
(require 'subr-x)
;;; Set up extra load paths and functionality
;; Since we might be running in CI or other environments, stick to
;; XDG_CONFIG_HOME value if possible.
;;(let ((*emacs-config-dir* (if-let ((xdg (getenv "XDG_CONFIG_HOME")))
;;	        	      (expand-file-name "emacs/" xdg)
;;			    user-emacs-directory)))
;; Add Lisp directory to `load-path'.
;; (add-to-list 'load-path (expand-file-name "lisp" *emacs-config-dir*)))

;;; Bootstrap
;;;
;;; ============================================================================
;;; Specify the load paths
;;; ============================================================================
;;(require 'config-path)

;;; ============================================================================
;;; Set up the package manager
;;; ============================================================================
;;(require 'init-elpa)

(require 'init-fn)

(defconst *is-gui?*     (display-graphic-p))
(defconst *is-mac?*     (eq system-type 'darwin))
(defconst *is-linux?*   (eq system-type 'gnu/linux))
(defconst *is-termux?*
  (string-suffix-p "Android" (string-trim (shell-command-to-string "uname -a"))))

;; What follows is *your* config. You own it, don't be afraid to customize it to
;; your needs. Corgi is just a set of packages. Comment out the next section and
;; you get a vanilla Emacs setup. You can use `M-x find-library' to look at the
;; package contents of each. If you want to tweak things in there then just copy
;; the code over to your `user-emacs-directory', load it with `load-file', and
;; edit it to your heart's content.

(let ((straight-current-profile 'corgi))
  ;; Change a bunch of Emacs defaults, from disabling the menubar and toolbar,
  ;; to fixing modifier keys on Mac and disabling the system bell.
  (use-package corgi-defaults)

  ;; UI configuration for that Corgi-feel. This sets up a bunch of packages like
  ;; Evil, Smartparens, Ivy (minibuffer completion), Swiper (fuzzy search),
  ;; Projectile (project-aware commands), Aggressive indent, Company
  ;; (completion).
  (use-package corgi-editor)

  ;; The few custom commands that we ship with. This includes a few things we
  ;; emulate from Spacemacs, and commands for jumping to the user's init.el
  ;; (this file, with `SPC f e i'), or opening the user's key binding or signals
  ;; file.
  (use-package corgi-commands)

  ;; Extensive setup for a good Clojure experience, including clojure-mode,
  ;; CIDER, and a modeline indicator that shows which REPLs your evaluations go
  ;; to.
  ;; Also contains `corgi/cider-pprint-eval-register', bound to `,,', see
  ;; `set-register' calls below.
  (use-package corgi-clojure)

  ;; Emacs Lisp config, mainly to have a development experience that feels
  ;; similar to using CIDER and Clojure. (show results in overlay, threading
  ;; refactorings)
  (use-package corgi-emacs-lisp)

  ;; Change the color of the modeline based on the Evil state (e.g. green when
  ;; in insert state)
  (use-package corgi-stateline
    :config
    (global-corgi-stateline-mode))

  ;; Package which provides corgi-keys and corgi-signals, the two files that
  ;; define all Corgi bindings, and the default files that Corkey will look for.
  (use-package corgi-bindings)

  ;; Corgi's keybinding system, which builds on top of Evil. See the manual, or
  ;; visit the key binding and signal files (with `SPC f e k', `SPC f e K', `SPC
  ;; f e s' `SPC f e S')
  ;; Put this last here, otherwise keybindings for commands that aren't loaded
  ;; yet won't be active.
  (use-package corkey
    :config
    (corkey-mode 1)
    ;; Automatically pick up keybinding changes
    (corkey/load-and-watch)))

;; Load other useful packages you might like to use
;; mac os X PATH

(use-package exec-path-from-shell
  :config
  (exec-path-from-shell-initialize))

;; Powerful Git integration. Corgi already ships with a single keybinding for
;; Magit, which will be enabled if it's installed (`SPC g g' or `magit-status').
(require 'init-vcs)

;; Language-specific packages
(require 'init-org) ;;(use-package org)
(use-package markdown-mode)
(use-package yaml-mode)
(use-package typescript-mode)

;; Some other examples of things you could include. There's a package for
;; everything in Emacs, so if you're missing a specific feature, see if you
;; can't find a good package that provides it.

;; Color hex color codes so you can see the actual color.
(use-package rainbow-mode)


;; REPL-driven development for JavaScript, included as an example of how to
;; configure signals, see `user-signal.el' (visit it with `SPC f e s')
(use-package js-comint)

;; Start the emacs-server, so you can open files from the command line with
;; `emacsclient -n <file>' (we like to put `alias en="emacsclient -n"' in our
;; shell config).
(server-start)

;; Emacs has "registers", places to keep small snippets of text. We make it easy
;; to run a snippet of Clojure code in such a register, just press comma twice
;; followed by the letter that designates the register (while in a Clojure
;; buffer with a connected REPL). The code will be evaluated, and the result
;; pretty-printed to a separate buffer.

;; By starting a snippet with `#_clj' or `#_cljs' you can control which type of
;; REPL it will go to, in case you have both a CLJ and a CLJS REPL connected.
(set-register ?k "#_clj (do (require 'kaocha.repl) (kaocha.repl/run))")
(set-register ?K "#_clj (do (require 'kaocha.repl) (kaocha.repl/run-all))")
(set-register ?r "#_clj (do (require 'user :reload) (user/reset))")
(set-register ?g "#_clj (user/go)")
(set-register ?b "#_clj (user/browse)")

;; We like this theme because it looks nice and works well enough in terminals,
;; swap it out with whatever suits you.
(use-package color-theme-sanityinc-tomorrow
  :config
  ;;(load-theme 'sanityinc-tomorrow-bright t)
  )

(require 'init-ui)
;;(use-package modus-themes
;;  :config
;;  (load-theme 'modus-vivendi t))
;; Maybe set a nice font to go with it
;;(set-frame-font "Iosevka Fixed SS14-14")

;; Create a *scratch-clj* buffer for evaluating ad-hoc Clojure expressions. If
;; you make sure there's always a babashka REPL connection then this is a cheap
;; way to always have a place to type in some quick Clojure expression evals.
(with-current-buffer (get-buffer-create "*scratch-clj*")
  (clojure-mode))

;; Connect to Babashka if we can find it. This is a nice way to always have a
;; valid REPL to fall back to. You'll notice that with this all Clojure buffers
;; get a green "bb" indicator, unless there's a more specific clj/cljs REPL
;; available.
(when (executable-find "bb")
  (corgi/cider-jack-in-babashka))

;; add nbb repl experience
(cider-register-cljs-repl-type 'nbb-repl "(+ 42)")

(defun mm/cider-connected-hook ()
  (when (eq 'nbb-repl cider-cljs-repl-type)
    (setq-local cider-show-error-buffer nil)
    (cider-set-repl-type 'cljs)))

(add-hook 'cider-connected-hook #'mm/cider-connected-hook)

;; Not a fan of trailing whitespace in source files, strip it out when saving.
(add-hook 'before-save-hook
          (lambda ()
            (when (derived-mode-p 'prog-mode)
              (delete-trailing-whitespace))))

;; Configure mac modifiers to be what you expect, and turn off the bell noise
(when (equal system-type 'darwin)
  (with-no-warnings
    (setq mac-command-modifier      'super
          ns-command-modifier       'super
          mac-option-modifier       'meta
          ns-option-modifier        'meta
          mac-right-option-modifier 'none
          ns-right-option-modifier  'none)))

(use-package evil-cleverparens
  :after (evil smartparens)
  :commands evil-cleverparens-mode
  :init
  (add-hook 'clojure-mode-hook #'evil-cleverparens-mode)
  (add-hook 'emacs-lisp-mode   #'evil-cleverparens-mode)
  (setq evil-cleverparens-complete-parens-in-yanked-region t)
  :config
  (setq evil-cleverparens-use-s-and-S nil)
  (evil-define-key '(normal visual) evil-cleverparens-mode-map
    "s" nil
    "S" nil
    "{" nil
    "}" nil
    "[" nil
    "]" nil
    (kbd "<tab>") 'evil-jump-item))

;; Enable our "connection indicator" for CIDER. This will add a colored marker
;; to the modeline for every REPL the current buffer is connected to, color
;; coded by type.
;;(corgi/enable-cider-connection-indicator)

;; common-lisp setup
(require 'init-clisp)
