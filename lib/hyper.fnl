(require-macros :lib.macros)
(local {:find find} (require :lib.functional))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Hyper Mode
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; - Bind a key or a combination of keys to trigger a hyper mode.
;; - Often this is cmd+shift+alt+ctrl
;; - Or a virtual F17 key if using something like Karabiner Elements
;; - The goal is to have a mode no other apps will be listening for
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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
  (: hyper :bind nil key f)
  (fn unbind
    []
    (when-let [binding (find (fn [{:msg msg}] (= msg key)) hyper.keys)]
              (: binding :delete))))

(fn init
  [config]
  (let [h (or config.hyper {})]
    (set hyper
         (hs.hotkey.modal.new (or h.mods []) h.key))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Exports
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

{:init init
 :bind hyper-bind}
