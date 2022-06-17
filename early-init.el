;; Even if when it's called there is no frame available yet, I found that there's
;; a small boost in the startup by disabling all this cruft before it gets even rendered:


(when (fboundp 'menu-bar-mode)
  (menu-bar-mode -1))
(when (fboundp 'tool-bar-mode)
  (tool-bar-mode -1))
(when (fboundp 'scroll-bar-mode)
  (scroll-bar-mode -1))
(when (fboundp 'horizontal-scroll-bar-mode)
  (horizontal-scroll-bar-mode -1))

(add-to-list 'load-path
             (expand-file-name "lisp" user-emacs-directory))

;; Resizing the Emacs frame can be a terribly expensive part of
;; changing the font. By inhibiting this, we easily halve startup
;; times with fonts that are larger than the system default.
(setq frame-inhibit-implied-resize t)

;; Skip garbage collections during startup to speed things up. This is optional
;; but nice to have.
(defvar op/default-gc-cons-threshold gc-cons-threshold
  "Backup of the default GC threshold.")

(defvar op/default-gc-cons-percentage gc-cons-percentage
  "Backup of the default GC cons percentage.")

(setq gc-cons-threshold most-positive-fixnum ; 2^61 bytes
      gc-cons-percentage 0.6)

;; and reset it to "normal" when done
(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold op/default-gc-cons-threshold
                  gc-cons-percentage op/default-gc-cons-percentage)))
