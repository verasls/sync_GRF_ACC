close all
clear
clc

load('../data/plot_data.mat')

acc_plot = (aR - mean(aR)) / std(aR);
grf_plot = (fR1(:, 1) - mean(fR1(:, 1))) / std(fR1(:, 1));


fig10 = figure('NAME', 'Resultant acceleration X Time');
set(gcf, 'Position', get(0, 'Screensize'));
plot(timestamp, acc_plot);
hold on
xticks(timestamp(1):minutes(10):timestamp(end));
fig12 = plot(grf_tmstp(:, 1), grf_plot, '-', 'color', [0.8500 0.3250 0.0980]);
% plot(grf_tmstp, fR1, 'DisplayName', 'Force plates');
legend('Accelerometer', 'Force plate');
lgd = legend;
lgd.FontSize = 18;


adjusted_time = plot_slider(fig10, fig12)
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

