(local atom (require :atom))
(local statemachine (require :statemachine))
(local windows (require :windows))
(local {:concat concat
        :filter filter
        :find find
        :join join
        :map map
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
                         :repeatable true}]}
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
                         :action "zoom/end-meeting"}]}]})

(global fsm nil)

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
        (: task :stop)))))

(fn activate-modal
  [menu-key]
  (fsm.dispatch :activate menu-key))

(fn deactivate-modal
  []
  (fsm.dispatch :deactivate))

(fn start-modal-timeout
  []
  (fsm.dispatch :start-timeout))

(fn create-action-trigger
 [{:action action :repeatable repeatable}]
 (let [[file fn-name] (split "/" action)]
   (fn []
    (if repeatable
      (start-modal-timeout)
			(deactivate-modal))
    (hs.timer.doAfter 0.01
     (fn []
        (let [module (require file)]
          (: module fn-name)))))))

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

(fn show-modal-menu
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


(fn activate-alfred
  []
  (windows.activate-app "Alfred 4"))

(fn find-menu
  [target menus]
  (find
   (fn [item]
     (and (= (. item :key) target)
          (. item :items)))
   menus))

(fn get-menu
  [config paths]
  (reduce
    (fn [{:items items} key]
      (let [menu (find-menu key items)]
        menu))
    config
    paths))

(fn idle->active
  [state data]
  (let [{:config config
         :stop-timeout stop-timeout} state
         menu (get-menu config [])]
    (show-modal-menu menu)
    {:status :active
      :unbind-keys (bind-keys menu.items)}))

(fn idle->enter-app
  [state data]
  {})

(fn idle->leave-app
  [state data]
  {})

(fn active->idle
  [state data]
  (hs.alert.closeAll)
  (when state.stop-timeout
    (state.stop-timeout))
  {:status :idle
   :unbind-keys (state.unbind-keys)})

(fn active->active
  [state menu-key]
  (let [{:config config
          :stop-timeout stop-timeout
          :unbind-keys unbind-keys} state
         menu (get-menu config [menu-key])]
    (unbind-keys)
    (show-modal-menu menu)
    {:status :active
      :unbind-keys (bind-keys menu.items)}))

(fn active->timeout
  [state]
  (when state.stop-timeout
    (state.stop-timeout))
  {:stop-timeout (timeout deactivate-modal)})

(fn active->enter-app
  [state data]
  {})

(fn active->leave-app
  [state data]
  {})


(local states
  {:idle   {:activate   idle->active
             :enter-app idle->enter-app
             :leave-app idle->leave-app}
    :active {:deactivate active->idle
              :activate   active->active
              :enter-app  active->enter-app
              :leave-app  active->leave-app
              :start-timeout active->timeout}})

(fn start-logger
  [fsm]
  (atom.add-watch
    fsm.state :log-state
    (fn log-state
      [state]
      (print "state is now: " state.status))))

(fn init
  [config]

  (let [initial-state {:status :idle
                       :config config
                       :app nil
                       :menu nil
                       :unbind-keys nil}]
    (global fsm (statemachine.new states initial-state :status))
    (hs.hotkey.bind [:cmd] :space activate-modal)
    (start-logger fsm)))


{:init            init
  :activate-alfred activate-alfred
  :config          config}
