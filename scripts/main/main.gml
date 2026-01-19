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
	
	
	tick = function(frame) {
		self.dt = frame.data[STEP].dt
		self.pass_time();
		self.rest(frame);
		self.move_distance(frame);
		return self.update_step_signal(frame);
	};
	
	pass_time = function() {
		self.time += self.dt;
		self.day = floor(self.time / SECONDS_PER_DAY);
	};
	
	rest = function(frame) {
		self.check_resting(frame);
		if (self.resting) {
			self.rest_timer -= self.dt;
			if (self.rest_timer < 0) {
				self.resting = false;
				self.rest_timer = self.rest_duration;
			};
		};
	};
	
	check_resting = function(frame) {
		if (frame.data[SIGNAL].rest_request) {
			self.resting = true
			frame.data[SIGNAL].rest_request = false;
		};
	};
	
	move_distance = function(frame) {
		self.distance_delta = 0;
		if (!self.resting) {
			self.distance_delta = self.pace * frame.data[SIGNAL].pace_multiplier * self.dt;
			self.distance += self.distance_delta;
		};
	};
	
	update_step_signal = function(frame) {
		frame.data[STEP].distance = self.distance;
		frame.data[STEP].distance_delta = self.distance_delta;
		frame.data[STEP].resting = self.resting;
		frame.data[STEP].time = self.time;
		frame.data[STEP].day = self.day;
		return frame;
	};
};
#endregion

#region Travel
function Travel() constructor {
	fatigue = 0;
	fatigue_rate = 0.0001;
	pace_multiplier = 0;
	
	update = function(frame) {
		self.fatigue += frame.data[STEP].distance_delta * self.fatigue_rate;
		self.fatigue = clamp(self.fatigue, 0, 1);
		
		 if (self.fatigue >= 1) {
			 frame.data[SIGNAL].rest_request = true;
			 self.fatigue = 0;
		 };
		 
		 self.pace_multiplier = lerp(1, 0.7, self.fatigue);
		 frame.data[SIGNAL].pace_multiplier = self.pace_multiplier;
		 
		 frame.data[SIGNAL].fatigue = self.fatigue; 
		 
		 return frame;
	};
};
#endregion

function Moment() constructor {
	all_actors = create_actors();
	active = undefined;
	cooldown = 0;
	chance_per_sec = .01;
	
	update = function(frame) {
		var dt = frame.data[STEP].dt;
		frame.data[SIGNAL].moment = undefined;
		
		self.cooldown = (self.cooldown > 0) ? self.cooldown - dt : 0;
		print(self.cooldown);
		
		if (self.active != undefined) {
			self.tick_active(frame, dt);
			return frame;
		};
		 
		if (self.cooldown <= 0) {
			if (random(1) < (self.chance_per_sec * dt)) {
				self.start_moment(frame);
				self.cooldown = random_range(10, 11);
			};
		};
		return frame;
	};
	
	start_moment = function(frame) {
		var actor = self.all_actors.bird;
		var spr = asset_get_index(actor.asset_name);
		
		var _y = random_range(12, room_height * .70);
		var _x = choose(0 - sprite_get_width(spr), room_width);
		var vx = (_x > 0) ? -50 : 50;
		
		var dur = (room_width + sprite_get_width(spr) * 2) / abs(vx);
		
		self.active = {
			type: "bird",
			sprite: spr,
			z: BACK_DEPTH + 100,
			x: _x,
			y: _y,
			vx: vx,
			t: 0,
			dur: dur
		};
		frame.data[SIGNAL].moment = "bird"
		
	};
	
	tick_active = function(frame, dt) {
		var moment = self.active;

		moment.t += dt;
		moment.x += moment.vx * dt;

		var frames = max(1, sprite_get_number(moment.sprite));
		var frame_index = floor(moment.t * 10) mod frames;

		array_push(
			frame.draw_items,
			create_draw_note(moment.sprite, moment.x, moment.y, moment.z, frame_index, 1, false)
		);

		frame.data[SIGNAL].moment = moment.type;

		if (moment.t >= moment.dur) {
			self.active = undefined;
		} else {
			self.active = moment;
		};
	};
};

#region Merchant
function Merchant() constructor {
	age = 0;
	sprite = spr_merchant_1;
	exist = function(frame) {
		self.age = frame.data[STEP].time;
		self.persist(frame);
	};
	
	persist = function(frame) {
		var frame_index = (frame.data[STEP].distance * 5) mod 20;
		var note = create_draw_note(self.sprite, room_width div 6 - sprite_get_width(self.sprite) div 2, (room_height - room_height div 4) - sprite_get_height(self.sprite) div 2, MID_DEPTH, frame_index, 1, false); 
		array_push(frame.draw_items, note);
	};
};
#endregion

