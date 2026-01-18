//Step event
if (keyboard_check(ord("S"))) {
	//travel.fatigue = 1;
	step_signal.data[STEP].dt = (delta_time / MICROSECONDS_PER_SECOND) * 500;
} else {
	step_signal.data[STEP].dt = delta_time / MICROSECONDS_PER_SECOND;
};


step_signal = journey.tick(step_signal);
step_signal = travel.update(step_signal);
step_signal = moment.update(step_signal);
step_signal = ledger.witness(step_signal);

merchant.exist(step_signal);

if (keyboard_check_pressed(ord("Z"))) {
	scenery.start_distance = step_signal.data[STEP].distance;
	scenery.transitioning = true;
	scenery.load_scene("fantasy", "next");
};

scenery.update(step_signal);

music.update();

print(travel.fatigue);

if (debug_print) {
	
	debug_print = false;
};


