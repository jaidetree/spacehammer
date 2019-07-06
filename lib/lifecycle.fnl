(fn activate-app
  [menu]
  (when (and menu menu.activate)
    (: menu :activate)))

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

{:activate-app   activate-app
 :deactivate-app deactivate-app
 :enter-menu     enter-menu
 :exit-menu      exit-menu}
