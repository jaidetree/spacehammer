(local utils (require :lib.utils))
(local log (hs.logger.new 'keybindings.fnl', 'debug'))

(local keymaps
       [{:from :h
         :to :left}
        {:from :j
         :to :down}
        {:from :k
         :to :up}
        {:from :l
         :to :right}])


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Simple Vi Mode
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;; Maps hjkl to arrow keys while enabled.
;; Let's refactor this using an fsm

(local arrows {:h :left, :j :down,:k :up,:l :right})

(global simple-vi-mode-keymaps (or simple-vi-mode-keymaps {}))

(fn enable-simple-vi-mode
  []
  (each [k v (pairs arrows)]
    (when (not (. simple-vi-mode-keymaps k))
      (tset simple-vi-mode-keymaps k {})
      (table.insert (. simple-vi-mode-keymaps k)
                    (utils.keymap k :alt v nil))
      (table.insert (. simple-vi-mode-keymaps k)
                    (utils.keymap k "alt+shift" v :alt))
      (table.insert (. simple-vi-mode-keymaps k)
                    (utils.keymap k "alt+shift+ctrl" v :shift))))
  (each [_ ks (pairs simple-vi-mode-keymaps)]
    (each [_ k (pairs ks)]
      (: k :enable))))

(fn disable-simple-vi-mode []
  (each [_ ks (pairs simple-vi-mode-keymaps)]
    (each [_ km (pairs ks)]
      (: km :disable))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Exports
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

{}
