//Step event
if (keyboard_check(ord("S"))) {
	//travel.fatigue = 1;
	frame.data.step.dt = (delta_time / MICROSECONDS_PER_SECOND) * 20;
} else {
	frame.data.step.dt = delta_time / MICROSECONDS_PER_SECOND;
};

frame = journey.tick(frame);
frame = travel.update(frame);
frame = moment.update(frame);
ledger.witness(frame);
merchant.exist(frame);
scenery.update(frame);
music.update();
