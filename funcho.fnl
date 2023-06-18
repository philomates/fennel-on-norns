;; funcho
;; 0.0.0 @philomates
;;
;; modified awake script in fennel
;; lines represent:
;; - Notes
;; - Transposition
;; - Step skip
;; - Step mute
;; - Amplitude
;; - Time division

(_G.include "lib/shim")
(set music-util (require :musicutil))
(global hs (_G.include "lib/halfsecond"))

(set engine.name "PolyPerc")

(set scale [])
(set hi_level 20)
(set lo_level 2)

(global build-scale
  (fn [] (set scale (music-util.generate_scale_of_length 60 5 16))))

(global repeat
  (fn [count element]
    (let [t []]
      (for [n 1 count]
        (tset t n element))
      t)))

(global range
  (fn [start end]
    (let [t []]
      (for [n start end]
        (tset t (+ 1 (length t)) n))
      t)))

(global max (fn [x y] (if (< x y) y x)))
(global min (fn [x y] (if (< x y) x y)))

(set notes {:pos 1})
(tset notes :length 9)
(tset notes :data [3 0 1 5 0 2 9 7 0 0 0 0 0 0 0 0])

(set trans {:pos 1})
(tset trans :length 5)
(tset trans :data [2 -1 1 0 0 0 0 0 0 0 0 0 0 0 0 0])

(set mute {:pos 1})
(tset mute :length 6)
(tset mute :data [1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0])

(set shift {:pos 1})
(tset shift :length 6)
(tset shift :data [1 0 0 2 -2 0 0 0 0 0 0 0 0 0 0 0])

(set vol {:pos 1})
(tset vol :length 5)
(tset vol :data [1 2 0 2 3 8 0 0 0 0 0 0 0 0 0 0])

(set speed {:pos 1})
(tset speed :length 6)
(tset speed :data [4 4 2 4 4 1 1 1 1 1 1 1 1 1 1 1])

(set running true)

(global get-note
  (fn []
    (let [note-index (+ 1 (. trans.data trans.pos) (. notes.data notes.pos))]
        (. scale (max 1 note-index)))))

(global update-pos
  (fn [t shift?]
    (let [shift-val (. shift.data shift.pos)]
      (set t.pos (max 1
                      (+ 1 (% (+ (if (and shift? shift-val) shift-val 0) t.pos)
                              t.length)))))))

(global inner-step
  (fn []
    (let [div (. speed.data speed.pos)]
      (clock.sync (/ 1 (if (< 1 div) 1 div))))
    (when running
      (update-pos notes true)
      (update-pos trans false)
      (update-pos shift false)
      (update-pos vol false)
      (update-pos speed false)
      (update-pos mute false)
      (when (not (= 1 (. mute.data mute.pos)))
        (let [note-num (get-note)
              freq (music-util.note_num_to_freq note_num)]
          (engine.hz freq)))
      (engine.amp (/ (. vol :data vol.pos) 10))
      (redraw))))

(global step
  (fn []
    (while true
      (inner-step))))

(global init
  (fn []
    (build-scale)
    (hs.init)
    (clock.run step)
    (norns.enc.sens 1 8)))

(global draw-table
  (fn [t y]
    (for [i 1 (. t :length)]
      (screen.move (* i 8) (* y 10))
      (when (= t.pos i)
        (screen.level hi_level))
      (screen.text (.. "" (. t :data i)))
      (screen.level lo_level))))

(global redraw (fn []
  (screen.clear)
  (screen.line_width 1)
  (screen.aa 0)
  (screen.move 0 0)
  (draw-table notes 1)
  (draw-table shift 2)
  (draw-table trans 3)
  (draw-table mute 4)
  (draw-table vol 5)
  (draw-table speed 6)
  (screen.update)))
