(local atom (require :atom))
(local hyper (require :hyper))
(local {:merge merge} (require :functional))

(local app-state (atom.new {:state :idle
                            :paths []
                            :config {}
                            :app nil
                            :menu nil
                            :hotkey-modal nil}))

(fn print-context
   [data]
   (print (. data :context)))

(fn idle->active
  [_ state data]
  (print-context data)
  {:state :active})

(fn active->idle-or-in-app
  [_ state data]
  (print-context data)
  (if (. state :app)
      {:state :in-app}
      {:state :idle}))

(fn active->active
  [_ state data]
  (print-context data)
  {:state :active})

(fn idle->in-app
  [_ state data]
  (print-context data)
  {:state :in-app
   :app (. data :app)})

(fn in-app->in-app
  [_ state data]
  (print-context data)
  {:state :active
   :app (. data :app)})

(fn in-app->active
  [_ state data]
  (print-context data)
  {:state :active
   :app (. data :app)})

(fn in-app->idle
  [_ state data]
  (print-context data)
  {:state :idle
   :app nil})

(local states
       {:idle   {:activate   idle->active
                 :enter-app  idle->in-app}
        :active {:deactivate active->idle-or-in-app
                 :activate   active->active
                 :enter-app  active->active
                 :leave-app  active->active}
        :in-app {:activate   in-app->active
                 :enter-app  in-app->in-app
                 :leave-app  in-app->idle}})

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

(dispatch :activate   {:context "Activating root modal"})
(dispatch :activate   {:context "Activating submodal"})
(dispatch :deactivate {:context "Deactivating"})
(dispatch :deactivate {:context "Deactivating"})
(dispatch :enter-app  {:context "Entering app" :app :emacs})
(dispatch :activate   {:context "Entering app modal"})
(dispatch :deactivate {:context "Exiting app modal"})
