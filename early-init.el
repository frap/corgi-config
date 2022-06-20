;;; early-init.el --- Early Customisations -*- lexical-binding: t; no-byte-compile: t; -*-
;; Copyright (C) 2001-2022 Gas

;; Author: Gas <gas@tuatara.red>
;; Version: 1.0
;; Package-Version: 0.1
;; Created: Sometime during the Covid-19 lockdown
;; Keywords: configuration, emacs
;; URL: https://github.com/frap/emacs.d
;; Package-Requires: ((emacs "27.2"))

;; Timestamp: <>
;; This file is not part of GNU Emacs.

;;; Commentary:
;; This file maybe automatically tangled from config.org.
;; Hand edits will be overwritten!
;; Je t'ai prévenu putain!

;;; Code:

(message "Chargement en cours early-init.el...")

(define-advice load (:before (feature &rest _))
    "Message the user when loading a library."
    (with-temp-message (format "En cours de chargement de la bibliothèque: '%s'" feature)))

;;; ============================================================================
;;; Emacs startup optimisations
;;; ============================================================================
  ;; Garbage collection slows down startup time, so we maximise the threshold for
  ;; it to run, and we will later reset it.
  (let ((normal-gc-cons-threshold (* 20 1024 1024))  ;; 20mb
        (init-gc-cons-threshold (* 128 1024 1024)))    ;;128mb
    (setq gc-cons-threshold init-gc-cons-threshold)
    (add-hook 'emacs-startup-hook
              (lambda () (setq gc-cons-threshold
                               normal-gc-cons-threshold))))
  ;;(setq gc-cons-threshold most-positive-fixnum)

  ;; file-name-handler-alist is consulted on various I/O functions such as
  ;; REQUIRE, slowing down startup time, so we set it to NIL, and establish a hook
  ;; to restore when Emacs is finished starting.
  (unless (or (daemonp) noninteractive)
    (let ((file-name-handler-alist/old file-name-handler-alist))
      (setq file-name-handler-alist nil)
      (add-hook 'emacs-startup-hook
                (lambda ()
                  (let ((value (delete-dups
                                (append file-name-handler-alist
                                        file-name-handler-alist/old))))
                    (setq file-name-handler-alist value))))))

  (unless (daemonp)
    (advice-add #'tty-run-terminal-initialization :override #'ignore)
    (add-hook 'window-setup-hook
              (lambda ()
                (advice-remove #'tty-run-terminal-initialization #'ignore)
                (tty-run-terminal-initialization (selected-frame) nil t))))


;;; ============================================================================
;;; Frame parameters for faster startup
;;; ============================================================================
(setq-default
 initial-frame-alist '((width . 170)
                       (height . 56)
                       (tool-bar-lines . 0)
                       (bottom-divider-width . 0)
                       (right-divider-width . 1)
                       (font . "Iosevka Slab 14"))
 default-frame-alist initial-frame-alist
 frame-inhibit-implied-resize t            ;; dont resize
 frame-resize-pixelwise t                   ;; as GUI use pixels
 x-gtk-resize-child-frames 'resize-mode
 fringe-indicator-alist (assq-delete-all 'truncation fringe-indicator-alist))

 (setq truncate-partial-width-windows nil)


(when (fboundp #'tool-bar-mode)
    (tool-bar-mode -1))

 (when (fboundp #'scroll-bar-mode)
      (scroll-bar-mode -1))


;;; ============================================================================
;;; Specify some directory paths
;;; ============================================================================

;; For the rest of the Emacs configuration, set this directory to something
;; inside the standard cache directory, so we do not pollute our emacs.d
;; directory with files that we would then have to ignore with Git.
(defconst *emacs-config/* user-emacs-directory)

(setq user-emacs-directory
      (expand-file-name "emacs/" (or (getenv "XDG_CACHE_HOME") "~/.cache/")))

;; Add our custom lisp modules to the Emacs load path so they can be discovered.
(push (expand-file-name "lisp/" (file-name-directory user-init-file)) load-path)

(defconst *emacs-autoloads-file*
    (expand-file-name "lisp/init-autoloads.el" *emacs-config/* )
    "The path to my personal autoloads file.")

(defconst *emacs-etc/* (concat user-emacs-directory "etc/")
      "Directory for non-volatile storage.
    Use this for files that don't change much, like servers binaries,
    external dependencies or long-term shared data.")

  (defconst *emacs-cache/* (concat user-emacs-directory "cache/")
      "Directory for Emacs volatile storage.
    Use this for files that change often.")

  (defconst *emacs-packages/*
      (expand-file-name (format "packages/%s.%s/"
                                emacs-major-version
                                emacs-minor-version)
                        ,user-emacs-directory )
      "Where Emacs packages are stored.")

  ;; For the rest of the Emacs configuration, set this directory to something
  ;; inside the standard cache directory, so we do not pollute our emacs.d
  ;; directory with files that we would then have to ignore with Git.
  (setq user-emacs-directory *xdg-cache/*)

  ;; For the list of native compilation ELN cache directories, delete all but the
  ;; last element, which is always assumed to be the system path, and then cons a
  ;; new path in our cache directory to the front. This effectively removes the
  ;; entry for the original ~/.emacs.d/eln-cache/ and any others that are
  ;; unwanted.
  (if (fboundp 'native-comp-available-p)
      (setq native-comp-eln-load-path
         (cons (expand-file-name "eln-cache/" *emacs-cache/* )
               (last native-comp-eln-load-path))))


(when (featurep 'native-compile)
  (defvar native-comp-deferred-compilation)
  (setq native-comp-deferred-compilation t)
  (defvar native-comp-async-report-warnings-errors)
  (setq native-comp-async-report-warnings-errors nil))


;;; ============================================================================
;;; Set up the package manager before it is loaded
;;; ============================================================================

(defvar elpa-bootstrap-p nil)

;; Pre-configure the package manager settings before it is loaded.
(setq package-enable-at-startup nil)
(setq package-quickstart nil)
(setq straight-check-for-modifications '(check-on-save find-when-checking))
(setq straight-profiles `((nil . ,(expand-file-name "lockfile" *emacs-config/* ))))

;; Bootstrap the straight.el package manager if it is not already installed,
;; then unconditionally load it. We use this rather than Emacs' built-in package
;; manager.
(defvar bootstrap-version)
(let ((bootstrap-file
       (expand-file-name "straight/repos/straight.el/bootstrap.el"
                         user-emacs-directory))
      (bootstrap-version 5))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         "https://raw.githubusercontent.com/raxod502/straight.el/develop/install.el"
         'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))

;; Additional post-setup of straight.el.
(require 'straight-x)

;;; Appendix
;; Get rid of a dumb alias.  straight-ಠ_ಠ-mode really slows down all
;; minibuffer completion functions.  Since it's a (rarely-used, even)
;; alias anyway, I just define it back to nil.  By the way, the alias
;; is `straight-package-neutering-mode'.
(defalias 'straight-ಠ_ಠ-mode nil)

(message "Chargement du early-init.el terminé!")
(provide 'early-init)
;;; early-init.el ends here
