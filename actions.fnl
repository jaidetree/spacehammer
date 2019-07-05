(fn reload-config
  []
  (hs.reload))

(fn clear-console
  []
  (hs.console.clearConsole))

(fn say-hi
  []
  (alert "Hello there!"))

{:reload-config reload-config
 :clear-console clear-console
 :say-hi say-hi}
