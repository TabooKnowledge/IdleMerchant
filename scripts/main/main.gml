//All Scripts
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
		self.dt = step_signal.data[STEP].dt
		self.pass_time();
		self.rest(step_signal);
		self.move_distance(step_signal);
		return self.update_step_signal(step_signal);
	};
	
	pass_time = function() {
		self.time += self.dt;
		self.day = floor(self.time / SECONDS_PER_DAY);
	};
	
	rest = function(step_signal) {
		self.check_resting(step_signal);
		if (self.resting) {
			self.rest_timer -= self.dt;
			if (self.rest_timer < 0) {
				self.resting = false;
				self.rest_timer = self.rest_duration;
			};
		};
	};
	
	check_resting = function(step_signal) {
		if (step_signal.data[SIGNAL].rest_request) {
			self.resting = true
			step_signal.data[SIGNAL].rest_request = false;
		};
	};
	
	move_distance = function(step_signal) {
		self.distance_delta = 0;
		if (!self.resting) {
			self.distance_delta = self.pace * step_signal.data[SIGNAL].pace_multiplier * self.dt;
			self.distance += self.distance_delta;
		};
	};
	
	update_step_signal = function(step_signal) {
		step_signal.data[STEP].distance = self.distance;
		step_signal.data[STEP].distance_delta = self.distance_delta;
		step_signal.data[STEP].resting = self.resting;
		step_signal.data[STEP].time = self.time;
		step_signal.data[STEP].day = self.day;
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
		self.fatigue += step_signal.data[STEP].distance_delta * self.fatigue_rate;
		self.fatigue = clamp(self.fatigue, 0, 1);
		
		 if (self.fatigue >= 1) {
			 step_signal.data[SIGNAL].rest_request = true;
			 self.fatigue = 0;
		 };
		 
		 self.pace_multiplier = lerp(1, 0.7, self.fatigue);
		 step_signal.data[SIGNAL].pace_multiplier = self.pace_multiplier;
		 
		 step_signal.data[SIGNAL].fatigue = self.fatigue; 
		 
		 return step_signal;
	};
};
#endregion

function Moment() constructor {//Moment Director
	all_actors = create_actors();
	
	update = function(step_signal) {
		self.choose_moment(step_signal);
		return step_signal;
	};
	
	choose_moment = function(step_signal) {
		var chance = random_range(0, 20);
		step_signal.data[SIGNAL].moment = self.create_moment(all_actors.bird)
		if (chance > 10) {
			
		};
	};
	
	create_moment = function(actor) {
		return {
			asset: asset_get_index(actor.asset_name),
			depth: actor.depth,
		};
	};
};

#region Merchant
function Merchant() constructor {
	age = 0;
	sprite = spr_merchant_1;
	exist = function(step_signal) {
		self.age = step_signal.data[STEP].time;
		self.persist(step_signal);
	};
	
	persist = function(step_signal) {
		var frame = (step_signal.data[STEP].distance * 5) mod 20;
		var note = create_draw_note(self.sprite, room_width div 6 - sprite_get_width(self.sprite) div 2, (room_height - room_height div 4) - sprite_get_height(self.sprite) div 2, MID_DEPTH, frame, 1, false); 
		array_push(step_signal.draw_items, note);
	};
};
#endregion

