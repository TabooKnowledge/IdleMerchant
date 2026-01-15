//Create event
journey = new Journey();
merchant = new Merchant();
travel = new Travel();
ledger = new Ledger();
scenery = new Scenery();
components = {journey:journey, merchant:merchant, travel:travel, ledger:ledger, scenery:scenery};
step_signal = create_step_signal();
step_signal = restore_state(components);
debug_print = true;