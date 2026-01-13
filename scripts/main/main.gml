#region Travel
function Travel() constructor {
	fatigue = 0;
	fatigue_rate = 0.0001;
	
	catch_up = function(step) {
		var fatigue_total = self.fatigue + step.offline_distance * self.fatigue_rate;
		var rest_count = floor(fatigue_total);
		self.fatigue = fatigue_total - rest_count;
		return rest_count;
	};
	
	update = function(step) {
		self.fatigue += step.distance_delta * self.fatigue_rate;
		self.fatigue = clamp(self.fatigue, 0, 1);
		
		 if (self.fatigue >= 1) {
			 self.fatigue = 0;
			 return true;
		 };
		 
		 return false;
	};
	
	pace_multiplier = function() {
		return lerp(1, 0.7, self.fatigue);
	};
};
#endregion

#region Journey
function Journey() constructor {
	time = 0;
	day = 0;
	last_time = date_current_datetime();
	offline_time = 0;
	
	distance = 0;
	pace = 1;
	offline_distance = 0;
	
	resting = false;
	rest_timer = 20;
	rest_duration = 20;
	
	// The measurment of a moment
	tick = function(multiplier) {
		var distance_delta = 0;
		self.time += (delta_time / MICROSECONDS_PER_SECOND);
		self.day = floor(self.time / SECONDS_PER_DAY);
		
		if (self.resting && self.rest_timer > 0) {
			self.rest_timer -= (delta_time / MICROSECONDS_PER_SECOND);
		} else {
			self.resting = false;
			self.rest_timer = self.rest_duration;
			distance_delta = self.pace * multiplier * (delta_time / MICROSECONDS_PER_SECOND);
			self.distance += distance_delta;
		};
		
		return {
			offline_distance: self.offline_distance,
			offline_time: self.offline_time,
			distance: self.distance, 
			distance_delta: distance_delta,
			resting: self.resting,
			time: self.time, 
			day: self.day
		};
	};
	
	// Remembering the past
	catch_up = function() {
		var now = date_current_datetime();
		var delta_seconds = (now - self.last_time) * SECONDS_PER_DAY;
		
		self.offline_time = delta_seconds;
		self.time += delta_seconds;
		self.day = floor(self.time / SECONDS_PER_DAY);
		
		self.offline_distance = delta_seconds * self.pace;
		self.distance += self.offline_distance;
		
		self.last_time = now;
		
		return {
			offline_distance: self.offline_distance, 
			offline_time: self.offline_time,
			distance: self.distance,
			time: self.time,
			day: self.day
		};
	};
	
	// Time mattered
	rest_catch_up = function(rest_counter) {
		var time_rested = self.rest_duration * rest_counter;
		
		var distance_lost = time_rested * self.pace;
		distance_lost = min(distance_lost, self.offline_distance);
		
		self.offline_distance -= distance_lost;
		self.distance -= distance_lost;
		
		return {
			offline_distance: self.offline_distance, 
			offline_time: self.offline_time,
			distance: self.distance,
			time: self.time,
			day: self.day
		};
	};
};
#endregion

#region Merchant
function Merchant() constructor {
	age = 0;
	sprite = spr_merchant;
	exist = function(step) {
		self.age = step.time;
	};
	
	persist = function() {
		draw_sprite(spr_merchant, 0, room_width div 2 - sprite_get_width(spr_merchant) div 2, (room_height - room_height div 4) - sprite_get_height(spr_merchant) div 2);
	};
};
#endregion

#region Scenery
function Scenery() constructor {
	max_span = 960;
	scroll = 0;
	red_start_x = room_width;
	blue_start_x = room_width*2;
	green_start_x = room_width*3;
	
	update = function(step) {
		self.scroll = step.distance mod self.max_span;
	};
	
	draw = function(step) {
		var red_x = self.red_start_x - self.scroll;
		var blue_x = self.blue_start_x - self.scroll;
		var green_x = self.green_start_x - self.scroll;
		
		draw_sprite(spr_red_background, 0, red_x, 0);
		draw_sprite(spr_blue_background, 0, blue_x, 0);
		draw_sprite(spr_green_background, 0, green_x, 0);

		draw_text(25, 0, string_format(step.time, 0, 0));
		draw_text(25, 25, string_format(step.distance, 0, 0));
		draw_text(25, 75, string_format(step.offline_time, 0, 0));
		draw_text(25, 100, string_format(step.offline_distance, 0, 0));
	};	
};
#endregion

#region Diary
function Diary() constructor {
	rest_distance = 0;
	next_event = 0;
    ledger = [];
	events = [
		[160,	  "Passed an odd looking lizard"],
		[320,			   "Met a friendly poet"],
		[480,		 "Rested under a large tree"],
		[960, "Reached the edge of the province"],
	];
	
	update = function(step) {
		if (variable_struct_exists(step, "resting") && step.resting) {
			
			if (self.rest_distance != step.distance) {
				array_push(self.ledger, "The merchant stopped under an old oak to rest.");
			};
			self.rest_distance = step.distance;
		};
		while (self.next_event < array_length(self.events) && step.distance >= self.events[self.next_event][EVENTS.DISTANCE]) {
			array_push(self.ledger, self.events[self.next_event][EVENTS.EVENT]);
			self.next_event++;
		};
	};
};
#endregion

#region Save/Load
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

function store_state(controller) {
	var data = {
	    distance: controller.journey.distance,
		time: controller.journey.time,
	    last_time: date_current_datetime(),
		
		next_event: controller.diary.next_event,
		ledger: controller.diary.ledger,
		
		fatigue: controller.travel.fatigue,
	};
	save(data, "save.json");
};

function restore_state(components) {
	var save_data = load("save.json");
	if (save_data != undefined){
		components.journey.distance = save_data.distance;
		components.journey.time = save_data.time;
		components.journey.last_time = save_data.last_time;
		var begin_step = components.journey.catch_up();
		
		components.travel.fatigue = save_data.fatigue;
		var rest_counter = components.travel.catch_up(begin_step);
		
		var end_step = components.journey.rest_catch_up(rest_counter);
		
		components.merchant.exist(end_step);
		
		components.diary.next_event = save_data.next_event;
		components.diary.ledger = save_data.ledger;
		components.diary.update(end_step);
		
		return true;
	};
	return false;
};
#endregion

#region Helpers
function print(_strng="") {
    if (_strng == "") return;
    show_debug_message(_strng);
}

enum EVENTS {
	DISTANCE = 0,
	EVENT = 1
}
#endregion
