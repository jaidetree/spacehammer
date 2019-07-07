(local atom (require :lib.atom))
(local statemachine (require :lib.statemachine))
(local windows (require :lib.windows))
(local {:concat concat
        :find   find
        :filter filter
        :get    get
        :join   join
        :map    map
        :merge  merge
        :tap    tap}
       (require :lib.functional))
(local {:align-columns align-columns}
       (require :lib.text))
(local {:action->fn action->fn
        :bind-keys bind-keys}
       (require :lib.bindings))
(local lifecycle (require :lib.lifecycle))

(var fsm nil)


;; General Utils
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(fn call-when
  [f]
  (when f (f)))


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

(fn enter-app
  [app-name]
  (fsm.dispatch :enter-app app-name))

(fn leave-app
  [app-name]
  (fsm.dispatch :leave-app app-name))


;; Set Key Bindings
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(fn create-action-trigger
  [{:action action :repeatable repeatable}]
  (let [action-fn (action->fn action)]
    (fn []
      (if repeatable
          (start-modal-timeout)
          (deactivate-modal))
      ;; Delay the action-fn ever so slightly
      ;; to speed up the closing of the menu
      ;; This makes the UI feel slightly snappier
      (hs.timer.doAfter 0.01 action-fn))))


(fn create-menu-trigger
  [{:key key}]
  (fn []
    (activate-modal key)))


(fn select-trigger
  [item]
  (if item.action
      (create-action-trigger item)
      item.items
      (create-menu-trigger item)
      (fn []
        (print "No trigger could be found for item: "
               (hs.inspect item)))))


(fn bind-item
  [item]
  {:mods (or item.mods [])
   :key item.key
   :action (select-trigger item)})


(fn bind-menu-keys
  [items]
  (-> items
      (->> (filter (fn [item]
                     (or item.action
                         item.items)))
           (map bind-item))
      (concat [{:key :ESCAPE
                :action deactivate-modal}])
      (bind-keys)))


(fn bind-app-keys
  [items]
  (bind-keys items))


(fn bind-global-keys
  [items]
  (each [_ item (ipairs items)]
    (let [{:key key} item
          mods (or item.mods [])
          action-fn (action->fn item.action)]
      (hs.hotkey.bind mods key action-fn))))


;; Display Modals
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(local mod-chars {:cmd "⌘"
                  :alt "⌥"
                  :shift "⇧"
                  :tab "⇥"})

(fn format-key
  [item]
  (let [mods (-?>> item.mods
                  (map (fn [m] (or (. mod-chars m) m)))
                  (join "+"))]
    (.. (or mods "")
        (if mods "+" "")
        item.key)))


(fn modal-alert
  [menu]
  (let [items (->> menu.items
                   (filter (fn [item] item.title))
                   (map (fn [item]
                          [(format-key item) (. item :title)]))
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
    :prev-menu prev-menu
    :unbind-keys unbind-keys
    :stop-timeout stop-timeout}]
  (call-when unbind-keys)
  (call-when stop-timeout)
  (lifecycle.exit-menu prev-menu)
  (lifecycle.enter-menu menu)
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
     (and (= (. item :key) target)
          (or item.items item.keys)))
   menus))


;; State Transitions
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(fn idle->active
  [state data]
  (let [{:config config
         :app app} state
        app-menu (when app
                   (find-menu app config.apps))
        menu (if (and app-menu (> (# app-menu.items) 0))
                 (find-menu app config.apps)
                 config)]
    (merge {:status :active}
           (show-modal-menu {:menu menu}))))


(fn idle->enter-app
  [state app-name]
  (let [{:config config
         :app app
         :unbind-app-keys unbind-app-keys} state
        prev-app (find-menu app config.apps)
        app-menu (find-menu app-name config.apps)]
    (when app-menu
      (call-when unbind-app-keys)
      (lifecycle.deactivate-app prev-app)
      (lifecycle.activate-app app-menu)
      {:app app-name
       :unbind-app-keys (bind-app-keys app-menu.keys)})))


(fn idle->leave-app
  [state app-name]
  (let [{:config config
         :app current-app
         :unbind-app-keys unbind-app-keys} state
        prev-app (find-menu current-app config.apps)]
    (if (= current-app app-name)
        (do (call-when unbind-app-keys)
            (lifecycle.deactivate-app prev-app)
            {:app :nil
             :unbind-app-keys :nil})
        nil)))


(fn active->idle
  [state data]
  (let [{:menu prev-menu} state]
    (hs.alert.closeAll)
    (call-when state.stop-timeout)
    (lifecycle.exit-menu prev-menu)
    {:status :idle
     :menu :nil
     :stop-timeout :nil
     :unbind-keys (state.unbind-keys)}))


(fn active->active
  [state menu-key]
  (let [{:config config
         :menu prev-menu
         :stop-timeout stop-timeout
         :unbind-keys unbind-keys} state
        menu (if menu-key
                 (find-menu menu-key prev-menu.items)
                 config)]
    (merge {:status :active}
           (show-modal-menu {:stop-timeout stop-timeout
                             :unbind-keys  unbind-keys
                             :prev-menu    prev-menu
                             :menu         menu}))))


(fn active->timeout
  [state]
  (call-when state.stop-timeout)
  {:stop-timeout (timeout deactivate-modal)})


(fn active->enter-app
  [state app-name]
  (let [{:config config
         :app prev-app
         :stop-timeout stop-timeout
         :menu prev-menu
         :unbind-keys unbind-keys
         :unbind-app-keys unbind-app-keys} state
        app-menu (find-menu app-name config.apps)
        prev-app-menu (find-menu prev-app config.apps)]
    (if app-menu
        (do
          (call-when unbind-app-keys)
          (lifecycle.deactivate-app prev-app-menu)
          (lifecycle.activate-app app-menu)
          (merge {:status :active
                  :app    app-name
                  :unbind-app-keys (bind-app-keys app-menu.keys)}
                 (show-modal-menu {:stop-timeout stop-timeout
                                   :unbind-keys  unbind-keys
                                   :prev-menu    prev-menu
                                   :menu         app-menu})))
        nil)))


(fn active->leave-app
  [state app-name]
  (let [{:config       config
         :app          current-app
         :stop-timeout stop-timeout
         :unbind-keys  unbind-keys
         :unbind-app-keys unbind-app-keys} state
        prev-app-menu (find-menu current-app config.apps)]
    (if (= current-app app-name)
        (do
          (call-when unbind-app-keys)
          (lifecycle.deactivate-app prev-app-menu)
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
        (enter-app app-name)
        (= event-type :deactivated)
        (leave-app app-name))))


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
        initial-state {:status :idle
                       :config config
                       :app nil
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
    (enter-app active-app)
    (fn cleanup []
      (: menu-hotkey :delete)
      (: app-watcher :stop))))


{:init init}