#region Scenery
function Scenery() constructor {
	all_scenes = create_scenery();
	current_scene = undefined;
	next_scene = self.all_scenes.gold;
	
	transition_length = 2;
	start_distance = 0;
	transitioning = false;
	t_alpha = 0;
	
	scroll = 0;
	cur_frnt_layers = [];
	cur_bck_layers = [];
	nxt_frnt_layers = [];
	nxt_bck_layers = [];
	
	update = function(step_signal) {
		self.scroll = step_signal.data[STEP].distance;
		self.transition(step_signal);
		self.emit_draw_notes(step_signal);
		
	};
	
	transition = function(step_signal) {
		if (self.transitioning) {
			self.t_alpha = (step_signal.data[STEP].distance - self.start_distance) / self.transition_length;
			self.t_alpha = clamp(self.t_alpha, 0, 1);
			if (self.t_alpha >= 1) {
				self.complete_transition();
			};
		};
	};
	
	complete_transition = function() {
		self.transitioning = false;
		self.t_alpha = 0;
		self.current_scene = self.next_scene;
		self.cur_frnt_layers = self.nxt_frnt_layers;
		self.cur_bck_layers = self.nxt_bck_layers;
		self.nxt_frnt_layers = [];
		self.nxt_bck_layers = [];
		self.next_scene = {};
		//self.emit_draw_notes(step_signal);
	};
	
	load_scene = function(name, stage) {
		if (stage == "current") {
			self.current_scene = variable_struct_get(self.all_scenes, name);
			self.load_assets(self.current_scene.front_layers, self.cur_frnt_layers);
			self.load_assets(self.current_scene.back_layers, self.cur_bck_layers);
			
		} else {
			self.next_scene = variable_struct_get(self.all_scenes, name);
			self.load_assets(self.next_scene.front_layers, self.nxt_frnt_layers);
			self.load_assets(self.next_scene.back_layers, self.nxt_bck_layers);
		};
	};
	
	load_assets = function(_layers, storage) {
		print(_layers);
		for (var i = 0; i < array_length(_layers); i++) {
			storage[i] = asset_get_index(_layers[i]);
		};
		print(storage);
	};
	
	emit_draw_notes = function(step_signal) {
		var out_alpha = (self.transitioning == false) ? 1 : (1-self.t_alpha);
		var in_alpha = self.t_alpha;
		self.define_draw_notes(self.cur_bck_layers, step_signal, BACK_DEPTH, out_alpha);
		self.define_draw_notes(self.cur_frnt_layers, step_signal, FRONT_DEPTH, out_alpha);	
		
		if (self.transitioning) {
			self.define_draw_notes(self.nxt_bck_layers, step_signal, BACK_DEPTH, in_alpha);
			self.define_draw_notes(self.nxt_frnt_layers, step_signal, FRONT_DEPTH, in_alpha);
		};
	};
	
	define_draw_notes = function(layers, step_signal, _depth, alpha) {
		
		var total_length = array_length(layers);
		for (var i = 0; i < array_length(layers); i++) {
			var _layer = layers[i];
			var max_span = sprite_get_width(_layer);
			var _scroll_mult = (i+1) / total_length * 25;
			var _x = -(self.scroll * _scroll_mult) mod max_span;
			array_push(step_signal.draw_items, create_draw_note(_layer, _x, 0, _depth + (i*100), 0, alpha, true));
		};
		
	};
	
	draw_debug = function(step_signal) {
		draw_sprite_stretched(spr_black_pixel, 0, 0, room_height, room_width, room_height);
		draw_sprite_ext(spr_paper_1, 0, 0, room_height, 1, 1.25, 0, c_white, .9);
		//draw_text(25, room_height + 100, string_format(step_signal[STEP].time, 0, 0));
		//draw_text(25, room_height + 75, string_format(step_signal[STEP].distance, 0, 0));
		//draw_text(25, room_height + 50, string_format(step_signal[SIGNAL].offline_time, 0, 0));
		//draw_text(25, room_height + 25, string_format(step_signal[SIGNAL].offline_distance, 0, 0));
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
			var time = step_signal.data[STEP].time;
			var array = self.time_events;
			self.time_i = self.update_events(time, array, self.time_i);
		};
		
		if (self.dist_i < array_length(self.distance_events)) {
			var distance = step_signal.data[STEP].distance;
			var array = self.distance_events;
			self.dist_i = self.update_events(distance, array, self.dist_i);
		};
		
		step_signal.data[SIGNAL].time_i = self.time_i;
		step_signal.data[SIGNAL].dist_i = self.dist_i;
		step_signal.data[SIGNAL].record = self.record;
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
		
		current_scene: components.scenery.current_scene,
		next_scene: components.scenery.next_scene,
		
		current_track_name: components.music.current_track_name,
		track_length: components.music.track_length,
		audio_last_pos: components.music.audio_last_pos,
		audio_pending: components.music.audio_pending,
	};
};

function restore_state(components) {
	var save_data = load("save_data.json");
	if (save_data != undefined) {
		load_components_state(save_data, components);
		
		var step_signal = create_step_signal();
		var now = date_current_datetime();
		var offline_seconds = (now - save_data.last_time) * SECONDS_PER_DAY;
		
		step_signal = load_audio_state(components, step_signal, offline_seconds);
		
		var start_distance = save_data.distance;
		var remaining = offline_seconds;
		var chunk = LARGE_CHUNK;
		
		while (remaining > 0) {
			step_signal.data[STEP].dt = min(chunk, remaining);
			
			step_signal = components.journey.tick(step_signal);
			step_signal = components.travel.update(step_signal);
			step_signal = components.ledger.witness(step_signal);
			
			remaining -= step_signal.data[STEP].dt;
		};
		var end_distance = step_signal.data[STEP].distance;
		
		step_signal.data[SIGNAL].offline_time = offline_seconds;
		step_signal.data[SIGNAL].offline_distance = end_distance - start_distance;
		
		return step_signal;
	};
	return undefined;
};

