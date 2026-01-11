var data = {
    distance: clock.distance,
    last_time: date_current_datetime(),
	next_event: diary.next_event,
	ledger: diary.ledger
	//distance: 0,
    //last_time: date_current_datetime(),
};

save(data, "save.json");
print("file saved");
alarm[0] = 60;
