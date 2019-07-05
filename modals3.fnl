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

(global config
        {:title "Main Menu"
         :items [{:key :space
                  :title "Alfred"
                  :action "modals2/activate-alfred"}
                 {:key :m
                  :title "Multimedia"
                  :items [{:key :s
                           :title "Play or Pause"
                           :action "multimedia/play-or-pause"}
                          {:key :h
                           :title "Prev Track"
                           :action "multimedia/prev-track"}
                          {:key :l
                           :title "Next Track"
                           :action "multimedia/next-track"}
                          {:key :j
                           :title "Volume Down"
                           :action "multimedia/volume-down"
                           :repeatable true}
                          {:key :k
                           :title "Volume Up"
                           :action "multimedia/volume-up"
                           :repeatable true}]}
                 {:key :w
                  :title "Window"
                  :items [{:key :l
                           :title "Layouts"
                           :items [{:key :1
                                    :title "Full-screen"
                                    :action "mosaic/full-size"
                                    :repeatable true}
                                   {:key :2
                                    :title "Left Half"
                                    :action "mosaic/left-half"
                                    :repeatable true}
                                   {:key :3
                                    :title "Right Half"
                                    :action "mosaic/right-half"
                                    :repeatable true}
                                   {:key :4
                                    :title "Left Big"
                                    :action "mosaic/left-big"
                                    :repeatable true}
                                   {:key :5
                                    :title "Right Small"
                                    :action "mosaic/right-small"
                                    :repeatable true}]}]}
                 {:key :z
                  :title "Zoom"
                  :items [{:key :a
                           :title "Mute or Unmute Audio"
                           :action "zoom/mute-or-unmute-audio"}
                          {:key :v
                           :title "Start or Stop Video"
                           :action "zoom/start-or-stop-video"}
                          {:key :s
                           :title "Start or Stop Sharing"
                           :action "zoom/start-or-stop-sharing"}
                          {:key :f
                           :title "Pause or Resume Sharing"
                           :action "zoom/pause-or-resume-sharing"}
                          {:key :i
                           :title "Invite..."
                           :action "zoom/invite"}
                          {:key :l
                           :title "End Meeting"
                           :action "zoom/end-meeting"}]}]
         :apps [{:key "Hammerspoon"
                 :items [{:key :r
                          :title "Reload Config"
                          :action "actions/reload-config"}
                         {:key :c
                          :title "Console"
                          :items [{:key :c
                                   :title "Clear"
                                   :action "actions/clear-console"}]}]}
                {:key "Emacs"
                 :items [{:key :h
                          :title "Say hi"
                          :action (fn []
                                    (alert "Hi there!"))}]}]})

(var fsm nil)


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


(fn timeout
  [f]
  (let [task (hs.timer.doAfter 2 f)]
    (fn destroy-task
      []
      (when task
        (: task :stop)
        nil))))


(fn activate-modal
  [menu-key]
  (fsm.dispatch :activate menu-key))


(fn deactivate-modal
  []
  (fsm.dispatch :deactivate))


(fn start-modal-timeout
  []
  (fsm.dispatch :start-timeout))


(fn create-action-fn
  [action]
  (let [[file fn-name] (split "/" action)]
    (fn []
      (let [module (require file)]
        (: module fn-name)))))

(fn parse-action-fn
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
  (let [action-fn (parse-action-fn action)]
    (fn []
      (if repeatable
          (start-modal-timeout)
          (deactivate-modal))
      (hs.timer.doAfter 0.01 action-fn))))


(fn create-menu-trigger
  [key]
  (fn []
    (fsm.dispatch :activate key)))


(fn query-bindings
  [type-key items]
  (->> items
       (filter (fn [item] (. item type-key)))))


(fn parse-action-bindings
  [menu]
  (->> (query-bindings :action menu)
       (map (fn [item]
              {:key (. item :key)
               :fn (create-action-trigger item)}))))


(fn parse-menu-bindings
  [menu]
  (->> (query-bindings :items menu)
       (map (fn [{:key key}]
              {:key key
               :fn (create-menu-trigger key)}))))


(fn parse-bindings
  [items]
  (let [action-bindings (parse-action-bindings items)
        menu-bindings (parse-menu-bindings items)]
    (concat [] action-bindings menu-bindings)))


(fn clear-bindings
  [clear-bindings]
  (when clear-bindings
    (clear-bindings)))


(fn bind-keys
  [items]
  (let [bindings (-> items
                     (parse-bindings))
        modal (hs.hotkey.modal.new [] nil)]
    (each [_ {:key key :fn f} (ipairs bindings)]
      (: modal :bind [] key f))
    (: modal :bind [] :ESCAPE deactivate-modal)
    (: modal :enter)
    (fn destroy-bindings
      []
      (when modal
        (: modal :exit)
        (: modal :delete))
      nil)))


(fn show-modal-alert
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
  (show-modal-alert menu)
  {:menu menu
   :stop-timeout :nil
   :unbind-keys (bind-keys menu.items)})


(fn activate-alfred
  []
  (windows.activate-app "Alfred 4"))


(fn find-app
  [target apps]
  (find
   (fn [item]
     (and (= (. item :name) target)
          (. item :items)))
   apps))


(fn find-menu
  [target menus]
  (find
   (fn [item]
     (and (= (. item :key) target)
          (. item :items)))
   menus))


(fn get-menu
  [parent group target]
  (find-menu target (. parent group)))


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
         :app app} state
        app-menu (find-menu app-name config.apps)]
    (when app-menu
      {:app app-name})))


(fn idle->leave-app
  [state app-name]
  (let [{:app current-app} state]
    (if (= current-app app-name)
        {:app :nil}
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
         :unbind-keys unbind-keys} state
        menu (get-menu config :apps app-name)]
    (if menu
        (do
          (merge {:status :active
                  :app    app-name}
                 (show-modal-menu {:stop-timeout stop-timeout
                                   :unbind-keys  unbind-keys
                                   :menu         menu})))
        nil)))


(fn active->leave-app
  [state app-name]
  (let [{:config       config
         :app          current-app
         :stop-timeout stop-timeout
         :unbind-keys  unbind-keys} state]
    (if (= current-app app-name)
        (merge {:menu :nil
                :app  :nil}
               (show-modal-menu {:stop-timeout stop-timeout
                                 :unbind-keys  unbind-keys
                                 :menu         config}))
        nil)))


(local states
       {:idle   {:activate      idle->active
                 :enter-app     idle->enter-app
                 :leave-app     idle->leave-app}
        :active {:deactivate    active->idle
                 :activate      active->active
                 :enter-app     active->enter-app
                 :leave-app     active->leave-app
                 :start-timeout active->timeout}})


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


(fn init
  [config]
  (let [initial-state {:status :idle
                       :config config
                       :app (active-app-name)
                       :menu nil
                       :unbind-keys nil
                       :stop-timeout nil}
        menu-hotkey (hs.hotkey.bind [:cmd] :space activate-modal)
        app-watcher (hs.application.watcher.new watch-apps)]
    (set fsm (statemachine.new states initial-state :status))
    (start-logger fsm)
    (: app-watcher :start)
    (fn cleanup []
      (: menu-hotkey :delete)
      (: app-watcher :stop))))


{:init            init
 :activate-alfred activate-alfred
 :config          config}