function load_components_state(save_data, components) {
	components.journey.distance = save_data.distance;
	components.journey.time = save_data.time;
	
	components.travel.fatigue = save_data.fatigue;
	
	components.ledger.time_i = save_data.time_i;
	components.ledger.dist_i = save_data.dist_i;
	components.ledger.record = save_data.record;
	components.ledger.showing = save_data.showing;
	
	components.scenery.current_scene = save_data.current_scene;
	components.scenery.next_scene = save_data.next_scene;
	components.scenery.load_scene(components.scenery.current_scene.name, "current");
	
	components.music.current_track_name = save_data.current_track_name;
	components.music.track_length = save_data.track_length;
	components.music.audio_last_pos = save_data.audio_last_pos;
	components.music.audio_pending = save_data.audio_pending;
};

function load_audio_state(components, step_signal, offline_seconds) {
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
		step_signal.data[SIGNAL].audio_pending = true;
	};
	return step_signal;
};
#endregion

#region Helpers
function print(_strng) {
    show_debug_message(_strng);
}

function create_step_signal() {
	return {
		data: [
			{
				time: 0,
		        day: 0,
		        distance: 0,
		        distance_delta: 0,
				dt: 0
			},
			{
				offline_time: 0,
		        offline_distance: 0,
				pace_multiplier: 1,
		        rest_request: false,
		        fatigue: 0,
				audio_pending: false,
			},
		],
		draw_items: []
	};
};

function create_scenery() {
	return {
		birch: {
			name: "birch",
			back_layers: ["spr_birch_1", "spr_fantasy_4", "spr_snow_tree_a", "spr_birch_2", "spr_birch_3", "spr_snow_tree_a_1", "spr_birch_4"],
			front_layers: ["spr_birch_5"],
			
		},
		gold: {
			name: "gold",
			back_layers: ["spr_gold_1", "spr_gold_2", "spr_gold_6", "spr_gold_3", "spr_gold_4"],
			front_layers: ["spr_gold_5"],
		},
		fantasy: {
			name: "fantasy",
			back_layers: ["spr_fantasy_1", "spr_fantasy_2", "spr_fantasy_6", "spr_fantasy_3", "spr_fantasy_7", "spr_fantasy_4"],
			front_layers: ["spr_fantasy_5"]
		},
		
		mountain_sunset: {
			name: "mountain_sunset",
			back_layers: ["spr_mountain_sunset_01", "spr_mountain_sunset_02", "spr_mountain_sunset_03", "spr_mountain_sunset_04", 
				"spr_mountain_sunset_05", "spr_mountain_sunset_06", "spr_mountain_sunset_07", "spr_mountain_sunset_08", "spr_mountain_sunset_09",
				"spr_mountain_sunset_10", "spr_mountain_sunset_11", "spr_mountain_sunset_12", "spr_mountain_sunset_13", "spr_mountain_sunset_14",
				"spr_mountain_sunset_15", "spr_mountain_sunset_16"],
			front_layers: []
		},
		
		summer: {
			name: "summer",
			back_layers: ["spr_summer_01", "spr_summer_02", "spr_summer_03", "spr_summer_04"],
			front_layers: ["spr_summer_05"]
		},
		
		expir: {
			name: "expir",
			back_layers: ["spr_ai_blue_sky", "spr_ai_mountain_a", "spr_ai_trees_a", "spr_ai_mountain_path"],
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
		gentle_travel_2: snd_gentle_travel_21,
		gentle_travel_3: snd_gentle_travel_3,
	};
};

function create_actors() {
	return {
		bird: {
			asset_name: "spr_black_bird",
			depth: 3000,
		},
	};
};

function create_draw_note(sprite, x, y, z, frame, alpha, tile_x=false) {
	return {
		sprite: sprite,
		x: x,
		y: y,
		z: z,
		frame: frame,
		alpha: alpha,
		tile_x: tile_x
	};
};

function draw_all(step_signal) {
	array_sort(step_signal.draw_items, function(a,b){return a.z - b.z});
	for (var i = 0; i < array_length(step_signal.draw_items); i++) {
		var item = step_signal.draw_items[i];
		
		if (item.sprite == -1) {
			print("Sprite not found at index " + string(i));
			continue;
		};
			
		draw_sprite_ext(item.sprite, item.frame, item.x, item.y, 1, 1, 0, c_white, item.alpha);
		
		if (item.tile_x) {
			var width = sprite_get_width(item.sprite);
			draw_sprite_ext(item.sprite, item.frame, item.x + width, item.y, 1, 1, 0, c_white, item.alpha);
		};
	};
	step_signal.draw_items = [];
};

#endregion
