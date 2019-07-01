(local log (hs.logger.new 'zoom.fnl' 'debug'))

(fn mute-or-unmute-audio
  []
  (let [zoom (hs.appfinder.appFromName "zoom.us")]
    (: log :i "Mute or Unmute Zoom")
    (if (: zoom :findMenuItem ["Meeting" "Mute Audio"])
      (do (: zoom :selectMenuItem ["Meeting" "Mute Audio"])
          (: log :i "Mute Audio"))
      (do (: zoom :selectMenuItem ["Meeting" "Unmute Audio"])
          (: log :i "Unmute Audio")))))
 
{:mute-or-unmute-audio mute-or-unmute-audio}
