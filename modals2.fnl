(local log (hs.logger.new 'modals2.fnl', 'debug'))
(local windows (require :windows))
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
        {:route []
         :active false})

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
  [modal]
  (let [menu (map (fn [[key modal]]
                    [key (. modal :title)])
                  modal)
        menu (space-columns menu)
        text (join "\n" menu)]
    (hs.alert.closeAll)
    (alert text
           {:textFont "Courier New"
            :radius 0
            :strokeWidth 0}
           3)))

(fn init-modals
  [modal]
  (hs.hotkey.bind [:cmd] :space
    (fn []
      (show-modal-menu modal))))

(fn activate-alfred
  []
  (windows.activate-app "Alfred 4"))

{:init-modals     init-modals
 :modal-paths     modal-paths}
