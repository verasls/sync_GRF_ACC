function adjusted_time = plot_slider(fig, plot_grf)
	% Create slider
	fig_pos = get(fig, 'Position');
	fig_l = fig_pos(1);
	fig_b = fig_pos(2);
	fig_w = fig_pos(3);
	fig_h = fig_pos(4);

	sldr_width = 100;
	sldr_height = 20;
	sldr_left = fig_l + fig_w / 2 - sldr_width / 2;
	sldr_bottom = 20;

	value = 0;
	original_time = min(get(plot_grf, 'Xdata'));

	uicontrol(fig, 'Style', 'slider', ...
		  'Position', [sldr_left, sldr_bottom, sldr_width, sldr_height], ...
		  'Min', - 60, 'Max', 60, 'Value', value,...
		  'Callback', {@slider_callback})

	bttn_width = 100;
	bttn_height = 20;
	bttn_left = fig_w - 4 * bttn_width;
	bttn_bottom = 20;

	uicontrol(fig, 'Style', 'pushbutton', ...
		  'String', 'Continue', ...
		  'Position', [bttn_left, bttn_bottom, bttn_width, bttn_height], ...
		  'Callback', 'uiresume(gcbf)')

	uiwait

	adjusted_time = min(get(plot_grf, 'Xdata'));

	function slider_callback(hObj, event)
		value = round(get(hObj, 'Value') - value);
		set(hObj, 'Value', value)

		xdata = get(plot_grf, 'Xdata');
		adjust = seconds(value);
		set(plot_grf, 'Xdata', xdata + adjust)
	end
end


