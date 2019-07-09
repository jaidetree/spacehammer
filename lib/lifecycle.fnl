(fn activate-app
  [menu]
  (when (and menu menu.activate)
    (: menu :activate)))

(fn close-app
  [menu]
  (when (and menu menu.close)
    (: menu :close)))

(fn deactivate-app
  [menu]
  (when (and menu menu.deactivate)
    (: menu :deactivate)))

(fn enter-menu
  [menu]
  (when (and menu menu.enter)
    (: menu :enter)))

(fn exit-menu
  [menu]
  (when (and menu menu.exit)
    (: menu :exit)))

(fn launch-app
  [menu]
  (when (and menu menu.launch)
    (: menu :launch)))

{:activate-app   activate-app
 :close-app      close-app
 :deactivate-app deactivate-app
 :enter-menu     enter-menu
 :exit-menu      exit-menu
 :launch-app     launch-app}
