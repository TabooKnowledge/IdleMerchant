//Scripts
#region Journey
function Journey() constructor {
	time = 0;
	day = 0;
	offline_time = 0;
	
	distance = 0;
	distance_delta = 0;
	pace = 1;
	offline_distance = 0;
	
	resting = false;
	rest_timer = 5;
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
		step_signal[STEP].day = self.day;
		return step_signal;
	};
};
#endregion

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

#region Merchant
function Merchant() constructor {
	age = 0;
	sprite = spr_merchant_1;
	exist = function(step_signal) {
		self.age = step_signal[STEP].time;
	};
	
	persist = function(step_signal) {
		var frame = (step_signal[STEP].distance * 6) mod 20;
		draw_sprite_ext(self.sprite, frame, room_width div 6 - sprite_get_width(self.sprite) div 2, (room_height - room_height div 4) - sprite_get_height(self.sprite) div 2, 1, 1, 1, c_white, 1);
	};
};
#endregion

#region Scenery
function Scenery() constructor {//Update save
	scene_layouts = create_scenery();
	current_scene = undefined;
	next_scene = self.scene_layouts.gold;
	transition_length = 2;
	start_distance = 0;
	transitioning = false;
	t_alpha = 0;
	max_span = room_width;
	scroll = 0;
	cur_all_layers = [];
	cur_layers_x = [];
	nxt_all_layers = [];
	nxt_layers_x = [];
	
	update = function(step_signal) {
		self.scroll = step_signal[STEP].distance;
		self.set_x();
		self.transition(step_signal);
	};
	
	transition = function(step_signal) {
		if (self.transitioning) {
			self.t_alpha = (step_signal[STEP].distance - self.start_distance) / self.transition_length;
			self.t_alpha = clamp(self.t_alpha, 0, 1);
			if (self.t_alpha >= 1) {
				self.transitioning = false;
				self.t_alpha = 0;
				self.current_scene = self.next_scene;
				self.cur_all_layers = array_concat(self.current_scene.back_layers, self.current_scene.front_layers);
				self.set_x();
			};
		};
	};
	
	stage_scene = function(name) {
		if (self.current_scene == undefined) {
			self.current_scene = variable_struct_get(self.scene_layouts, name);
			self.cur_all_layers = array_concat(self.current_scene.back_layers, self.current_scene.front_layers);
		} else {
			self.next_scene = variable_struct_get(self.scene_layouts, name);
			self.nxt_all_layers = array_concat(self.next_scene.back_layers, self.next_scene.front_layers);
		};
	};
	
	set_x = function() {
		self.cur_layers_x = self.set_x_for_layers(self.cur_all_layers, self.cur_layers_x);	
		
		if (self.transitioning) {
			self. nxt_layers_x = self.set_x_for_layers(self.nxt_all_layers, self.nxt_layers_x);
		};
	};
	
	set_x_for_layers = function(layers, x_index_array) {
		var total_length = array_length(layers);
		for (var i = 0; i < array_length(layers); i++) {
			var max_span = sprite_get_width(layers[i]);
			var _depth = (i+1) / total_length;
			x_index_array[i] = -(self.scroll * _depth * 25) mod max_span;
		};
		return x_index_array;
	};
	
	draw_back = function(step_signal) {
		var out_alpha = (self.transitioning == false) ? 1 : (1-self.t_alpha);
		var in_alpha = self.t_alpha;
		
		self.draw_layers(self.current_scene.back_layers, self.cur_layers_x, 0, out_alpha);
		
		if (self.transitioning) {
			self.draw_layers(self.next_scene.back_layers, self.nxt_layers_x, 0, in_alpha);
		};
	};	
	
	draw_front = function(step_signal) {	
		var out_alpha = (self.transitioning == false) ? 1 : (1-self.t_alpha);
		var in_alpha = self.t_alpha;
		
		var index = array_length(self.current_scene.back_layers);
		self.draw_layers(self.current_scene.front_layers, self.cur_layers_x, index, out_alpha);
		
		if (self.transitioning) {
			index = array_length(self.next_scene.back_layers);
			self.draw_layers(self.next_scene.front_layers, self.nxt_layers_x, index, in_alpha);
		};
	};
	
	draw_layers = function(layers, layers_index, start_index, alpha) {
		for (var i = 0; i < array_length(layers); i++) {
			var _layer = layers[i];
			var max_span = sprite_get_width(_layer);
			draw_sprite_ext(_layer, 0, layers_index[start_index+i], 0, 1, 1, 0, c_white, alpha);
			draw_sprite_ext(_layer, 0, layers_index[start_index+i] + max_span, 0, 1, 1, 0, c_white, alpha);
		};
	};
	
	draw_debug = function(step_signal) {
		draw_sprite_stretched(spr_black_pixel, 0, 0, room_height, room_width, room_height);
		draw_sprite_ext(spr_paper_1, 0, 0, room_height, 1, 1.25, 0, c_white, .9);
		//draw_text(25, room_height + 100, string_format(step_signal[STEP].time, 0, 0));
		//draw_text(25, room_height + 75, string_format(step_signal[STEP].distance, 0, 0));
		//draw_text(25, room_height + 50, string_format(step_signal[STEP].offline_time, 0, 0));
		//draw_text(25, room_height + 25, string_format(step_signal[STEP].offline_distance, 0, 0));
	};
	
};
#endregion

