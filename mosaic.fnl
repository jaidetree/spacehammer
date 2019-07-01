(local hyper (require :hyper))

(fn full-size
  []
  (hs.eventtap.keyStroke [:alt :cmd :ctrl :shift] :1))

(fn left-half
  []
  (hs.eventtap.keyStroke [:alt :cmd :ctrl :shift] :2))

(fn right-half
  []
  (hs.eventtap.keyStroke [:alt :cmd :ctrl :shift] :3))

(fn left-big
  []
  (hs.eventtap.keyStroke [:alt :cmd :ctrl :shift] :4))

(fn right-small
  []
  (hs.eventtap.keyStroke [:alt :cmd :ctrl :shift] :5))

(hyper.bind :1 full-size)
(hyper.bind :2 left-half)
(hyper.bind :3 right-half)
(hyper.bind :4 left-big)
(hyper.bind :5 right-small)

{:full-size   full-size
 :left-half   left-half
 :right-half  right-half
 :left-big    left-big
 :right-small right-small}
