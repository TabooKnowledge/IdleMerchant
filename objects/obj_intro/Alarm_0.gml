var data = {
    distance: distance,
    last_time: date_current_datetime(),
	red_x: red_x,
	blue_x: blue_x,
	green_x: green_x,
	//distance: 0,
    //last_time: date_current_datetime(),
	//red_x: 320,
	//blue_x: 640,
	//green_x: 960,
};

var _json_string = json_stringify(data);
var _file = file_text_open_write("save.json");
file_text_write_string(_file, _json_string);
file_text_close(_file);

prnt("file saved");
alarm[0] = 60;
