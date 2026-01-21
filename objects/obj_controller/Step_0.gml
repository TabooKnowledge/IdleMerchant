//Step event
if (keyboard_check(ord("S"))) {
	//travel.fatigue = 1;
	frame.data.step.dt = (delta_time / MICROSECONDS_PER_SECOND) * 20;
} else {
	frame.data.step.dt = delta_time / MICROSECONDS_PER_SECOND;
};

if (keyboard_check_pressed(ord("Z"))) {
	scenery.start_distance = frame.data.step.distance;
	scenery.transitioning = true;
	if (scenery.cur_scene.name == "birch") {
		scenery.load_scene("fantasy", "next");
	} else if (scenery.cur_scene.name == "fantasy") {
		scenery.load_scene("gold", "next");
	} else if (scenery.cur_scene.name == "gold") {
		scenery.load_scene("summer", "next");
	} else if (scenery.cur_scene.name == "summer") {
		scenery.load_scene("birch", "next");
	};
};

frame = journey.tick(frame);
frame = travel.update(frame);
frame = moment.update(frame);
ledger.witness(frame);
merchant.exist(frame);
scenery.update(frame);
music.update();
