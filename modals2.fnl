(local atom (require :atom))
(local windows (require :windows))
(local {:concat concat
        :filter filter
        :find find
        :join join
        :map map
        :reduce reduce
        :split split
        :tap tap} (require :functional))
(local log (hs.logger.new 'modals2.fnl', 'debug'))
(var timeout nil)

(global config
        {:title "Main Menu"
         :menu [{:key :space
                 :title "Alfred"
                 :action "modals2/activate-alfred"}
                {:key :m
                 :title "Multimedia"
                 :menu [{:key :s
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
                 :menu [{:key :1
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
                 :menu [{:key :a
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

(global state
        (atom.new {:paths []
                   :active false
                   :config {}
                   :bindings nil}))


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

(fn set-config
  [config]
  (atom.swap! state (fn [state]
                     (tset state :config config)
                     state)))

(fn activate-modal
  [paths]
  (atom.swap! state (fn [state]
                      (tset state :active true)
                      (tset state :paths (or paths []))
                      state)))

(fn deactivate-modal
  []
  (atom.swap! state (fn [state]
                      (tset state :active false)
                      (tset state :paths [])
                      state)))

(fn clear-timeout
 []
 (when timeout
  (: timeout :stop)
  (set timeout nil)))

(fn set-timeout
  []
  (let [timer (hs.timer.doAfter 5 deactivate-modal)]
    (clear-timeout)
    (set timeout timer)))

(fn set-bindings
  [bindings]
  (atom.swap! state (fn [state]
                      (tset state :bindings bindings)
                      state)))

(fn align-columns
  [items]
  (let [max (max-length items)]
    (map
      (fn [[key action]]
        (.. (pad-str " " max key) " - " action))
      items)))

(fn create-action-trigger
 [{:action action :repeatable repeatable}]
 (let [[file fn-name] (split "/" action)]
   (fn []
    (print "Activated trigger: Deactivating modal")
    (if repeatable
      (set-timeout)
			(deactivate-modal))
    (hs.timer.doAfter 0.01
     (fn []
        (let [module (require file)]
          (: module fn-name)))))))

(fn create-menu-trigger
 [key]
 (fn []
  (let [paths (. (atom.deref state) :paths)]
    (hs.alert.closeAll 0)
    (activate-modal (concat [] paths [key])))))

(fn query-bindings
 [type-key items]
 (->> items
      (filter (fn [item] (. item type-key)))))

(fn parse-action-bindings
 [items]
 (->> (query-bindings :action items)
      (map (fn [item]
            {:key (. item :key)
             :fn (create-action-trigger item)}))))

(fn parse-menu-bindings
 [items]
 (->> (query-bindings :menu items)
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
 (let [bindings (->> items
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
      (: modal :delete)))))

(fn show-modal-menu
  [menu paths]
  (let [items (->> (. menu :menu)
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

(fn init
  [config]
  (set-config config)
  (hs.hotkey.bind [:cmd] :space
    activate-modal))

(fn activate-alfred
  []
  (windows.activate-app "Alfred 4"))

(fn find-menu
  [target menus]
  (find
   (fn [item]
     (and (= (. item :key) target)
          (. item :menu)))
   menus))

(fn get-menu
  [config paths]
  (reduce
    (fn [{:menu menu} key]
      (let [item (find-menu key menu)]
        item))
    config
    paths))

(atom.add-watch
  state :show-modals
  (fn show-modals
    [{:active active-now
      :paths current-paths
      :config config
      :bindings bindings}
     {:active was-active :paths prev-paths}]
    (when (or (and active-now (~= active-now was-active))
              (and active-now (~= (join "," current-paths)
                                  (join "," prev-paths))))
      (print "Activating modal")
      (let [menu (get-menu config current-paths)
            {:menu items} menu]
        (clear-bindings bindings)
        (set-bindings (bind-keys items))
        (show-modal-menu menu current-paths)))))

(atom.add-watch
  state :hide-modals
  (fn show-modals
    [{:active active-now :bindings bindings} {:active was-active}]
    (when (and (not active-now) (~= active-now was-active))
     (print "Deactivating modal")
     (hs.alert.closeAll 0)
     (clear-bindings bindings)
     (clear-timeout))))


(atom.add-watch
  state :log-state
  (fn log-state
   [state]
   state))
   ;(print "state: " (hs.inspect state))))


{:init            init
 :activate-alfred activate-alfred
 :config          config}
