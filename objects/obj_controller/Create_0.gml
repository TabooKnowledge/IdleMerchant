//Create event
journey = new Journey();
merchant = new Merchant();
travel = new Travel();
ledger = new Ledger();
scenery = new Scenery();
music = new Music();
components = {journey:journey, merchant:merchant, travel:travel, ledger:ledger, scenery:scenery, music:music};
step_signal = create_step_signal();
step_signal = restore_state(components);
if (music.current_track_name == undefined) {
	music.load_track("gentle_travel_2");
};
debug_print = true;