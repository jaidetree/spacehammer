;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; HYPER MODE
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(var hyper nil)

(fn enter-hyper-mode
  []
  (: hyper :enter))

(fn exit-hyper-mode
  []
  (: hyper :exit))

(hs.hotkey.bind [] :F18 enter-hyper-mode exit-hyper-mode)

(fn hyper-bind
  [key f]
  (: hyper :bind [] key f))

(fn init
  [config]
  (let [h (or config.hyper {})]
    (set hyper
         (hs.hotkey.modal.new (or h.mods []) h.key))))

{:init init
 :bind hyper-bind}
