journey = new Journey();
merchant = new Merchant();
travel = new Travel();
p_mult = travel.pace_multiplier;
diary = new Diary();
scenery = new Scenery();
components = {journey:journey, merchant:merchant, travel:travel, diary:diary, scenery:scenery};
restore_state(components);
step = undefined;
alarm[0] = 60;

