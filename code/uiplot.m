close all
clear
clc

functions_path = [pwd,'/functions'];
addpath(functions_path);

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
hold off
title({'Adjust the plots using the buttons bellow', 'Press "Continue" when done'})
legend('Accelerometer', 'Force plate');
ax = gca;
ax.FontSize = 15;

adjusted_time = plot_slider(fig10, fig11);

%% Make a new plot with the adjusted time
% Generate the new GRF timestamp
n_sec = size(grf_plot, 1) / 100; % Resampled force plate frequency;
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
% Create a new Accelerometer timestamp
new_acc_tmstp = timestamp(acc_start_idx:acc_end_idx);

figure()
set(gcf, 'Position', get(0, 'Screensize'));
plot(new_acc_tmstp, acc_plot(acc_start_idx:acc_end_idx))
hold on
plot(new_grf_tmstp, grf_plot)
legend('Acceleration', 'Ground reaction force')

% Find peaks on the acceleration signal
min_hei = 4;
min_dist = 3;
samp_freq = 100;
acc_sig = acc_plot(acc_start_idx:acc_end_idx);
[pks_acc, pks_acc_idx] = find_signal_peaks(min_hei, min_dist, samp_freq, acc_sig);
time_pks_acc = new_acc_tmstp(pks_acc_idx);

% Plot the acceleration peaks
plot(time_pks_acc, pks_acc, 'rx', 'MarkerSize', 10, 'DisplayName', 'Acceleration peaks')

% Select region of interest
ax = gca;
ax.FontSize = 15;
y_lim = get(gca, 'YLim');
% Beginning
title('Click on the BEGINNING of the region of interest')
[x_b, y] = ginput(1);
x_b = num2ruler(x_b, ax.XAxis);
line([x_b, x_b], y_lim, 'Color', 'k', 'LineWidth', 2, 'HandleVisibility', 'off')
% End
title('Click on the END of the region of interest')
[x_e, y] = ginput(1);
x_e = num2ruler(x_e, ax.XAxis);
line([x_e, x_e], y_lim, 'Color', 'k', 'LineWidth', 2, 'HandleVisibility', 'off')

% Remove the peaks out of the region of interest
pks_keep = time_pks_acc > x_b & time_pks_acc < x_e;
pks_acc = pks_acc(pks_keep);
time_pks_acc = time_pks_acc(pks_keep);
pks_acc_idx = pks_acc_idx(pks_keep);

figure()
set(gcf, 'Position', get(0, 'Screensize'));
plot(new_acc_tmstp, acc_sig)
hold on
plot(new_grf_tmstp, grf_plot)
plot(time_pks_acc, pks_acc, 'rx', 'MarkerSize', 10)
line([x_b, x_b], y_lim, 'Color', 'k', 'LineWidth', 2)
line([x_e, x_e], y_lim, 'Color', 'k', 'LineWidth', 2)
legend('Acceleration', 'Ground reaction force', 'Acceleration peaks')
ax = gca;
ax.FontSize = 15;

% Find peaks in the force signal
pks_grf = zeros(size(pks_acc));
pks_grf_idx = zeros(size(pks_acc));
for i = 1:length(pks_acc)
	idx_min = time_pks_acc(i) - seconds(min_dist);
    idx_max = time_pks_acc(i) + seconds(min_dist);
    
    idx_min = find(new_grf_tmstp == idx_min);
    idx_max = find(new_grf_tmstp == idx_max);
     
	pks_grf(i) = max(grf_plot(idx_min:idx_max));
	pks_grf_idx(i) = find(grf_plot(idx_min:idx_max) == pks_grf(i), 1, 'first') + idx_min - 1;
end
time_pks_grf = new_grf_tmstp(pks_grf_idx);

plot(time_pks_grf, pks_grf, 'gx', 'MarkerSize', 10, 'DisplayName', 'Ground reaction force peaks')


rmpath(functions_path);
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


