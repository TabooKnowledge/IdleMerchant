scroll = distance mod max_span;
red_x = base_red_x - scroll;
blue_x = base_blue_x - scroll;
green_x = base_green_x - scroll;

draw_sprite(spr_red_background, 0, red_x, 0);
draw_sprite(spr_blue_background, 0, blue_x, 0);
draw_sprite(spr_green_background, 0, green_x, 0);


draw_text(25, 25, string_format(distance, 0, 0));
draw_text(25, 50, string_format(offline_distance, 0, 0));
draw_text(25, 75, string(diary));