(local atom (require :atom))
(local windows (require :windows))
(local log (hs.logger.new 'modals2.fnl', 'debug'))
(var timeout nil)

(global modal-paths
        [[:space {:title "Alfred"
                  :action "modals2/activate-alfred"}]
         [:m {:title "Multimedia"
              :menu [[:s {:title "Play or Pause"
                          :action "multimedia/play-or-pause"}]]}]
         [:z {:title "Zoom"
              :menu [[:m {:title "Mute or Unmute Audio"
                          :action "zoom/mute-or-unmute"}]]}]])
(global state
        (atom.new {:route []
                   :active false
                   :modals {}}))

(fn seq?
  [tbl]
  (~= (. tbl 1) nil))

(fn seq
  [tbl]
  (if (seq? tbl)
    (ipairs tbl)
    (pairs tbl)))

(fn reduce
  [f acc tbl]
  (var result acc)
  (each [k v (seq tbl)]
    (set result (f result v k)))
  result)

(fn map
  [f tbl]
  (reduce
    (fn [new-tbl v k]
      (table.insert new-tbl (f v k))
      new-tbl)
    []
    tbl))

(fn join
  [sep list]
  (let [last-k (# list)]
    (reduce
      (fn [str v k]
        (if (< k last-k)
          (.. str v sep)
          (.. str v)))
      ""
      list)))

(fn max-length
  [items]
  (reduce
    (fn [max [key _]]  (math.max max (# key)))
    0
    items))

(fn repeat-str
  [x str]
  (var result "")
  (for [i 1 x]
    (set result (.. result str)))
  result)

(fn pad-str
  [char max str]
  (let [diff (- max (# str))]
    (.. str (repeat-str diff char))))


(fn space-columns
  [items]
  (let [max (max-length items)]
    (map
      (fn [[key action]] (.. (pad-str " " max key) " - " action))
      items)))

(fn show-modal-menu
  [routes paths]
  (let [menu (map (fn [[key routes]]
                    [key (. routes :title)])
                  routes)
        menu (space-columns menu)
        text (join "\n" menu)]
    (hs.alert.closeAll)
    (alert text
           {:textFont "Courier New"
            :radius 0
            :strokeWidth 0}
           99999)))

(fn set-modals
  [modals]
  (atom.swap! state (fn [state]
                     (tset state :modals modals)
                     state)))

(fn activate-modal
  []
  (atom.swap! state (fn [state]
                      (tset state :active true)
                      state)))

(fn deactivate-modal
  []
  (atom.swap! state (fn [state]
                      (tset state :active false)
                      state)))

(fn remove-escape-listener
 []
 (hs.hotkey.deleteAll [] :ESCAPE))

(fn create-escape-listener
 []
 (remove-escape-listener)
 (hs.hotkey.bind [] :ESCAPE deactivate-modal))

(fn clear-timeout
 []
 (when timeout
  (: timeout :stop)
  (set timeout nil)))

(fn set-timeout
  []
  (let [timer (hs.timer.doAfter 3 deactivate-modal)]
    (clear-timeout)
    (set timeout timer)))

(fn init
  [modal]
  (set-modals modal)
  (hs.hotkey.bind [:cmd] :space
    activate-modal))

(fn activate-alfred
  []
  (windows.activate-app "Alfred 4"))

(atom.add-watch
  state :show-modals
  (fn show-modals
    [{:active active-now :route route :modals modals} {:active was-active}]
    (print "show-modals" active-now was-active)
    (when (and active-now (~= active-now was-active))
      (show-modal-menu modals route)
      (create-escape-listener)
      (set-timeout))))

(atom.add-watch
  state :hide-modals
  (fn show-modals
    [{:active active-now} {:active was-active}]
    (print "hide-modals" active-now was-active)
    (when (and (not active-now) (~= active-now was-active))
     (hs.alert.closeAll)
     (remove-escape-listener)
     (clear-timeout))))


{:init         init
 :modal-paths  modal-paths}