#region Scenery
function Scenery() constructor {
	all_scenes = create_scenery();
	current_scene = undefined;
	next_scene = self.all_scenes.gold;
	
	transition_length = 4;
	start_distance = 0;
	transitioning = false;
	t_alpha = 0;
	
	scroll = 0;
	cur_frnt_layers = [];
	cur_bck_layers = [];
	nxt_frnt_layers = [];
	nxt_bck_layers = [];
	
	update = function(frame) {
		self.scroll = frame.data[STEP].distance;
		self.transition(frame);
		self.emit_draw_notes(frame);
		
	};
	
	transition = function(frame) {
		if (self.transitioning) {
			self.t_alpha = (frame.data[STEP].distance - self.start_distance) / self.transition_length;
			print("Alpha: " + string(self.t_alpha));
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
	
	emit_draw_notes = function(frame) {
		var out_alpha = (self.transitioning == false) ? 1 : (1-self.t_alpha);
		var in_alpha = self.t_alpha;
		self.define_draw_notes(self.cur_bck_layers, frame, BACK_DEPTH, out_alpha);
		self.define_draw_notes(self.cur_frnt_layers, frame, FRONT_DEPTH, out_alpha);	
		
		if (self.transitioning) {
			self.define_draw_notes(self.nxt_bck_layers, frame, BACK_DEPTH, in_alpha);
			self.define_draw_notes(self.nxt_frnt_layers, frame, FRONT_DEPTH, in_alpha);
		};
	};
	
	define_draw_notes = function(layers, frame, _depth, alpha) {
		
		var total_length = array_length(layers);
		for (var i = 0; i < array_length(layers); i++) {
			var _layer = layers[i];
			var max_span = sprite_get_width(_layer);
			var _scroll_mult = (i+1) / total_length * 25;
			var _x = -(self.scroll * _scroll_mult) mod max_span;
			array_push(frame.draw_items, create_draw_note(_layer, _x, 0, _depth + (i*100), 0, alpha, true));
		};
		
	};
	
	draw_debug = function(frame) {
		draw_sprite_stretched(spr_black_pixel, 0, 0, room_height, room_width, room_height);
		draw_sprite_ext(spr_paper_1, 0, 0, room_height, 1, 1.25, 0, c_white, .9);
		
		draw_text(25, room_height + 25, "Time: ");
		draw_text(75, room_height + 25, string_format(frame.data[STEP].time, 0, 0));
		draw_text(25, room_height + 50, "Distance: ");
		draw_text(110, room_height + 50, string_format(frame.data[STEP].distance, 0, 0));
		draw_text(25, room_height + 75, "Away Time: ");
		draw_text(120, room_height + 75, string_format(frame.data[SIGNAL].offline_time, 0, 0));		
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

	witness = function(frame) {
		if (self.time_i < array_length(self.time_events)) {
			var time = frame.data[STEP].time;
			var array = self.time_events;
			self.time_i = self.update_events(time, array, self.time_i);
		};
		
		if (self.dist_i < array_length(self.distance_events)) {
			var distance = frame.data[STEP].distance;
			var array = self.distance_events;
			self.dist_i = self.update_events(distance, array, self.dist_i);
		};
		
		frame.data[SIGNAL].time_i = self.time_i;
		frame.data[SIGNAL].dist_i = self.dist_i;
		frame.data[SIGNAL].record = self.record;
		return frame;
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
		
		var frame = create_step_signal();
		var now = date_current_datetime();
		var offline_seconds = (now - save_data.last_time) * SECONDS_PER_DAY;
		
		frame = load_audio_state(components, frame, offline_seconds);
		
		var start_distance = save_data.distance;
		var remaining = offline_seconds;
		var chunk = LARGE_CHUNK;
		
		while (remaining > 0) {
			frame.data[STEP].dt = min(chunk, remaining);
			
			frame = components.journey.tick(frame);
			frame = components.travel.update(frame);
			frame = components.ledger.witness(frame);
			
			remaining -= frame.data[STEP].dt;
		};
		var end_distance = frame.data[STEP].distance;
		
		frame.data[SIGNAL].offline_time = offline_seconds;
		frame.data[SIGNAL].offline_distance = end_distance - start_distance;
		
		return frame;
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

function load_audio_state(components, frame, offline_seconds) {
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
		frame.data[SIGNAL].audio_pending = true;
	};
	return frame;
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

function create_draw_note(sprite, x, y, z, frame_index, alpha, tile_x=false) {
	return {
		sprite: sprite,
		x: x,
		y: y,
		z: z,
		frame_index: frame_index,
		alpha: alpha,
		tile_x: tile_x
	};
};

function draw_all(frame) {
	array_sort(frame.draw_items, function(a,b){return a.z - b.z});
	for (var i = 0; i < array_length(frame.draw_items); i++) {
		var item = frame.draw_items[i];
		
		if (item.sprite == -1) {
			print("Sprite not found at index " + string(i));
			continue;
		};
			
		draw_sprite_ext(item.sprite, item.frame_index, item.x, item.y, 1, 1, 0, c_white, item.alpha);
		
		if (item.tile_x) {
			var width = sprite_get_width(item.sprite);
			draw_sprite_ext(item.sprite, item.frame_index, item.x + width, item.y, 1, 1, 0, c_white, item.alpha);
		};
	};
	frame.draw_items = [];
};

#endregion
