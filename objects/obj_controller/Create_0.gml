//Create event
journey = new Journey();
merchant = new Merchant();
travel = new Travel();
p_mult = travel.pace_multiplier;
diary = new Diary();
scenery = new Scenery();
components = {journey:journey, merchant:merchant, travel:travel, diary:diary, scenery:scenery};
step_signal = create_step_signal();
step_signal = restore_state(components);
alarm[0] = 60 / SECONDS_PER_DAY;
