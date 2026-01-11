enum EVENTS {
	DISTANCE = 0,
	EVENT = 1
}
function prnt(_strng="") {
    if (_strng == "") return;
    show_debug_message(string(_strng));
}
function check_events() {
	while (next_event < array_length(events) && distance >= events[next_event][EVENTS.DISTANCE]) {
		array_push(diary, events[next_event][EVENTS.EVENT]);
		next_event++;
	};
};
max_span = 960;
scroll = 0;
base_red_x = room_width;
base_blue_x = room_width*2;
base_green_x = room_width*3;
pace = 20;
events = [
	[960, "Passed an odd looking lizard"],
	[1920, "Met a friendly poet"],
	[3840, "Rested under a large tree"],
	[5000, "Reached the edge of the province"],
];

diary = [];


if (file_exists("save.json")) {
    var _file = file_text_open_read("save.json");
    var _json_string = "";
    while (!file_text_eof(_file)) _json_string += file_text_readln(_file);
    file_text_close(_file);

    var _save_data = json_parse(_json_string);
    distance  = _save_data.distance;
    last_time = _save_data.last_time;
	red_x = _save_data.red_x;
	blue_x = _save_data.blue_x;
	green_x = _save_data.green_x;
} else {
    distance  = 0;
    last_time = date_current_datetime();
	red_x = base_red_x;
	blue_x = base_blue_x;
	green_x = base_green_x;
}


var now = date_current_datetime();
var delta_seconds = (now - last_time) * 86400;
offline_distance = delta_seconds * pace;
distance += offline_distance;
red_x -= offline_distance;
blue_x -= offline_distance;
green_x -= offline_distance;
scroll -= offline_distance;

last_time = now;

next_event = 0;
check_events();
alarm[0] = 60;
