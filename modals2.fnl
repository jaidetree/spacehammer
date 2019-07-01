(local atom (require :atom))
(local windows (require :windows))
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
                         :action "multimedia/play-or-pause"}]}
                {:key :z
                 :title "Zoom"
                 :menu [{:key :m
                         :title "Mute or Unmute Audio"
                         :action "zoom/mute-or-unmute"}]}]}

(global state
        (atom.new {:route []
                   :active false
                   :modals {}
                   :bindings nil}))

(fn seq?
  [tbl]
  (~= (. tbl 1) nil))

(fn seq
  [tbl]
  (if (seq? tbl)
    (ipairs tbl)
    (pairs tbl)))

(fn reduce
  [f acc tbl]
  (var result acc)
  (each [k v (seq tbl)]
    (set result (f result v k)))
  result)

(fn map
  [f tbl]
  (reduce
    (fn [new-tbl v k]
      (table.insert new-tbl (f v k))
      new-tbl)
    []
    tbl))

(fn filter
 [f tbl]
 (reduce
  (fn [xs v k]
   (when (f v k)
    (table.insert xs v))
   xs)
  []
  tbl))

(fn find
 [f tbl]
 (do
   (var done? false)
   (var item nil)
   (var i 1)
   (while (and (not done?) (<= i (# tbl)))
     (let [v (. tbl i)]
       (when (f v)
         (set done? true)
         (set item v)))
     (set i (+ i 1)))
   item))

(fn join
  [sep list]
  (table.concat list sep))

(fn split
 [search str]
 (var pieces [])
 (var input str)
 (let [len (# search)]
   (while input
    (let [i (string.find input search 1 true)]
     (if i
       (let [left (string.sub input 1 (- i 1))
             right (string.sub input (+ i len))]
         (set input right)
         (table.insert pieces left))
       (do
         (table.insert pieces input)
         (set input nil))))))
 pieces)

(fn max-length
  [items]
  (reduce
    (fn [max [key _]]  (math.max max (# key)))
    0
    items))

(fn logf
 [...]
 (let [prefixes [...]]
  (fn [x]
   (print (table.unpack prefixes) (hs.inspect x)))))

(fn tap
 [f x ...]
 (f x (table.unpack [...]))
 x)

(fn concat
 [...]
 (reduce
  (fn [cat tbl]
    (each [_ v (ipairs tbl)]
      (table.insert cat v))
    cat)
  []
  [...]))


(fn pad-str
  [char max str]
  (let [diff (- max (# str))]
    (.. str (string.rep char diff))))

(fn set-modals
  [modals]
  (atom.swap! state (fn [state]
                     (tset state :modals modals)
                     state)))

(fn activate-modal
  [route]
  (atom.swap! state (fn [state]
                      (tset state :active true)
                      (tset state :route (or route []))
                      state)))

(fn deactivate-modal
  []
  (atom.swap! state (fn [state]
                      (tset state :active false)
                      (tset state :route [])
                      state)))

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
 [action]
 (let [[file fn-name] (split "/" action)]
   (fn []
    (deactivate-modal)
    (let [module (require file)]
      (: module fn-name)))))

(fn create-menu-trigger
 [key]
 (fn []
  (let [route (. (atom.deref state) :route)]
    (hs.alert.closeAll 0)
    (activate-modal (concat [] route [key])))))

(fn query-bindings
 [type-key routes]
 (->> routes
      (map (fn [[key route]] [key (. route type-key)]))
      (filter (fn [[key action]] action))))

(fn parse-action-bindings
 [routes]
 (->> (query-bindings :action routes)
      (map (fn [[key action]]
            {:key key
             :fn (create-action-trigger action)}))))

(fn parse-menu-bindings
 [routes]
 (->> (query-bindings :menu routes)
      (map (fn [[key _]]
            {:key key
             :fn (create-menu-trigger key)}))))

(fn parse-bindings
 [routes]
 (let [action-bindings (parse-action-bindings routes)
       menu-bindings (parse-menu-bindings routes)]
  (concat [] action-bindings menu-bindings)))

(fn clear-bindings
 [clear-bindings]
 (when clear-bindings
   (clear-bindings)))

(fn bind-keys
 [routes]
 (let [bindings (->> routes
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
  [routes paths]
  (let [menu (->> routes
                  (map (fn [[key route]]
                        [key (. route :title)]))
                  (align-columns))
        text (join "\n" menu)]
    (hs.alert.closeAll)
    (alert text
           {:textFont "Courier New"
            :radius 0
            :strokeWidth 0}
           99999)))

(fn clear-timeout
 []
 (when timeout
  (: timeout :stop)
  (set timeout nil)))

(fn set-timeout
  []
  (let [timer (hs.timer.doAfter 3 deactivate-modal)]
    (clear-timeout)
    (set timeout timer)))

(fn init
  [modal]
  (set-modals modal)
  (hs.hotkey.bind [:cmd] :space
    activate-modal))

(fn activate-alfred
  []
  (windows.activate-app "Alfred 4"))

(fn find-menu
  [target menus]
  (find
   (fn [[key item]]
     (and (= key target)
          (. item :menu)))
   menus))

(fn get-menu
  [menus paths]
  (reduce
    (fn [current key]
      (let [item (find-menu key current)]
        (. item 2 :menu)))
    menus
    paths))
    
(atom.add-watch
  state :show-modals
  (fn show-modals
    [{:active active-now :route current-route :modals modals :bindings bindings}
     {:active was-active :route prev-route}]
    (when (or (and active-now (~= active-now was-active))
              (and active-now (~= (join "," current-route) (join "," prev-route))))
      (let [menu (get-menu modals current-route)]
        (clear-bindings bindings)
        (set-bindings (bind-keys menu))
        (show-modal-menu menu current-route)
        (set-timeout)))))

(atom.add-watch
  state :hide-modals
  (fn show-modals
    [{:active active-now :bindings bindings} {:active was-active}]
    (when (and (not active-now) (~= active-now was-active))
     (hs.alert.closeAll 0)
     (clear-bindings bindings)
     (clear-timeout))))


(atom.add-watch
  state :log-state
  (fn log-state
   [state]
   (print "state: " (hs.inspect state))))


{:init            init
 :activate-alfred activate-alfred
 :modal-paths     modal-paths}
