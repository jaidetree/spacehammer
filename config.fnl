(local windows (require :windows))

(fn reload-config
  []
  (hs.reload))

(fn clear-console
  []
  (hs.console.clearConsole))

(fn say-hi
  []
  (alert "Hello there!"))

(fn activate-alfred
  []
  (windows.activate-app "Alfred 4"))


(local menu-items
       [{:key :space
         :title "Alfred"
         :action activate-alfred}
        {:key :m
         :title "Multimedia"
         :enter (fn [menu]
                  (print "Entering menu: " (hs.inspect menu)))
         :exit (fn [menu]
                 (print "Exiting menu: " (hs.inspect menu)))
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
                  :repeatable true}]}
        {:key :w
         :title "Window"
         :items [{:key :l
                  :title "Layouts"
                  :items [{:key :1
                           :title "Full-screen"
                           :action "mosaic:full-size"
                           :repeatable true}
                          {:key :2
                           :title "Left Half"
                           :action "mosaic:left-half"
                           :repeatable true}
                          {:key :3
                           :title "Right Half"
                           :action "mosaic:right-half"
                           :repeatable true}
                          {:key :4
                           :title "Left Big"
                           :action "mosaic:left-big"
                           :repeatable true}
                          {:key :5
                           :title "Right Small"
                           :action "mosaic:right-small"
                           :repeatable true}]}]}
        {:key :z
         :title "Zoom"
         :items [{:key :a
                  :title "Mute or Unmute Audio"
                  :action "zoom:mute-or-unmute-audio"}
                 {:key :v
                  :title "Start or Stop Video"
                  :action "zoom:start-or-stop-video"}
                 {:key :s
                  :title "Start or Stop Sharing"
                  :action "zoom:start-or-stop-sharing"}
                 {:key :f
                  :title "Pause or Resume Sharing"
                  :action "zoom:pause-or-resume-sharing"}
                 {:key :i
                  :title "Invite..."
                  :action "zoom:invite"}
                 {:key :l
                  :title "End Meeting"
                  :action "zoom:end-meeting"}]}])

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
         :items [{:key :r
                  :title "Reload Config"
                  :action reload-config}
                 {:key :c
                  :title "Console"
                  :items [{:key :c
                           :title "Clear"
                           :action clear-console}]}]
         :keys [{:mods [:cmd]
                 :key :y
                 :action (fn []
                           (alert "Hi Hammerspoon"))}]}
        {:key "Emacs"
         :items [{:key :h
                  :title "Say hi"
                  :action say-hi}]
         :keys [{:key :y
                 :mods [:cmd]
                 :action (fn []
                           (alert "Hi Emacs"))}]}])

(local config
        {:title "Main Menu"
         :items menu-items
         :keys common-keys
         :apps apps})


config
