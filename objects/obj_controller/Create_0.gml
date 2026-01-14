//Create event
journey = new Journey();
merchant = new Merchant();
travel = new Travel();
diary = new Diary();
scenery = new Scenery();
components = {journey:journey, merchant:merchant, travel:travel, diary:diary, scenery:scenery};
step_signal = create_step_signal();
step_signal = restore_state(components);
debug_print = true;