(require :lib.shim)
(set music-util (require :musicutil))
(global hs
  ; (require :lib.halfsecond)
  (dofile "/home/we/dust/code/incomo/lib/halfsecond.lua"))

(set engine.name "PolyPerc")

(set notes [])
(set hi_level 20)
(set lo_level 2)

(global build-scale
  (fn [] (set notes (music-util.generate_scale_of_length 60 5 16))))

(set one {:pos 0
          :length 8
          :data [1 7 3 0 6 0 8 7 0 0 0 0 0 0 0 0]})

(set running true)

(global step
  (fn []
    (while true
      (clock.sync (/ 1 4))
      (when running
        (set one.pos (+ 1 one.pos))
        (when (> one.pos one.length)
          (set one.pos 1))
        (let [note-num (. notes (+ 1 (. one.data one.pos)))
              freq (music-util.note_num_to_freq note_num)]
          (engine.hz freq))
        (redraw)))))

(global init
  (fn []
    (build-scale)
    (hs.init)
    (clock.run step)
    (norns.enc.sens 1 8)))

(global redraw (fn []
  (screen.clear)
  (screen.line_width 1)
  (screen.aa 0)
  (screen.move 0 0)
  (for [i 1 (. one :length)]
    (screen.move (* i 8) 10)
    (when (= one.pos i)
      (screen.level hi_level))
    (screen.text (.. "" (. one :data i)))
    (screen.level lo_level))
  (screen.update)))
