//Step event
step_signal[STEP].dt = delta_time / MICROSECONDS_PER_SECOND;
step_signal = journey.tick(step_signal)
step_signal = travel.update(step_signal)
step_signal = diary.update(step_signal);

merchant.exist(step_signal);
scenery.update(step_signal);

if (debug_print) {
	print(diary.ledger);
	debug_print = false;
};


