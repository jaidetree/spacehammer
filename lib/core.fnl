(local fennel (require :fennel))
(require-macros :lib.macros)
(hs.console.clearConsole)
(hs.ipc.cliInstall) ; ensure CLI installed

;; Make private folder override repo files
(tset fennel :path (.. "./private/?.fnl;" fennel.path))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; defaults
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(set hs.hints.style :vimperator)
(set hs.hints.showTitleThresh 4)
(set hs.hints.titleMaxSize 10)
(set hs.hints.fontSize 30)
(set hs.window.animationDuration 0.2)

(global alert (fn 
                [str style seconds]
                (hs.alert.show str
                               style
                               (hs.screen.primaryScreen)
                               seconds)))
(global log (fn [s] (print (hs.inspect s) 5)))
(global fw hs.window.focusedWindow)

(fn file-exists?
  [filepath]
  (let [file (io.open filepath "r")]
    (when file
      (io.close file))
    (~= file nil)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; auto reload config
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(global
 config-file-pathwatcher
 (hs.pathwatcher.new
  hs.configdir
  (fn [files]
    (let [u hs.fnutils
          fnl-file-change? (u.some
                            files
                            (fn [p]
                              (when (not (string.match p ".#")) ;; ignore emacs temp files
                                (let [ext (u.split p "%p")]
                                  (or (u.contains ext "fnl")
                                      (u.contains ext "lua"))))))]
      (when fnl-file-change? (hs.reload))))))

(: config-file-pathwatcher :start)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Set utility keybindings
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


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


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Load private init.fnl file (if it exists)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(when (file-exists? (.. hs.configdir "/private/init.fnl"))
  (require :private))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Initialize Modals & Apps
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(local config (if (file-exists? (.. hs.configdir "/private/config.fnl"))
                  (require :private.config)
                  (require :config)))

(local modal (require :lib.modal))
(local apps (require :lib.apps))
(modal.init config)
(apps.init config)
