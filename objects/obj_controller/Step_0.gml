//Step event
if (keyboard_check(ord("S"))) {
	//travel.fatigue = 1;
	step_signal[STEP].dt = (delta_time / MICROSECONDS_PER_SECOND) * 500;
} else {
	step_signal[STEP].dt = delta_time / MICROSECONDS_PER_SECOND;
};


step_signal = journey.tick(step_signal)
step_signal = travel.update(step_signal)
step_signal = ledger.witness(step_signal);

merchant.exist(step_signal);

if (keyboard_check_pressed(ord("Z"))) {
	scenery.start_distance = step_signal[STEP].distance;
	scenery.transitioning = true;	
};

scenery.update(step_signal);

music.update();

print(travel.fatigue);

if (debug_print) {
	
	debug_print = false;
};


