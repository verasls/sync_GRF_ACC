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


move_plot(fig10, fig12)
function move_plot(fig, plot_grf)
	% Create slider
	fig_pos = get(fig, 'Position');
	fig_l = fig_pos(1);
	fig_b = fig_pos(2);
	fig_w = fig_pos(3);
	fig_h = fig_pos(4);

	ui_width = 100;
	ui_height = 20;
	ui_left = fig_l + fig_w / 2 - ui_width / 2;
	ui_bottom = 20;

	value = 0;

	uicontrol(fig, 'Style', 'slider', ...
			  'Position', [ui_left, ui_bottom, ui_width, ui_height], ...
			  'Min', - 60, 'Max', 60, 'Value', value,...
			  'Callback', {@slide_plot})

	function slide_plot(hObj, event)
		value = round(get(hObj, 'Value') - value);
		set(hObj, 'Value', value)

		time_adjust = seconds(value);
		disp(time_adjust)
		xdata = get(plot_grf, 'Xdata');
		set(plot_grf, 'Xdata', xdata + time_adjust)
	end
end

