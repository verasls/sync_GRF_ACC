close all
clear
clc

load('../data/plot_data.mat')

% Normalize the two different scales
acc_plot = (aR - mean(aR)) / std(aR);
grf_plot = (fR1(:, 1) - mean(fR1(:, 1))) / std(fR1(:, 1));

% Plot GRF and ACC signals
fig10 = figure('NAME', 'Resultant acceleration X Time');
set(gcf, 'Position', get(0, 'Screensize'));
plot(timestamp, acc_plot);
hold on
xticks(timestamp(1):minutes(10):timestamp(end));
fig11 = plot(grf_tmstp(:, 1), grf_plot, '-', 'color', [0.8500 0.3250 0.0980]);
% plot(grf_tmstp, fR1, 'DisplayName', 'Force plates');
legend('Accelerometer', 'Force plate');
lgd = legend;
lgd.FontSize = 18;


adjusted_time = plot_slider(fig10, fig11);

%% Make a new plot with the adjusted time
% Generate the new GRF timestamp
n_sec = size(grf_plot, 1) / 100 % Resampled force plate frequency;
t1 = adjusted_time;
t2 = t1 + seconds(n_sec);
new_grf_tmstp = t1:seconds(1 / 100):t2;
new_grf_tmstp = new_grf_tmstp';
new_grf_tmstp = new_grf_tmstp(1:end - 1);
% Get start and end times for the acceleration signal
start_time = min(new_grf_tmstp) - seconds(30);
end_time = max(new_grf_tmstp) + seconds(30);
% Get start and end indices
acc_start_idx = find(timestamp == start_time);
acc_end_idx = find(timestamp == end_time);

figure()
set(gcf, 'Position', get(0, 'Screensize'));
plot(timestamp(acc_start_idx:acc_end_idx), acc_plot(acc_start_idx:acc_end_idx))
hold on
plot(new_grf_tmstp, grf_plot)
hold off


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