#region Ledger
function Ledger() constructor {
	rest_distance = 0;
	next_event = 0;
	showing = [];
    record = [];
	time_events = create_time_events();
	time_i = 0;
	distance_events = create_distance_events();
	dist_i = 0;
	
	update = function() {
		
	};

	witness = function(step_signal) {
		if (self.time_i < array_length(self.time_events)) {
			var time = step_signal[STEP].time;
			var array = self.time_events;
			self.time_i = self.update_events(time, array, self.time_i);
		};
		
		if (self.dist_i < array_length(self.distance_events)) {
			var distance = step_signal[STEP].distance;
			var array = self.distance_events;
			self.dist_i = self.update_events(distance, array, self.dist_i);
		};
		
		step_signal[SIGNAL].time_i = self.time_i;
		step_signal[SIGNAL].dist_i = self.dist_i;
		step_signal[SIGNAL].record = self.record;
		return step_signal;
	}
			
	update_events = function(param, array, i) {
		while (i < array_length(array) && array[i][0] <= param) {
			var event = array[i][1];
			array_push(self.record, event);
			self.update_showing();
			i++
		};
		return i;
	};
	
	update_showing = function() {
		var last_event = self.record[array_length(self.record) - 1];
		array_push(self.showing, last_event);
		while (array_length(self.showing) > 3) {
			array_delete(self.showing, 0, 1);
		};		
	};
	
	draw = function() {
		for (var i = 0; i < array_length(self.showing); i++) {
			switch (i) {
				case 0:
				draw_text_ext(20, room_height + 25, self.showing[i], 20, 160);
				break;
				case 1:
				draw_text_ext(20, room_height + 70, self.showing[i], 20, 160);
				break;
				case 2:
				draw_text_ext(20, room_height + 120, self.showing[i], 20, 160);
				break;
			};
		};
	};
};
#endregion

