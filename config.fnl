(local windows (require :lib.windows))

;; Default Config
;; - It is not recommended to edit this file.
;; - Changes may conflict with upstream updates.
;; - Edit ~/.hammerspoon/private folder instead.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; [ ] w - windows
;; [ ] |-- cmd + hjkl - jumping
;; [ ] |-- hjkl - halves
;; [ ] |-- alt + hjkl - increments
;; [ ] |-- shift + hjkl - resize
;; [ ] |-- n, p - next, previous screen
;; [ ] |-- g - grid
;; [ ] |-- m - maximize
;; [ ] |-- u - undo
;;
;; [x] a - apps
;; [x] |-- e - emacs
;; [x] |-- g - chrome
;; [x] |-- f - firefox
;; [x] |-- i - iTerm
;; [x] |-- s - Slack
;; [x] |-- b - Brave
;;
;; [ ] j - jump
;;
;; [x] m - media
;; [x] |-- h - previous track
;; [x] |-- l - next track
;; [x] |-- k - volume up
;; [x] |-- j - volume down
;; [x] |-- s - play\pause
;; [x] |-- a - launch player
;;
;; x - emacs
;; |-- c - capture
;; |-- z - note
;; |-- f - fullscreen
;; |-- v - split

(fn activator
  [app-name]
  (fn activate []
    (windows.activate-app app-name)))

;; Config
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(local music-app
       "Spotify")


(local menu-items
       [{:key :space
         :title "Alfred"
         :action (activator "Alfred 4")}
        {:key :w
         :title "Window"
         :items [{:mods [:cmd]
                  :key :h
                  :title "Jump Left ←"
                  :action (fn [] true)}
                 {:mods [:cmd]
                  :key :j
                  :title "Jump Down ↓"
                  :action (fn [] true)}
                 {:mods [:cmd]
                  :key :k
                  :title "Jump Up ↓"}
                 {:mods [:cmd]
                  :key :l
                  :title "Jump Right →"
                  :action (fn [] true)}]}
        {:key :a
         :title "Apps"
         :items [{:key :e
                  :title "Emacs"
                  :action (activator "Emacs")}
                 {:key :g
                  :title "Chrome"
                  :action (activator "Google Chrome")}
                 {:key :f
                  :title "Firefox"
                  :action (activator "Firefox")}
                 {:key :i
                  :title "iTerm"
                  :action (activator "iTerm2")}
                 {:key :s
                  :title "Slack"
                  :action (activator "Slack")}
                 {:key :b
                  :title "Brave"
                  :action (activator "Brave")}
                 {:key :m
                  :title music-app
                  :action (activator music-app)}]}
        {:key :j
         :title "Jump"
         :action (fn [] true)}
        {:key :m
         :title "Media"
         ;; :enter (fn [menu]
         ;;          (print "Entering menu: " (hs.inspect menu)))
         ;; :exit (fn [menu]
         ;;         (print "Exiting menu: " (hs.inspect menu)))
         :items [{:key :s
                  :title "Play or Pause"
                  :action "multimedia:play-or-pause"}
                 {:key :h
                  :title "Prev Track"
                  :action "multimedia:prev-track"}
                 {:key :l
                  :title "Next Track"
                  :action "multimedia:next-track"}
                 {:key :j
                  :title "Volume Down"
                  :action "multimedia:volume-down"
                  :repeatable true}
                 {:key :k
                  :title "Volume Up"
                  :action "multimedia:volume-up"
                  :repeatable true}
                 {:key :a
                  :title (.. "Launch " music-app)
                  :action (activator music-app)}]}])

(local common-keys
       [{:mods [:cmd]
         :key "h"
         :action (fn []
                   (alert "Pressed CMD+h"))}])

(local apps
       [{:key "Hammerspoon"
         :enter (fn []
                  (print "Entering Hammerspoon :D"))
         :exit (fn []
                 (print "Exiting Hammerspoon T_T"))
         :activate (fn []
                     (print "Activating Hammerspoon"))
         :deactivate (fn []
                     (print "Deactivating Hammerspoon"))
         :items [{:key :r
                  :title "Reload Config"
                  :action hs.reload}
                 {:key :c
                  :title "Console"
                  :items [{:key :c
                           :title "Clear"
                           :action hs.console.clearConsole}]}]
         :keys [{:mods [:cmd]
                 :key :y
                 :action (fn []
                           (alert "Hi Hammerspoon"))}]}
        {:key "Emacs"
         ;; :activate (fn []
         ;;             (print "Activating Emacs"))
         ;; :deactivate (fn []
         ;;               (print "Deactivating Emacs"))
         :items []
         :keys [{:key :y
                 :mods [:cmd]
                 :action (fn []
                           (alert "Hi Emacs"))}]}])

(local config
        {:items menu-items
         :keys common-keys
         :apps apps})

;; Exports
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

config
