(local atom (require :lib.atom))
(local statemachine (require :lib.statemachine))
(local {:call-when call-when
        :concat    concat
        :find      find
        :filter    filter
        :get       get
        :has-some? has-some?
        :join      join
        :last      last
        :map       map
        :merge     merge
        :slice     slice
        :tap       tap}
       (require :lib.functional))
(local {:action->fn action->fn
        :bind-keys bind-keys}
       (require :lib.bindings))
(local lifecycle (require :lib.lifecycle))

(var fsm nil)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Event Dispatchers
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(fn enter-app
  [app-name]
  (fsm.dispatch :enter-app app-name))

(fn leave-app
  [app-name]
  (fsm.dispatch :leave-app app-name))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Set Key Bindings
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(fn bind-app-keys
  [items]
  (bind-keys items))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Apps Navigation
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(fn by-key
  [target]
  (fn [app]
    (and (= app.key target)
         (or (has-some? app.items) (has-some? app.keys)))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; State Transitions
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(fn idle->enter-app
  [state app-name]
  (let [{:apps apps
         :app prev-app
         :unbind-keys unbind-keys} state
        next-app (find (by-key app-name) apps)]
    (when next-app
      (call-when unbind-keys)
      (lifecycle.deactivate-app prev-app)
      (lifecycle.activate-app next-app)
      {:app next-app
       :unbind-keys (bind-app-keys next-app.keys)})))


(fn idle->leave-app
  [state app-name]
  (let [{:app prev-app
         :unbind-keys unbind-keys} state]
    (if (= prev-app.name app-name)
        (do (call-when unbind-keys)
            (lifecycle.deactivate-app prev-app)
            {:app :nil
             :unbind-keys :nil})
        nil)))

(fn in-app->enter-app
  [state app-name]
  (let [{:apps apps
         :app prev-app
         :unbind-keys unbind-keys} state
        next-app (find (by-key app-name) apps)]
    (if next-app
        (do
          (call-when unbind-keys)
          (lifecycle.deactivate-app prev-app)
          (lifecycle.activate-app next-app)
          {:app next-app
           :unbind-keys (bind-app-keys next-app.keys)})
        nil)))

(fn in-app->leave-app
  [state app-name]
  (let [{:apps         apps
         :app          current-app
         :unbind-keys  unbind-keys} state]
    (if (= current-app.key app-name)
        (do
          (call-when unbind-keys)
          (lifecycle.deactivate-app current-app)
          {:app :nil
           :unbind-keys :nil})
        nil)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Finite State Machine States
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(local states
       {:idle   {:enter-app      idle->enter-app
                 :leave-app      idle->leave-app}
        :in-app {:enter-app      in-app->enter-app
                 :leave-app      in-app->leave-app}})

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Watchers, Dispatchers, & Logging
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(local app-events
       {hs.application.watcher.activated   :activated
        hs.application.watcher.deactivated :deactivated
        hs.application.watcher.hidden      :hidden
        hs.application.watcher.launched    :launched
        hs.application.watcher.launching   :launching
        hs.application.watcher.terminated  :terminated
        hs.application.watcher.unhidden    :unhidden})


(fn watch-apps
  [app-name event app]
  (let [event-type (. app-events event)]
    (if (= event-type :activated)
        (enter-app app-name)
        (= event-type :deactivated)
        (leave-app app-name))))

(fn active-app-name
  []
  (let [app (hs.application.frontmostApplication)]
    (if app
        (: app :name)
        nil)))

(fn start-logger
  [fsm]
  (atom.add-watch
   fsm.state :log-state
   (fn log-state
     [state]
     (print "app is now: " (and state.app state.app.key)))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; API Methods
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(fn get-app
  []
  (when fsm
    (let [state (atom.deref fsm.state)]
      state.app)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Initialization
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(fn init
  [config]
  (let [active-app (active-app-name)
        initial-state {:apps config.apps
                       :app nil
                       :status :idle
                       :unbind-keys nil}
        app-watcher (hs.application.watcher.new watch-apps)]
    (set fsm (statemachine.new states initial-state :status))
    (start-logger fsm)
    (enter-app active-app)
    (: app-watcher :start)
    (fn cleanup []
      (: app-watcher :stop))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Exports
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


{:init init
 :get-app get-app}
