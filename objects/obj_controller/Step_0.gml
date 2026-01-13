//Step event
step_signal[STEP].dt = delta_time / MICROSECONDS_PER_SECOND;
step_signal = journey.tick(step_signal)
step_signal = travel.update(step_signal)
step_signal = diary.update(step_signal);

merchant.exist(step_signal);
scenery.update(step_signal);

print("Fatigue level: " + string(travel.fatigue) + "\n");
print("Rest Timer: " + string(journey.rest_timer) + "\n");
//print(diary.ledger);

