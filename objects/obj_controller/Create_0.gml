//Create event
randomize();
journey = new Journey();
merchant = new Merchant();
travel = new Travel();
moment = new Moment();
ledger = new Ledger();
scenery = new Scenery();
scenery.load_scene("birch", "current");
music = new Music();
components = {journey:journey, merchant:merchant, travel:travel, ledger:ledger, scenery:scenery, music:music};
step_signal = create_step_signal();
step_signal = restore_state(components);

if (step_signal.data[SIGNAL].audio_pending) {
	music.load_track("gentle_travel_3");
};