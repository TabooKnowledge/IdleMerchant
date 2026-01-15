//Step event
if (keyboard_check(ord("S"))) {
	step_signal[STEP].dt = (delta_time / MICROSECONDS_PER_SECOND) * 500;
} else {
	step_signal[STEP].dt = delta_time / MICROSECONDS_PER_SECOND;
};


step_signal = journey.tick(step_signal)
step_signal = travel.update(step_signal)
step_signal = ledger.witness(step_signal);

merchant.exist(step_signal);
scenery.update(step_signal);

print(ledger.record);
if (debug_print) {
	
	debug_print = false;
};
if (keyboard_check_pressed(ord("Z"))) {
	if (scenery.current_scene == scenery.scene_layouts.gold) {
		scenery.current_scene = scenery.scene_layouts.birch;
		scenery.set_x();
	} else if (scenery.current_scene == scenery.scene_layouts.birch) {
		scenery.current_scene = scenery.scene_layouts.fantasy;
		scenery.set_x();
	} else if (scenery.current_scene == scenery.scene_layouts.fantasy) {
		scenery.current_scene = scenery.scene_layouts.gold;
		scenery.set_x();
	};
	
};

