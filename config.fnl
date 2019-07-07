(local windows (require :windows))
(local {:concat concat
        :filter filter
        :logf logf} (require :lib.functional))

;; Default Config
;; - It is not recommended to edit this file.
;; - Changes may conflict with upstream updates.
;; - Create a ~/.hammerspoon/private/config.fnl file instead.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Table of Contents
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; [x] w - windows
;; [x] |-- w - Last window
;; [x] |-- cmd + hjkl - jumping
;; [x] |-- hjkl - halves
;; [x] |-- alt + hjkl - increments
;; [x] |-- shift + hjkl - resize
;; [x] |-- n, p - next, previous screen
;; [x] |-- shift + n, p - up, down screen
;; [x] |-- g - grid
;; [x] |-- m - maximize
;; [x] |-- c - center
;; [x] |-- u - undo
;;
;; [x] a - apps
;; [x] |-- e - emacs
;; [x] |-- g - chrome
;; [x] |-- f - firefox
;; [x] |-- i - iTerm
;; [x] |-- s - Slack
;; [x] |-- b - Brave
;;
;; [x] j - jump
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


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Helpers
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(fn allowed-app?
  [window]
  (if (: window :isStandard)
      true
      false))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Actions
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(fn activator
  [app-name]
  (fn activate []
    (windows.activate-app app-name)))

(fn jump []
  (let [wns (->> (hs.window.allWindows)
                 (filter allowed-app?))]
    (hs.hints.windowHints wns nil true)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; General
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(local music-app
       "Spotify")

(local return
       {:key :space
        :title "Back"
        :action :previous})


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Windows
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(local window-jumps
       [{:mods [:cmd]
         :key "hjkl"
         :title "Jump"}
        {:mods [:cmd]
         :key :h
         :action "windows:jump-window-left"
         :repeatable true}
        {:mods [:cmd]
         :key :j
         :action "windows:jump-window-above"
         :repeatable true}
        {:mods [:cmd]
         :key :k
         :action "windows:jump-window-below"
         :repeatable true}
        {:mods [:cmd]
         :key :l
         :action "windows:jump-window-right"
         :repeatable true}])

(local window-halves
       [{:key "hjkl"
         :title "Halves"}
        {:key :h
         :action "windows:resize-half-left"
         :repeatable true}
        {:key :j
         :action "windows:resize-half-bottom"
         :repeatable true}
        {:key :k
         :action "windows:resize-half-top"
         :repeatable true}
        {:key :l
         :action "windows:resize-half-right"
         :repeatable true}])

(local window-increments
       [{:mods [:alt]
         :key "hjkl"
         :title "Increments"}
        {:mods [:alt]
         :key :h
         :action "windows:resize-inc-left"
         :repeatable true}
        {:mods [:alt]
         :key :j
         :action "windows:resize-inc-bottom"
         :repeatable true}
        {:mods [:alt]
         :key :k
         :action "windows:resize-inc-top"
         :repeatable true}
        {:mods [:alt]
         :key :l
         :action "windows:resize-inc-right"
         :repeatable true}])

(local window-resize
       [{:mods [:shift]
         :key "hjkl"
         :title "Resize"}
        {:mods [:shift]
         :key :h
         :action "windows:resize-left"
         :repeatable true}
        {:mods [:shift]
         :key :j
         :action "windows:resize-down"
         :repeatable true}
        {:mods [:shift]
         :key :k
         :action "windows:resize-up"
         :repeatable true}
        {:mods [:shift]
         :key :l
         :action "windows:resize-right"
         :repeatable true}])

(local window-move-screens
       [{:key "n, p"
         :title "Move next\\previous screen"}
        {:mods [:shift]
         :key "n, p"
         :title "Move up\\down screens"}
        {:key :n
         :action "windows:move-south"
         :repeatable true}
        {:key :p
         :action "windows:move-north"
         :repeatable true}
        {:mods [:shift]
         :key :n
         :action "windows:move-west"
         :repeatable true}
        {:mods [:shift]
         :key :p
         :action "windows:move-east"
         :repeatable true}])

(local window-bindings
       (concat
        [return
         {:key :w
          :title "Last Window"
          :action "windows:jump-to-last-window"}]
        window-jumps
        window-halves
        window-increments
        window-resize
        window-move-screens
        [{:key :m
          :title "Maximize"
          :action "windows:maximize-window-frame"}
         {:key :c
          :title "Center"
          :action "windows:center-window-frame"}
         {:key :g
          :title "Grid"
          :action "windows:show-grid"}
         {:key :u
          :title "Undo"
          :action "windows:undo-action"}]))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Apps Menu
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(local app-bindings
       [return
        {:key :e
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
         :action (activator music-app)}])

(local media-bindings
       [return
        {:key :s
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
         :action (activator music-app)}])


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Main Menu & Config
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(local menu-items
       [{:key :space
         :title "Alfred"
         :action (activator "Alfred 4")}
        {:key :w
         :title "Window"
         :items window-bindings}
        {:key :a
         :title "Apps"
         :items app-bindings}
        {:key :j
         :title "Jump"
         :action jump}
        {:key :m
         :title "Media"
         ;; :enter (fn [menu]
         ;;          (print "Entering menu: " (hs.inspect menu)))
         ;; :exit (fn [menu]
         ;;         (print "Exiting menu: " (hs.inspect menu)))
         :items media-bindings}])

(local common-keys
       [{:mods [:cmd]
         :key "h"
         :action (fn []
                   (alert "Pressed CMD+h"))}])


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; App Specific Config
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(local apps
       [{:key "Hammerspoon"
         ;; :enter (fn []
         ;;          (print "Entering Hammerspoon :D"))
         ;; :exit (fn []
         ;;         (print "Exiting Hammerspoon T_T"))
         ;; :activate (fn []
         ;;             (print "Activating Hammerspoon"))
         ;; :deactivate (fn []
         ;;             (print "Deactivating Hammerspoon"))
         :items []
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
       {:title "Main Menu"
        :items menu-items
        :keys common-keys
        :apps apps})

;; Exports
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

config
