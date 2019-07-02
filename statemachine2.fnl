(local atom (require :atom))
(local hyper (require :hyper))
(local {:merge merge} (require :functional))

(local app-state (atom.new {:state :idle
                            :paths []
                            :config {}
                            :hotkey-modal nil}))

(local states
       {:idle   {:activate   (fn idle->active
                               [state data]
                               (print "Activating root model")
                               {:state :active})}
        :active {:deactivate (fn active->idle
                               [state data]
                               (print "Deactivating modal")
                               {:state :idle})
                 :activate   (fn active->active
                               [state data]
                               (print "Activating submodal")
                               {:state :active})}})

(fn update-state
  [states state key action data]
  (let [current-fsm (. states key)]
    (if (. current-fsm action) 
        (: current-fsm action state data)
        (do
          (print (string.format "ERROR: Could not %s from %s state"
                                action key))))))

(fn dispatch
  [action data]
  (let [state (atom.deref app-state)
        key (. state :state)
        update (update-state states state key action data)]
    (when update
      (atom.swap! app-state
                  (fn [state]
                    (merge {} state update))))))


(atom.add-watch
 app-state :logger
 (fn [state]
   (print "app-state: " (hs.inspect state))))

(dispatch :activate {:context "activate"})
(dispatch :activate {:context "activate submodal"})
(dispatch :deactivate {:context "deactivate"})
(dispatch :deactivate {:context "deactivate"})
