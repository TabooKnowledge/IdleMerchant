//Create event
randomize();
journey = new Journey();
merchant = new Merchant();
travel = new Travel();
moment = new Moment();
ledger = new Ledger();
scenery = new Scenery();
music = new Music();

components = {journey:journey, merchant:merchant, travel:travel, ledger:ledger, scenery:scenery, music:music};

frame = create_step_signal();
frame = restore_state(components);

if (frame.data.signal.audio_pending) {
	music.load_track("gentle_travel_3");
};

if (scenery.cur_scene == undefined) {
	scenery.load_scene("birch", "current");
};