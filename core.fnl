(require-macros :macros)
(hs.console.clearConsole)
(hs.ipc.cliInstall) ; ensure CLI installed

;;;;;;;;;;;;;;
;; defaults ;;
;;;;;;;;;;;;;;

(set hs.hints.style :vimperator)
(set hs.hints.showTitleThresh 4)
(set hs.hints.titleMaxSize 10)
(set hs.hints.fontSize 30)
(set hs.window.animationDuration 0.2)

(global alert hs.alert.show)
(global log (fn [s] (print (hs.inspect s) 5)))
(global fw hs.window.focusedWindow)

;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  auto reload config   ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;
(global
 config-file-pathwatcher
 (hs.pathwatcher.new
  hs.configdir
  (fn [files]
    (let [u hs.fnutils
          fnl-file-change? (u.some
                            files,
                            (fn [p]
                              (when (not (string.match p ".#")) ;; ignore emacs temp files
                                (let [ext (u.split p "%p")]
                                  (or (u.contains ext "fnl")
                                      (u.contains ext "lua"))))))]
      (when fnl-file-change? (hs.reload))))))

(: config-file-pathwatcher :start)

;;;;;;;;;;;;;;;
;; Load modules
;;;;;;;;;;;;;;;

(local modules [:mosaic
                :zoom])

(each [_ module (ipairs modules)]
  (require module))

;;;;;;;;;;;;;;;;;;;;
;; Initialize modals
;;;;;;;;;;;;;;;;;;;;

(local modal (require :modals3))
(modal.init modal.config)


;;;;;;;;;;;;
;; modals ;;
;;;;;;;;;;;;
; (local modal (require :modal))

; (each [_ n (pairs [:windows
;                    :apps
;                    :multimedia
;                    :emacs
;                    :chrome
;                    :grammarly
;   (let [module (require n)]
;     (when module.add-state
;       (module.add-state modal))
;     (when module.add-app-specific
;       (module.add-app-specific))))

; (let [state-machine (modal.create-machine)]
;   (: state-machine :toMain))


; (require :keybindings)

;; toggle hs.console with Ctrl+Cmd+~
(hs.hotkey.bind
 [:ctrl :cmd] "`" nil
 (fn []
   (when-let [console (hs.console.hswindow)]
     (if (= console (hs.window.focusedWindow))
         (-> console (: :application) (: :hide))
         (-> console (: :raise) (: :focus))))))

;; disable annoying Cmd+M for minimizing windows
;; (hs.hotkey.bind [:cmd] :m nil (fn [] nil))
