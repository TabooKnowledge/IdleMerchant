
function Clock() constructor {
	distance = 0;
	last_time = date_current_datetime();
	pace = 20;
	offline_distance = 0;
	
	catch_up = function() {
		var now = date_current_datetime();
		var delta_seconds = (now - self.last_time) * 86400;
		self.offline_distance = delta_seconds * self.pace;
		self.distance += self.offline_distance;
		self.last_time = now;
	};
	
	tick = function() {
		self.distance += self.pace * (delta_time / 1000000);
		self.last_time = date_current_datetime();
	};
};


function Scenery() constructor {
	max_span = 960;
	scroll = 0;
	red_start_x = room_width;
	blue_start_x = room_width*2;
	green_start_x = room_width*3;
	
	update = function(clock) {
		self.scroll = clock.distance mod self.max_span;
	};
	
	draw = function(clock) {
		var red_x = self.red_start_x - self.scroll;
		var blue_x = self.blue_start_x - self.scroll;
		var green_x = self.green_start_x - self.scroll;
		
		draw_sprite(spr_red_background, 0, red_x, 0);
		draw_sprite(spr_blue_background, 0, blue_x, 0);
		draw_sprite(spr_green_background, 0, green_x, 0);


		draw_text(25, 25, string_format(clock.distance, 0, 0));
		draw_text(25, 50, string_format(clock.offline_distance, 0, 0));
	};	
};


function Diary() constructor {
	next_event = 0;
    ledger = [];
	events = [
		[160, "Passed an odd looking lizard"],
		[320, "Met a friendly poet"],
		[480, "Rested under a large tree"],
		[960, "Reached the edge of the province"],
	];
	
	update = function(clock) {
		while (self.next_event < array_length(self.events) && clock.distance >= self.events[self.next_event][EVENTS.DISTANCE]) {
			array_push(self.ledger, self.events[self.next_event][EVENTS.EVENT]);
			self.next_event++;
		};
	};
};


function save(data, file_name) {
	var json_string = json_stringify(data);
	var file = file_text_open_write(file_name);
	file_text_write_string(file, json_string);
	file_text_close(file);
	return true;
};

function load(file_name) {
	if (!file_exists(file_name)) return undefined;
	    var file = file_text_open_read(file_name);
	    var json_string = "";
	    while (!file_text_eof(file)) json_string += file_text_readln(file);
	    file_text_close(file);

	    return json_parse(json_string);
};



function print(_strng="") {
    if (_strng == "") return;
    show_debug_message(string(_strng));
}

enum EVENTS {
	DISTANCE = 0,
	EVENT = 1
}