#region Music
function Music() constructor {
	all_music = load_music();
	track_inst = undefined;
	current_track_name = undefined;
	track_length = undefined;
	audio_last_pos = undefined;
	audio_pending = false;
	
	update = function() {
		if (self.track_inst != undefined) {
			self.audio_last_pos = audio_sound_get_track_position(self.track_inst);
		};
		
	};
	
	load_track = function(name) {
		var track_asset = variable_struct_get(self.all_music, name);
		var track_inst = audio_play_sound(track_asset, 1, false);
		audio_sound_gain(track_inst, .2, 0);
		self.track_inst = track_inst;
		self.current_track_name = name;
		self.track_length = audio_sound_length(track_asset);
		
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

function save_components_state(components) {
	return {
		time: components.journey.time,
		last_time: date_current_datetime(),
        distance: components.journey.distance,
		
		fatigue: components.travel.fatigue,
		
		time_i: components.ledger.time_i,
		dist_i: components.ledger.dist_i,
		record: components.ledger.record,
		showing: components.ledger.showing,
		
		current_track_name: components.music.current_track_name,
		track_length: components.music.track_length,
		audio_last_pos: components.music.audio_last_pos,
		audio_pending: components.music.audio_pending,
	};
};

function load_components_state(save_data, components) {
	components.journey.distance = save_data.distance;
	components.journey.time = save_data.time;
	
	components.travel.fatigue = save_data.fatigue;
	
	components.ledger.time_i = save_data.time_i;
	components.ledger.dist_i = save_data.dist_i;
	components.ledger.record = save_data.record;
	components.ledger.showing = save_data.showing;
	
	components.music.current_track_name = save_data.current_track_name;
	components.music.track_length = save_data.track_length;
	components.music.audio_last_pos = save_data.audio_last_pos;
	components.music.audio_pending = save_data.audio_pending;
};

function restore_state(components) {
	var save_data = load("save_data.json");
	if (save_data != undefined) {
		load_components_state(save_data, components);
		
		var step_signal = create_step_signal();
		var now = date_current_datetime();
		var offline_seconds = (now - save_data.last_time) * SECONDS_PER_DAY;
		
		var audio_inst = undefined;
		var audio_asset = variable_struct_get(components.music.all_music, components.music.current_track_name);
		if (audio_asset != undefined) {
			var audio_pos = (components.music.audio_last_pos + offline_seconds) mod components.music.track_length;
			audio_inst = audio_play_sound(audio_asset, 0, false);
			audio_sound_gain(audio_inst, 0, 0);
			audio_sound_set_track_position(audio_inst, audio_pos);
			audio_sound_gain(audio_inst, .2, 9000);
			components.music.track_inst = audio_inst;
		};
		
		if (audio_inst == -1 or audio_inst == undefined) {
			print("Audio Asset: " + string(audio_asset));
			print("Audio Name: " + string(components.music.current_track_name));
			print("Audio Inst ID: " + string(audio_inst));
			step_signal[SIGNAL].audio_pending = true;
		};
		
		var start_distance = save_data.distance;
		var remaining = offline_seconds;
		var chunk = 100;
		
		while (remaining > 0) {
			step_signal[STEP].dt = min(chunk, remaining);
			
			step_signal = components.journey.tick(step_signal);
			step_signal = components.travel.update(step_signal);
			step_signal = components.ledger.witness(step_signal);
			
			remaining -= step_signal[STEP].dt;
		};
		var end_distance = step_signal[STEP].distance;
		
		step_signal[STEP].offline_time = offline_seconds;
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
		offline_time: 0,
        offline_distance: 0,
		dt: 0
	};
	var signal = {
		pace_multiplier: 1,
        rest_request: false,
        fatigue: 0,
		audio_pending: false,
	};
	return [step, signal];
};

function create_scenery() {
	return {
		birch: {
			back_layers: [spr_birch_1, spr_fantasy_4, spr_snow_tree_a, spr_birch_2, spr_birch_3, spr_snow_tree_a_1, spr_birch_4],
			front_layers: [spr_birch_5, spr_birch_4]
		},
		gold: {
			back_layers: [spr_gold_1, spr_gold_2, spr_gold_6, spr_gold_3, spr_gold_4],
			front_layers: [spr_gold_5]
		},
		fantasy: {
			back_layers: [spr_ai_blue_sky, spr_fantasy_2, spr_fantasy_6, spr_fantasy_3, spr_fantasy_7, spr_fantasy_4],
			front_layers: [spr_fantasy_5,]
		},
		mountain_sunset: {
			back_layers: [spr_mountain_sunset_01, spr_mountain_sunset_02, spr_mountain_sunset_03, spr_mountain_sunset_04, 
				spr_mountain_sunset_05, spr_mountain_sunset_06, spr_mountain_sunset_07, spr_mountain_sunset_08, spr_mountain_sunset_09,
				spr_mountain_sunset_10, spr_mountain_sunset_11, spr_mountain_sunset_12, spr_mountain_sunset_13, spr_mountain_sunset_14,
				spr_mountain_sunset_15, spr_mountain_sunset_16],
			front_layers: []
		},
		summer: {
			back_layers: [spr_summer_01, spr_summer_02, spr_summer_03, spr_summer_04],
			front_layers: [spr_summer_05,]
		},
		expir: {
			back_layers: [spr_ai_blue_sky, spr_ai_mountain_a, spr_ai_trees_a, spr_ai_mountain_path],
			front_layers: []
		},
	};
};

function create_time_events() {
	var events = [
		[100, "Passed an odd looking lizard"],
		[250, "Met a friendly poet"],
		[1200, "Rested under a large tree"],
		[1800, "Reached the edge of the province"],
		[3000, "Couldn't sleep last night"],
	];
	array_sort(events, function(a,b) {return a[0] - b[0]})
	return events;
};

function create_distance_events() {
	var events = [
		[100, "Shoes are broken in now"],
		[250, "This is where I last saw..."],
		[1350, "Days like this make me miss my old chair"],
		[5000, "Breathtaking views"],
		[7500, "Halfway to nowhere"],
	];
	array_sort(events, function(a,b) {return a[0] - b[0]})
	return events;
};

function load_music() {
	return {
		gentle_travel: snd_gentle_travel,
		gentle_travel_2: snd_gentle_travel_2,
	};
};
#endregion
