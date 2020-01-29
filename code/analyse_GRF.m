clear
clc
close all

added_path = [pwd,'/functions'];
addpath(added_path);

% Imput from user ---------------------------------------------------------

% Select data directory
path_to_data = uigetdir('../data');
path_to_data = join([path_to_data, '/']);
% Get file names
files = dir([path_to_data, '*.txt']);
filenames = {files.name};
% Separate files per jump type
drop_jumps_idx = cellfun('isempty', regexp(filenames, '\d_\d*cm'));
drop_jumps_files = filenames(~drop_jumps_idx);
box_jumps_idx = cellfun('isempty', regexp(filenames, '_Box_Jumps_'));
box_jumps_files = filenames(~box_jumps_idx);
continuous_jumps_idx = cellfun('isempty', regexp(filenames, '\d_Jumps'));
continuous_jumps_files = filenames(~continuous_jumps_idx);
% Get Subject's body mass (kg)
file_ex = filenames{1}; % Select a file to obtain the variables below
ID = str2num(file_ex(end - 6:end - 4));
trial = str2num(file_ex(end - 8:end - 8));
body_mass_data = dlmread('../data/body_mass.txt', ',', 1, 0);
ID_row = find(body_mass_data(:, 1) == ID);
body_mass = round(body_mass_data(ID_row, 3), 2);
% Ask user input for body mass
prompt = {'Enter subject body mass (in kg)'};
dlgtitle = 'Body mass';
definput = {num2str(body_mass)};
opts.Interpreter = 'tex';
opts.Resize = 'on';
answer = inputdlg(prompt, dlgtitle, [1 50], definput, opts);
body_mass = str2num(answer{1});
% Sample frequency (Hz)
samp_freq = 1000;
% Minimum time to consider an interval (s)
threshold = 5 * samp_freq;

% -------------------------------------------------------------------------

for i = 1:size(continuous_jumps_files, 2)
	file = join([path_to_data, continuous_jumps_files{i}]);
	data = dlmread(file);
	time = 1:length(data);
	time = time / samp_freq;  % Time in seconds

	% Get data from platform 1
	% Ground reaction force (GRF; N)
	[fX1, fY1, fZ1] = deal(data(:, 1), data(:, 2), data(:, 3));
	fR1 = sqrt(fX1.^2 + fY1.^2 + fZ1.^2); % Compute resultant vector

	% Get data from platform 2
	% Ground reaction force (N)
	[fX2, fY2, fZ2] = deal(data(:, 7), data(:, 8), data(:, 9));
	fR2 = sqrt(fX2.^2 + fY2.^2 + fZ2.^2); % Compute resultant vector

	% Filter GRF data
	[fX1, fY1, fZ1, fR1] = deal(filter_signal(samp_freq, fX1),...
								filter_signal(samp_freq, fY1),...
								filter_signal(samp_freq, fZ1),...
								filter_signal(samp_freq, fR1));

	[fX2, fY2, fZ2, fR2] = deal(filter_signal(samp_freq, fX2),...
								filter_signal(samp_freq, fY2),...
								filter_signal(samp_freq, fZ2),...
								filter_signal(samp_freq, fR2));

	% Get GRF in body weights (BW)
	[fX1_BW, fY1_BW, fZ1_BW, fR1_BW] = deal(get_GRF_BW(body_mass, fX1), ...
											get_GRF_BW(body_mass, fY1), ...
											get_GRF_BW(body_mass, fZ1), ...
											get_GRF_BW(body_mass, fR1));

	[fX2_BW, fY2_BW, fZ2_BW, fR2_BW] = deal(get_GRF_BW(body_mass, fX2), ...
											get_GRF_BW(body_mass, fY2), ...
											get_GRF_BW(body_mass, fZ2), ...
											get_GRF_BW(body_mass, fR2));

	% Find peak GRF (N)
	[pks_fZ1, time_pks_fZ1] = find_signal_peaks(3, 0.2, samp_freq, fZ1);
	[pks_fR1, time_pks_fR1] = find_signal_peaks(3, 0.2, samp_freq, fR1);

	[pks_fZ2, time_pks_fZ2] = find_signal_peaks(1, 0.2, samp_freq, fZ2);
	[pks_fR2, time_pks_fR2] = find_signal_peaks(1, 0.2, samp_freq, fR2);

	% Find peak GRF (BW)
	[pks_fZ1_BW, time_pks_fZ1_BW] = find_signal_peaks(3, 0.2, samp_freq, fZ1_BW);
	[pks_fR1_BW, time_pks_fR1_BW] = find_signal_peaks(3, 0.2, samp_freq, fR1_BW);

	[pks_fZ2_BW, time_pks_fZ2_BW] = find_signal_peaks(1, 0.2, samp_freq, fZ2_BW);
	[pks_fR2_BW, time_pks_fR2_BW] = find_signal_peaks(1, 0.2, samp_freq, fR2_BW);

	% Plot Vertical GRF (N) x Time (s)
	plot_2_platforms(continuous_jumps_files{i}, 'vertical', 'N', time, ...
					 fZ1, fZ2, time_pks_fZ1, time_pks_fZ2, pks_fZ1, pks_fZ2)
	% Plot Vertical GRF (BW) x Time (s)
	plot_2_platforms(continuous_jumps_files{i}, 'vertical', 'BW', time, ...
					 fZ1_BW, fZ2_BW, time_pks_fZ1_BW, time_pks_fZ2_BW, ...
					 pks_fZ1_BW, pks_fZ2_BW)
	% Plot Resultant GRF (N) x Time (s)
	plot_2_platforms(continuous_jumps_files{i}, 'resultant', 'N', time, ...
					 fR1, fR2, time_pks_fR1, time_pks_fR2, pks_fR1, pks_fR2)
	% Plot Resultant GRF (BW) x Time (s)
	plot_2_platforms(continuous_jumps_files{i}, 'resultant', 'BW', time, ...
					 fR1_BW, fR2_BW, time_pks_fR1_BW, time_pks_fR2_BW, ...
					 pks_fR1_BW, pks_fR2_BW)
end
rmpath(added_path);