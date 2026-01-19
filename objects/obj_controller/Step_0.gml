//Step event
if (keyboard_check(ord("S"))) {
	//travel.fatigue = 1;
	step_signal.data[STEP].dt = (delta_time / MICROSECONDS_PER_SECOND) * 500;
} else {
	step_signal.data[STEP].dt = delta_time / MICROSECONDS_PER_SECOND;
};

if (keyboard_check_pressed(ord("Z"))) {
	scenery.start_distance = step_signal.data[STEP].distance;
	scenery.transitioning = true;
	if (scenery.current_scene.name == "birch") {
		scenery.load_scene("fantasy", "next");
	} else if (scenery.current_scene.name == "fantasy") {
		scenery.load_scene("gold", "next");
	} else if (scenery.current_scene.name == "gold") {
		scenery.load_scene("summer", "next");
	} else if (scenery.current_scene.name == "summer") {
		scenery.load_scene("birch", "next");
	};
};

step_signal = journey.tick(step_signal);
step_signal = travel.update(step_signal);
step_signal = moment.update(step_signal);
step_signal = ledger.witness(step_signal);
merchant.exist(step_signal);
scenery.update(step_signal);
music.update();
