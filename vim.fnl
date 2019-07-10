(local atom (require :lib.atom))
(local {:call-when call-when} (require :lib.functional))
(local machine (require :lib.statemachine))
(local {:bind-keys bind-keys} (require :lib.bind))
(local log (hs.logger.new "keybindings.fnl" "debug"))

;; Debug
(local hyper (require :lib.hyper))

(var fsm {})

(local shape {:x 900
              :y 900
              :h 40
              :w 180})
(local text (hs.drawing.text shape ""))
(local box (hs.drawing.rectangle shape))

(: text :setBehaviorByLabels [:canJoinAllSpaces
                              :transient])

(: box :setBehaviorByLabels [:canJoinAllSpaces
                             :transient])

(: text :setLevel :overlay)
(: box :setLevel :overlay)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Actions
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(fn disable
  []
  (: box :hide)
  (: text :hide)
  (fsm.dispatch :disable))

(fn enable
  []
  (fsm.dispatch :enable))

(fn normal
  []
  (fsm.dispatch :normal))

(fn visual
  []
  (fsm.dispatch :visual))

(fn insert
  []
  (fsm.dispatch :insert))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Helpers, Utils & Config
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(fn keystroke
  [target-mods target-key]
  (hs.eventtap.keyStroke (or target-mods []) target-key 10000))

(fn key-fn
  [target-mods target-key]
  (fn [] (keystroke target-mods target-key)))

(local bindings
       {:normal [{:key :ESCAPE
                  :action disable}
                 {:key :h
                  :action (key-fn [] :left)
                  :repeat true}
                 {:key :j
                  :action (key-fn [] :down)
                  :repeat :true}
                 {:key :k
                  :action (key-fn [] :up)
                  :repeat true}
                 {:key :l
                  :action (key-fn [] :right)
                  :repeat true}
                 {:mods [:shift]
                  :key :i
                  :action (fn []
                            (keystroke [:ctrl] :a)
                            (insert))}
                 {:key :i
                  :action insert}
                 {:key :a
                  :action (fn []
                            (keystroke nil :right)
                            (insert))}
                 {:mods [:shift]
                  :key :a
                  :action (fn []
                            (keystroke [:ctrl] :e)
                            (insert))}
                 {:key :v
                  :action visual}
                 {:key :/
                  :action (key-fn [:cmd] :f)}]
        :insert [{:key :ESCAPE
                  :action normal}]
        :visual [{:key :ESCAPE
                  :action normal}
                 {:key :h
                  :action (key-fn [:shift] :left)}
                 {:key :j
                  :action (key-fn [:shift] :down)}
                 {:key :k
                  :action (key-fn [:shift] :up)}
                 {:key :l
                  :action (key-fn [:shift] :right)}
                 {:key :y
                  :action (key-fn [:cmd]   :c)}]})

(fn key-watcher
  [])

(fn create-event-tap
  [])

(fn state-box
  [label]
  (let [frame (: (hs.screen.mainScreen) :fullFrame)
        _ (print (hs.inspect frame))
        x frame.x
        y frame.y
        width frame.w
        height frame.h
        coords {:x (+ x (- width shape.w))
                :y (+ y (- height shape.h))
                :h shape.h
                :w shape.w}]
    (: box :setFillColor {:hex "#000"
                          :alpha 0.8})
    (: box :setFill true)
    (: text :setTextColor {:hex "#FFF"
                           :alpha 1.0})
    (: text :setFrame coords)
    (: box :setFrame coords)
    (: text :setText label)
    (: text :setTextStyle {:alignment :center})
    (: box :show)
    (: text :show)
    (print (hs.inspect coords)))
  box)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Side Effects
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(fn normal-mode
  []
  (state-box "Normal")
  (bind-keys bindings.normal))

(fn insert-mode
  []
  (state-box "Insert Mode")
  (bind-keys bindings.insert))

(fn visual-mode
  []
  (state-box "Visual Mode")
  (bind-keys bindings.visual))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Transitions
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(fn disabled->normal
  [state data]
  {:mode :normal
   :unbind-keys (normal-mode)})

(fn normal->insert
  [state data]
  (call-when state.unbind-keys)
  {:mode :insert
   :unbind-keys (insert-mode)})

(fn normal->visual
  [state data]
  (call-when state.unbind-keys)
  {:mode :visual
   :unbind-keys (visual-mode)})

(fn ->disabled
  [state data]
  (call-when state.unbind-keys)
  {:mode :disabled
   :unbind-keys :nil})

(fn insert->normal
  [state data]
  (call-when state.unbind-keys)
  {:mode :normal
   :unbind-keys (normal-mode)})

(fn visual->normal
  [state data]
  (call-when state.unbind-keys)
  {:mode :normal
   :unbind-keys (normal-mode)})


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; States
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(local states
       {:disabled {:enable  disabled->normal}
        :normal   {:insert  normal->insert
                   :visual  normal->visual
                   :disable ->disabled}
        :insert   {:normal  insert->normal
                   :disable ->disabled}
        :visual   {:normal  visual->normal
                   :disable ->disabled}})


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Watchers & Logging
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(fn log-updates
  [fsm]
  (atom.add-watch fsm.state :logger
                  (fn [state]
                    (log.f "Vim mode: %s" (hs.inspect state)))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Initialize
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(fn init
  [config]
  (let [initial {:mode        :disabled
                 :unbind-keys nil}]
    (set fsm (machine.new states initial :mode))
    (log-updates fsm)
    (hyper.bind :v enable)
    (enable)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Exports
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

{:init    init
 :disable disable
 :enable  enable}
