(local {:split split}
       (require :lib.functional))

(local log (hs.logger.new "bind.fnl" "debug"))


(fn create-action-fn
  [action]
  (let [[file fn-name] (split ":" action)]
    (fn []
      (let [module (require file)]
        (if (. module fn-name)
            (: module fn-name)
            (do
              (log.wf "Could not invoke action %s"
                     action)))))))


(fn action->fn
  [action]
  (match (type action)
    :function action
    :string (create-action-fn action)
    _         (do
                (log.wf "Could not create action handler for %s"
                        (hs.inspect action))
                (fn [] true))))


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


{:action->fn    action->fn
 :bind-keys     bind-keys}
