(local atom (require :lib.atom))
(local hyper (require :lib.hyper))
(local {:call-when call-when
        :contains? contains?
        :eq?       eq?
        :filter    filter
        :find      find
        :has-some? has-some?
        :map       map
        :some      some} (require :lib.functional))
(local machine (require :lib.statemachine))
(local {:bind-keys bind-keys} (require :lib.bind))
(local log (hs.logger.new "vim.fnl" "debug"))

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

(var ignore-fx false)

(fn keystroke
  [target-mods target-key]
  (set ignore-fx true)
  (hs.eventtap.keyStroke (or target-mods []) target-key 10000)
  (hs.timer.doAfter 0.1 (fn [] (set ignore-fx false))))

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
                            (insert)
                            (keystroke [:ctrl] :a))}
                 {:key :i
                  :action insert}
                 {:key :a
                  :action (fn []
                            (insert)
                            (keystroke nil :right))}
                 {:mods [:shift]
                  :key :a
                  :action (fn []
                            (insert)
                            (keystroke [:ctrl] :e))}
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

(fn flags->mods
  [flags]
  (let [mods (->> flags
                  (map (fn [is-pressed mod] [mod is-pressed]))
                  (filter (fn [[mod is-pressed]] is-pressed))
                  (map (fn [[mod]] mod)))]
    (if (has-some? mods)
        mods
        nil)))

(fn by-action
  [mods key]
  (fn [item]
    (and (= key item.key)
         (eq? mods item.mods))))

(fn watch-key
  [items event]
  (let [key-code (: event :getKeyCode)
        key-str  (. hs.keycodes.map key-code)
        event-type (. hs.eventtap.event.types (: event :getType))
        mods (flags->mods (: event :getFlags))
        action-found (some (by-action mods key-str) items)
        block-input (and (~= key-str :escape)
                         (not ignore-fx)
                         (not action-found)
                         (not (contains? :fn mods))
                         (not (contains? :cmd mods))
                         (not (contains? :alt mods))
                         (not (hyper.enabled?)))]
    ;; 53 = ESCAPE
    (print key-str "\t" (hs.inspect mods))
    (print "Block input? "
           block-input)
    (values block-input {})))

(fn create-event-tap
  [items]
  (let [types hs.eventtap.event.types
        tap (hs.eventtap.new
             [types.keyDown]
             (partial watch-key items))]
    (: tap :start)
    (fn destroy
      []
      (: tap :stop))))

(fn create-screen-watcher
  [f]
  (let [watcher (hs.screen.watcher.newWithActiveScreen f)]
    (: watcher :start)
    (fn destroy []
      (: watcher :stop))))

(fn state-box
  [label]
  (let [frame (: (hs.screen.mainScreen) :fullFrame)
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
    (: text :show))
  box)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Side Effects
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(fn normal-mode
  [state]
  (state-box "Normal")
  (call-when state.untap)
  (call-when state.unbind-keys)
  {:mode :normal
   :untap (create-event-tap bindings.normal)
   :unbind-keys (bind-keys bindings.normal)
   })

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
  (normal-mode state))

(fn normal->insert
  [state data]
  (call-when state.unbind-keys)
  (call-when state.untap)
  {:mode :insert
   :unbind-keys (insert-mode)})

(fn normal->visual
  [state data]
  (call-when state.unbind-keys)
  (call-when state.untap)
  {:mode :visual
   :unbind-keys (visual-mode)})

(fn ->disabled
  [state data]
  (call-when state.unbind-keys)
  (call-when state.untap)
  {:mode :disabled
   :unbind-keys :nil})

(fn insert->normal
  [state data]
  (normal-mode state))

(fn visual->normal
  [state data]
  (normal-mode state))


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

(fn watch-screen
  [fsm active-screen-changed]
  (let [state (atom.deref fsm.state)]
    (when (~= state.mode :disabled)
      (state-box state.mode))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Initialize
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(fn init
  [config]
  (let [initial {:mode        :disabled
                 :unbind-keys nil}
        state-machine (machine.new states initial :mode)
        stop-screen-watcher (create-screen-watcher
                             (partial watch-screen state-machine))]
    (set fsm state-machine)
    (log-updates fsm)
    (enable)
    (fn []
      (stop-screen-watcher))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Exports
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

{:init    init
 :disable disable
 :enable  enable}
