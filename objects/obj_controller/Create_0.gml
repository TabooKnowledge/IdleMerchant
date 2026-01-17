//Create event
journey = new Journey();
merchant = new Merchant();
travel = new Travel();
ledger = new Ledger();
scenery = new Scenery();
scenery.stage_scene("expir");
music = new Music();
components = {journey:journey, merchant:merchant, travel:travel, ledger:ledger, scenery:scenery, music:music};
step_signal = create_step_signal();
step_signal = restore_state(components);

if (step_signal[SIGNAL].audio_pending) {
	music.load_track("gentle_travel_2");
};
debug_print = true;