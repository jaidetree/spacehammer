(local atom (require :atom))
(local statemachine (require :statemachine))
(local windows (require :windows))
(local {:concat concat
        :filter filter
        :find find
        :join join
        :map map
        :merge merge
        :reduce reduce
        :split split
        :tap tap} (require :functional))


(var fsm nil)

;; Menu Column Alignment
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(fn max-length
  [items]
  (reduce
   (fn [max [key _]]  (math.max max (# key)))
   0
   items))


(fn pad-str
  [char max str]
  (let [diff (- max (# str))]
    (.. str (string.rep char diff))))


(fn align-columns
  [items]
  (let [max (max-length items)]
    (map
     (fn [[key action]]
       (.. (pad-str " " max key) " - " action))
     items)))


;; Timers & Delays
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(fn timeout
  [f]
  (let [task (hs.timer.doAfter 2 f)]
    (fn destroy-task
      []
      (when task
        (: task :stop)
        nil))))


;; Event Dispatchers
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(fn activate-modal
  [menu-key]
  (fsm.dispatch :activate menu-key))


(fn deactivate-modal
  []
  (fsm.dispatch :deactivate))


(fn start-modal-timeout
  []
  (fsm.dispatch :start-timeout))


;; Menu & Action Trigger Handlers
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(fn create-action-fn
  [action]
  (let [[file fn-name] (split "/" action)]
    (fn []
      (let [module (require file)]
        (: module fn-name)))))

(fn action->fn
  [action]
  (match (type action)
    :function action
    :string (create-action-fn action)
    _         (do
                (print (string.format
                        "ERROR: Could not create action handler for %s"
                        (hs.inspect action)))
                (fn [] true))))


(fn create-action-trigger
  [{:action action :repeatable repeatable}]
  (let [action-fn (action->fn action)]
    (fn []
      (if repeatable
          (start-modal-timeout)
          (deactivate-modal))
      (hs.timer.doAfter 0.01 action-fn))))


(fn create-menu-trigger
  [key]
  (fn []
    (fsm.dispatch :activate key)))


;; Key Bindings
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(fn query-bindings
  [type-key items]
  (->> items
       (filter (fn [item] (. item type-key)))))


(fn bind-actions
  [menu]
  (->> (query-bindings :action menu)
       (map (fn [item]
              {:key (. item :key)
               :action (create-action-trigger item)}))))


(fn bind-menus
  [menu]
  (->> (query-bindings :items menu)
       (map (fn [{:key key}]
              {:key key
               :action (create-menu-trigger key)}))))


(fn menu->bindings
  [items]
  (let [action-bindings (bind-actions items)
        menu-bindings (bind-menus items)]
    (concat [] action-bindings menu-bindings)))


(fn bind-keys
  [items]
  (let [modal (hs.hotkey.modal.new [] nil)]
    (each [_ item (ipairs items)]
      (let [{:key key
             :mods mods
             :action action} item
            mods (or mods [])
            action-fn (action->fn action)]
        (: modal :bind mods key action-fn)))
    (: modal :enter)
    (fn destroy-bindings
      []
      (when modal
        (: modal :exit)
        (: modal :delete)))))

(fn bind-menu-keys
  [items]
  (bind-keys
   (concat (menu->bindings items)
           [{:key :ESCAPE
             :action deactivate-modal}])))

(fn bind-app-keys
  [items]
  (let [modal (hs.hotkey.modal.new [] nil)]
    (each [_ item (ipairs items)]
      (let [{:key key
             :mods mods
             :action action} item
            mods (or mods [])
            action-fn (action->fn action)]
        (: modal :bind mods key action-fn)))
    (: modal :enter)
    (fn destroy-bindings
      []
      (when modal
        (: modal :exit)
        (: modal :delete)))))

(fn bind-global-keys
  [items]
  (each [_ item (ipairs items)]
    (let [{:key key} item
          mods (or item.mods [])
          action-fn (action->fn item.action)]
      (hs.hotkey.bind mods key action-fn))))


;; Display Modals
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(fn modal-alert
  [menu]
  (let [items (->> (. menu :items)
                   (map (fn [item]
                          [(. item :key) (. item :title)]))
                   (align-columns))
        text (join "\n" items)]
    (hs.alert.closeAll)
    (alert text
           {:textFont "Courier New"
            :radius 0
            :strokeWidth 0}
           99999)))


(fn show-modal-menu
  [{:menu menu
    :unbind-keys unbind-keys
    :stop-timeout stop-timeout}]
  (when unbind-keys
    (unbind-keys))
  (when stop-timeout
    (stop-timeout))
  (modal-alert menu)
  {:menu menu
   :stop-timeout :nil
   :unbind-keys (bind-menu-keys menu.items)})


;; Menus, & Config Navigation
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(fn find-menu
  [target menus]
  (find
   (fn [item]
     (= (. item :key) target))
   menus))


(fn get-menu
  [parent group target]
  (find-menu target (. parent group)))


;; State Transitions
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(fn idle->active
  [state data]
  (let [{:config config
         :app app} state
        menu (if app
                 (get-menu config :apps app)
                 config)]
    (merge {:status :active}
           (show-modal-menu {:menu menu}))))


(fn idle->enter-app
  [state app-name]
  (let [{:config config
         :app app
         :unbind-app-keys unbind-app-keys} state
        app-menu (find-menu app-name config.apps)]
    (when app-menu
      (when unbind-app-keys (unbind-app-keys))
      {:app app-name
       :unbind-app-keys (bind-app-keys app-menu.keys)})))


(fn idle->leave-app
  [state app-name]
  (let [{:app current-app
         :unbind-app-keys unbind-app-keys} state]
    (if (= current-app app-name)
        (when unbind-app-keys (unbind-app-keys))
        {:app :nil
         :unbind-app-keys :nil}
        nil)))


(fn active->idle
  [state data]
  (hs.alert.closeAll)
  (when state.stop-timeout
    (state.stop-timeout))
  {:status :idle
   :menu :nil
   :stop-timeout :nil
   :unbind-keys (state.unbind-keys)})


(fn active->active
  [state menu-key]
  (let [{:config config
         :menu menu
         :stop-timeout stop-timeout
         :unbind-keys unbind-keys} state
        menu (if menu-key
                 (get-menu menu :items menu-key)
                 config)]
    (merge state
           {:status :active}
           (show-modal-menu {:stop-timeout stop-timeout
                             :unbind-keys  unbind-keys
                             :menu         menu}))))


(fn active->timeout
  [state]
  (when state.stop-timeout
    (state.stop-timeout))
  {:stop-timeout (timeout deactivate-modal)})


(fn active->enter-app
  [state app-name]
  (let [{:config config
         :app app
         :stop-timeout stop-timeout
         :unbind-keys unbind-keys
         :unbind-app-keys unbind-app-keys} state
        menu (get-menu config :apps app-name)]
    (if menu
        (do
          (when unbind-app-keys (unbind-app-keys))
          (merge {:status :active
                  :app    app-name
                  :unbind-app-keys (bind-app-keys menu.keys)}
                 (show-modal-menu {:stop-timeout stop-timeout
                                   :unbind-keys  unbind-keys
                                   :menu         menu})))
        nil)))


(fn active->leave-app
  [state app-name]
  (let [{:config       config
         :app          current-app
         :stop-timeout stop-timeout
         :unbind-keys  unbind-keys
         :unbind-app-keys unbind-app-keys} state]
    (if (= current-app app-name)
        (do
          (when unbind-app-keys (unbind-app-keys))
          (merge {:menu :nil
                  :app  :nil
                  :unbind-app-keys :nil}
                 (show-modal-menu {:stop-timeout stop-timeout
                                   :unbind-keys  unbind-keys
                                   :menu         config})))
        nil)))


;; Finite State Machine States
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(local states
       {:idle   {:activate      idle->active
                 :enter-app     idle->enter-app
                 :leave-app     idle->leave-app}
        :active {:deactivate    active->idle
                 :activate      active->active
                 :enter-app     active->enter-app
                 :leave-app     active->leave-app
                 :start-timeout active->timeout}})


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
        (fsm.dispatch :enter-app app-name)
        (= event-type :deactivated)
        (fsm.dispatch :leave-app app-name))))


(fn start-logger
  [fsm]
  (atom.add-watch
   fsm.state :log-state
   (fn log-state
     [state]
     (print "state is now: " state.status)
     (print "app is now: " state.app))))


(fn active-app-name
  []
  (let [app (hs.application.frontmostApplication)]
    (if app
        (: app :name)
        nil)))


;; Initialization
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(fn init
  [config]
  (let [active-app (active-app-name)
        app-menu (find-menu active-app config.apps)
        initial-state {:status :idle
                       :config config
                       :app (when app-menu active-app)
                       :menu nil
                       :unbind-keys nil
                       :unbind-app-keys nil
                       :stop-timeout nil}
        menu-hotkey (hs.hotkey.bind [:cmd] :space activate-modal)
        app-watcher (hs.application.watcher.new watch-apps)]
    (set fsm (statemachine.new states initial-state :status))
    (bind-global-keys (or config.keys []))
    (start-logger fsm)
    (: app-watcher :start)
    (fn cleanup []
      (: menu-hotkey :delete)
      (: app-watcher :stop))))


{:init init}
