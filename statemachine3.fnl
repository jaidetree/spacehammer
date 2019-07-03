(local atom (require :atom))
(local hyper (require :hyper))
(local {:merge merge} (require :functional))


(fn update-state
  [state-key action-name action-fn data]
  (action-fn state data)
  (if action-fn
      (action-fn state data)
      (do
        (print (string.format "ERROR: Could not %s from %s state"
                              action-name state-key)))))

(fn transition
  [action-fn state data]
  (action-fn state data))


(fn update-state
  [state-atom update]
  (atom.swap!
    state-atom
    (fn [state] (merge {} state update))))


(fn update-error
  [current-state-key action-name]
  (print (string.format "ERROR: Could not %s from %s state"
                        current-state-key action-name)))


(fn create-dispatcher
  [states state-atom state-key]
  (fn dispatch
    [_ action data]
    (let [state (atom.deref state-atom)
          key (. state state-key)
          update (-?> states
                      (. key)
                      (. action)
                      (transition state data))]
      (if update
          (do
            (update-state state-atom update)
            true)
          (do
            (update-error key action)
            false)))))


(fn create-machine
  [states initial-state state-key]
  (let [machine-state (atom.new initial-state)]
    {:dispatch (create-dispatcher states machine-state state-key)
     :states states
     :state machine-state}))

