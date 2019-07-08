(local utils (require :lib.utils))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Tab Switching
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(fn simple-tab-switching
  []
  (let [tbl []]
    (each [dir key (pairs {:j "[" :k "]"})]
      (let [tf (fn [] (hs.eventtap.keyStroke [:shift :cmd] key))]
        (tset tbl dir (hs.hotkey.new [:cmd] dir tf nil tf))))
    tbl))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; App switcher
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(local switcher
       (hs.window.switcher.new
        (utils.globalFilter)
        {:textSize 12
         :showTitles false
         :showThumbnails false
         :showSelectedTitle false
         :selectedThumbnailSize 800
         :backgroundColor [0 0 0 0]}))

(fn prev-app
  []
  (: switcher :previous))

(fn next-app
  []
  (: switcher :next))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Exports
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

{:simple-tab-switching    simple-tab-switching
 :prev-app                prev-app
 :next-app                next-app}
