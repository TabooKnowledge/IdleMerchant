clock = new Clock();
diary = new Diary();
scenery = new Scenery();

var save_data = load("save.json");
if (save_data != undefined){
	clock.distance = save_data.distance;
	clock.last_time = save_data.last_time;
	diary.next_event = save_data.next_event;
	diary.ledger = save_data.ledger;
};
//if (save_data != undefined){
//	clock.distance = 0;
//	clock.last_time = save_data.last_time;
//	diary.next_event = 0;
//	diary.ledger = [];
//};
clock.catch_up();
diary.update(clock);

alarm[0] = 60;