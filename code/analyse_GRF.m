clear
clc
close all

functions_path = [pwd,'/functions'];
addpath(functions_path);

% Imput from user -------------------------------------------------------------

% Select data directory
default_directory = '/Volumes/LVERAS/sync_GRF_ACC/data';
path_to_data = uigetdir(default_directory);
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
offset_idx = cellfun('isempty', regexp(filenames, '_vazio_'));
offset_files = filenames(~offset_idx);
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
% Choose the type of jump to analyse
jump_type = questdlg('What type of jumps do you want to analyse?', ...
	'Jumps menu', ...
	'Drop jumps', 'Box jumps', 'Continuous jumps', ...
	'Continuous jumps');
if strcmp(jump_type, 'Drop jumps')
	jump_files = drop_jumps_files;
elseif strcmp(jump_type, 'Box jumps')
	jump_files = box_jumps_files;
elseif strcmp(jump_type, 'Continuous jumps')
	jump_files = continuous_jumps_files;
end
% Correct files order
last_file_idx = size(jump_files, 2);
last_file = jump_files{last_file_idx};
if contains(last_file, '_5cm_')
	for i = last_file_idx : - 1: 2
		jump_files{i} = jump_files{i - 1};
	end
	jump_files{1} = last_file;
end
% Sample frequency (Hz)
samp_freq = 1000;

% -----------------------------------------------------------------------------

% Set mininum peak height and distance
if strcmp(jump_type, 'Drop jumps')
	min_hei = 3;
	min_dist = 3;
elseif strcmp(jump_type, 'Box jumps')
	min_hei = 3.5;
	min_dist = 3;
elseif strcmp(jump_type, 'Continuous jumps')
	min_hei = 3;
	min_dist = 0.2;
end

% Display messages
disp(['Selected ID: ', num2str(ID)]);
disp(['Body mass: ', num2str(body_mass)]);
disp(['Selected type of jumps: ', jump_type]);
disp(['Offset file: ', offset_files{1}, newline]);

% Run analyis for all selected files
disp('Files analysed:');
for i = 1:size(jump_files, 2)
	file = join([path_to_data, jump_files{i}]);
	offset_file = join([path_to_data, offset_files{1}]);
	disp(jump_files{i});

	data = dlmread(file);
	time = 0:length(data) - 1;
	time = time / samp_freq;  % Time in seconds
	% Get data from platform 1
	% Ground reaction force (GRF; N)
	[fX1, fY1, fZ1] = deal(data(:, 1), data(:, 2), data(:, 3));
	fR1 = sqrt(fX1.^2 + fY1.^2 + fZ1.^2); % Compute resultant vector

	% Read offset data
	offset_data = dlmread(offset_file);

	[offset_X1, offset_Y1, offset_Z1] = deal(offset_data(:, 1), ...
		offset_data(:, 2), ...
		offset_data(:, 3));
	offset_R1 = sqrt(offset_X1.^2 + offset_Y1.^2 + offset_Z1.^2);

	% Remove offset
	disp('For the X axis:')
	fX1 = remove_offset(fX1, offset_X1, samp_freq);
	disp('For the Y axis:')
	fY1 = remove_offset(fY1, offset_Y1, samp_freq);
	disp('For the Z axis:')
	fZ1 = remove_offset(fZ1, offset_Z1, samp_freq);
	disp('For the resultant vector:')
	fR1 = remove_offset(fR1, offset_R1, samp_freq);

	% Filter GRF data
	[fX1, fY1, fZ1, fR1] = deal(filter_signal(samp_freq, fX1),...
		filter_signal(samp_freq, fY1),...
		filter_signal(samp_freq, fZ1),...
		filter_signal(samp_freq, fR1));

	% Get GRF in body weights (BW)
	[fX1_BW, fY1_BW, fZ1_BW, fR1_BW] = deal(get_GRF_BW(body_mass, fX1), ...
		get_GRF_BW(body_mass, fY1), ...
		get_GRF_BW(body_mass, fZ1), ...
		get_GRF_BW(body_mass, fR1));

	% Find peak GRF (N)
	[pks_fZ1, time_pks_fZ1] = find_signal_peaks(min_hei, min_dist, ...
		samp_freq, fZ1);
	[pks_fR1, time_pks_fR1] = find_signal_peaks(min_hei, min_dist, ...
		samp_freq, fR1);

	% Find peak GRF (BW)
	[pks_fZ1_BW, time_pks_fZ1_BW] = find_signal_peaks(min_hei, min_dist, ...
		samp_freq, fZ1_BW);
	[pks_fR1_BW, time_pks_fR1_BW] = find_signal_peaks(min_hei, min_dist, ...
		samp_freq, fR1_BW);

	% Plot Vertical GRF (N) x Time (s)
	plot_GRF(jump_files{i}, 1, 'vertical', 'N', ...
		time, fZ1, time_pks_fZ1, pks_fZ1)
	% Plot Vertical GRF (BW) x Time (s)
	plot_GRF(jump_files{i}, 1, 'vertical', 'BW', ...
		time, fZ1_BW, time_pks_fZ1_BW, pks_fZ1_BW)
	% Plot Resultant GRF (N) x Time (s)
	plot_GRF(jump_files{i}, 1, 'resultant', 'N', ...
		time, fR1, time_pks_fR1, pks_fR1)
	% Plot Resultant GRF (BW) x Time (s)
	plot_GRF(jump_files{i}, 1, 'resultant', 'BW', ...
		time, fR1_BW, time_pks_fR1_BW, pks_fR1_BW)
end

rmpath(functions_path);
