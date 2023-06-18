
-- half sec loop 75% decay

local sc = {}

function sc.init()
  print("starting halfsecond")

  audio.level_cut(1.0)
  audio.level_adc_cut(1)
  audio.level_eng_cut(1)
  softcut.level(1,1.0)
  softcut.level_slew_time(1,0.25)
  softcut.level_input_cut(1, 1, 1.0)
  softcut.level_input_cut(2, 1, 1.0)
  softcut.pan(1, 0.0)

  softcut.rate_slew_time(1,0.25)

  softcut.play(1, 1) -- voice 1 play on
  softcut.rate(1, 1) -- voice 1 rate 1.0
  softcut.loop_start(1, 1) -- voice 1 loop start @ 1.0s
  softcut.loop_end(1, 1.5) -- voice 1 loop end @ 1.5s
  softcut.loop(1, 1) -- voice 1 enable loop
  softcut.fade_time(1, 0.1) -- voice 1 fade time
  softcut.rec(1, 1) -- voice 1 enable record
  softcut.rec_level(1, 1) -- voice 1 record level
  softcut.pre_level(1, 0.75) -- voice 1 prerec (overdub) level 0.75
  softcut.position(1, 1) -- voice 1 set position 1.0s
  softcut.enable(1, 1) -- enable voice 1

  softcut.filter_dry(1, 0.125); -- voice 1 filter settings...
  softcut.filter_fc(1, 1200);
  softcut.filter_lp(1, 0);
  softcut.filter_bp(1, 1.0);
  softcut.filter_rq(1, 2.0);


  params:add_group("halfsecond",4)
  params:add{id="delay", name="delay", type="control",
    controlspec=controlspec.new(0,1,'lin',0,0.5,""),
    action=function(x) softcut.level(1,x) end}
  params:add{id="delay_rate", name="delay rate", type="control",
    controlspec=controlspec.new(0.5,2.0,'lin',0,1,""),
    action=function(x) softcut.rate(1,x) end}
  params:add{id="delay_feedback", name="delay feedback", type="control",
    controlspec=controlspec.new(0,1.0,'lin',0,0.75,""),
    action=function(x) softcut.pre_level(1,x) end}
  params:add{id="delay_pan", name="delay pan", type="control",
    controlspec=controlspec.new(-1,1.0,'lin',0,0,""),
    action=function(x) softcut.pan(1,x) end}
end

return sc
