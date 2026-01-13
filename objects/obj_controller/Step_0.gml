step = journey.tick(p_mult())
if (travel.update(step)) {
	journey.resting = true;
};
merchant.exist(step);
diary.update(step);
scenery.update(step);
print(travel.fatigue);
print(journey.rest_timer);
print(diary.ledger);

