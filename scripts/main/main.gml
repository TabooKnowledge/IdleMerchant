//Scripts
#region Travel
function Travel() constructor {
	fatigue = 0;
	fatigue_rate = 0.0001;
	pace_multiplier = 0;
	
	update = function(step_signal) {
		self.fatigue += step_signal[STEP].distance_delta * self.fatigue_rate;
		self.fatigue = clamp(self.fatigue, 0, 1);
		
		 if (self.fatigue >= 1) {
			 step_signal[SIGNAL].rest_request = true;
			 self.fatigue = 0;
		 };
		 
		 self.pace_multiplier = lerp(1, 0.7, self.fatigue);
		 step_signal[SIGNAL].pace_multiplier = self.pace_multiplier;
		 
		 step_signal[SIGNAL].fatigue = self.fatigue; 
		 
		 return step_signal;
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
	distance_delta = 0;
	pace = 1;
	offline_distance = 0;
	
	resting = false;
	rest_timer = 20;
	rest_duration = 20;
	
	dt = 0;
	
	
	tick = function(step_signal) {
		self.dt = step_signal[STEP].dt
		self.pass_time();
		self.rest(step_signal);
		self.move_distance(step_signal);
		return self.update_step_signal(step_signal);
		
	};
	
	pass_time = function() {
		self.time += self.dt;
		self.day = floor(self.time / SECONDS_PER_DAY);
		self.last_time = date_current_datetime();
	};
	
	rest = function(step_signal) {
		self.check_rest(step_signal);
		if (self.resting) {
			self.rest_timer -= self.dt;
			if (self.rest_timer < 0) {
				self.resting = false;
				self.rest_timer = self.rest_duration;
			};
		};
	};
	
	check_rest = function(step_signal) {
		if (step_signal[SIGNAL].rest_request) {
			self.resting = true;
			step_signal[SIGNAL].rest_request = false;
		};
	};
	
	move_distance = function(step_signal) {
		self.distance_delta = 0;
		if (!self.resting) {
			self.distance_delta = self.pace * step_signal[SIGNAL].pace_multiplier * self.dt;
			self.distance += self.distance_delta;
		};
	};
	
	update_step_signal = function(step_signal) {
		step_signal[STEP].distance = self.distance;
		step_signal[STEP].distance_delta = self.distance_delta;
		step_signal[STEP].resting = self.resting;
		step_signal[STEP].time = self.time;
		step_signal[STEP].last_time = self.last_time;
		step_signal[STEP].day = self.day;
		return step_signal;
	};
};
#endregion

#region Merchant
function Merchant() constructor {
	age = 0;
	sprite = spr_merchant_1;
	exist = function(step_signal) {
		self.age = step_signal[STEP].time;
	};
	
	persist = function(step_signal) {
		var frame = (step_signal[STEP].distance * 5) mod 20;
		draw_sprite(self.sprite, frame, room_width div 6 - sprite_get_width(self.sprite) div 2, (room_height - room_height div 4) - sprite_get_height(self.sprite) div 2);
	};
};
#endregion

#region Scenery
function Scenery() constructor {
	scene_layouts = create_scenery();
	current_scene = self.scene_layouts.birch;
	max_span = room_width;
	scroll = 0;
	layers_x = [];
	
	update = function(step_signal) {
		self.scroll = step_signal[STEP].distance mod self.max_span;
		self.set_x();
	};
	
	set_scene = function(name) {
		self.current_scene = variable_struct_get(self.scene_layouts, name);
	};
	
	set_x = function() {
		var total_length = array_length(self.current_scene.back_layers) + array_length(self.current_scene.front_layers);
		for (var i = 0; i < total_length; i++) {
			self.layers_x[i] = -(self.scroll * ((i+1) * 8)) mod self.max_span;
		};
	};
	
	draw_back = function(step_signal) {
		for (var i = 0; i < array_length(self.current_scene.back_layers); i++) {
			var _layer = self.current_scene.back_layers[i];
			draw_sprite(_layer, 0, self.layers_x[i], 0);
			draw_sprite(_layer, 0, self.layers_x[i] + self.max_span, 0);
		};
	};	
	
	draw_front = function(step_signal) {	
		for (var i = 0; i < array_length(self.current_scene.front_layers); i++) {
			var x_index = i + array_length(self.current_scene.back_layers);
			var _layer = self.current_scene.front_layers[i];
			draw_sprite(_layer, 0, self.layers_x[x_index], 0);
			draw_sprite(_layer, 0, self.layers_x[x_index] + self.max_span, 0);
		};		
	};
	
	draw_debug = function(step_signal) {
		draw_text(25, room_height div 2 - 100, string_format(step_signal[STEP].time, 0, 0));
		draw_text(25, room_height div 2 - 75, string_format(step_signal[STEP].distance, 0, 0));
		draw_text(25, room_height div 2 - 50, string_format(step_signal[STEP].offline_time, 0, 0));
		draw_text(25, room_height div 2 - 25, string_format(step_signal[STEP].offline_distance, 0, 0));
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
	
	update = function(step_signal) {
		if (step_signal[STEP].resting) {
			
			if (self.rest_distance != step_signal[STEP].distance) {
				array_push(self.ledger, "The merchant stopped under an old oak to rest.");
			};
			self.rest_distance = step_signal[STEP].distance;
		};
		while (self.next_event < array_length(self.events) && step_signal[STEP].distance >= self.events[self.next_event][EVENTS.DISTANCE]) {
			array_push(self.ledger, self.events[self.next_event][EVENTS.EVENT]);
			self.next_event++;
		};
		step_signal[SIGNAL].next_event = self.next_event;
		step_signal[SIGNAL].ledger = self.ledger;
		return step_signal;
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

function store_state(step_signal) {
	save(step_signal, "save.json");
};

function load_components_state(step_signal, components) {
	components.journey.distance = step_signal[STEP].distance;
	components.journey.time = step_signal[STEP].time;
	components.journey.last_time = step_signal[STEP].last_time;
	
	components.travel.fatigue = step_signal[SIGNAL].fatigue;
	
	components.diary.next_event = step_signal[SIGNAL].next_event;
	components.diary.ledger = step_signal[SIGNAL].ledger;
};

function restore_state(components) {
	var step_signal = load("save.json");
	if (step_signal != undefined) {
		load_components_state(step_signal, components);
		
		var now = date_current_datetime();
		var offline_seconds = (now - step_signal[STEP].last_time) * SECONDS_PER_DAY;
		step_signal[STEP].offline_time = offline_seconds;
		
		var start_distance = step_signal[STEP].distance;
		
		
		var chunk = 1;
		var remaining = offline_seconds;
		
		while (remaining > 0) {
			step_signal[STEP].dt = min(chunk, remaining);
			
			step_signal = components.journey.tick(step_signal);
			step_signal = components.travel.update(step_signal);
			step_signal = components.diary.update(step_signal);
			
			remaining -= step_signal[STEP].dt;
		};
		var end_distance = step_signal[STEP].distance;
		step_signal[STEP].offline_distance = end_distance - start_distance;
		return step_signal;
	};
	return undefined;
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

function create_step_signal() {
	var step = {
		time: 0,
        day: 0,
        distance: 0,
        distance_delta: 0,
        resting: false,
		offline_time: 0,
        offline_distance: 0,
		dt: 0
	};
	
	var signal = {
		pace_multiplier: 1,
        rest_request: false,
        fatigue: 0,
        rest_count: 0,
		next_event: 0,
		ledger: []
	};
	
	return [step, signal];
};

function create_scenery() {
	return {
		birch: {
			back_layers: [spr_birch_1, spr_fantasy_4, spr_birch_2, spr_birch_3, spr_birch_4],
			front_layers: [spr_birch_5]
		},
		gold: {
			back_layers: [spr_gold_1, spr_gold_2, spr_gold_6, spr_gold_3, spr_gold_4],
			front_layers: [spr_gold_5]
		},
		fantasy: {
			back_layers: [spr_fantasy_1, spr_fantasy_2, spr_fantasy_6, spr_fantasy_3, spr_fantasy_7, spr_fantasy_4],
			front_layers: [spr_fantasy_5,]
		},
	};
};
#endregion
