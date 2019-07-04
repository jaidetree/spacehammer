;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; HYPER MODE
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(global hyper (hs.hotkey.modal.new [] :F17))

(fn enter-hyper-mode
  []
  (set hyper.triggered false)
  (: hyper :enter))

(fn exit-hyper-mode
  []
  (: hyper :exit)
  (when (not hyper.triggered)
    (hs.eventtap.keyStroke [] :ESCAPE)))

(hs.hotkey.bind [] :F18 enter-hyper-mode exit-hyper-mode)

(fn hyper-bind
  [key f]
  (: hyper :bind [] key (fn []
                          (f)
                          (set hyper.triggered true))))

{:bind hyper-bind}
