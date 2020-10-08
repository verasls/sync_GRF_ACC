clear
clc
close all

functions_path = [pwd,'/functions'];
addpath(functions_path);

% Select data file through a GUI
[file, path] = uigetfile('*.csv');

% Get force plates files metadata
grf_files = dir([path, '*.txt']);
% Get file names
grf_names = {grf_files.name};
grf_names = grf_names';
% Remove offset file
offset_idx = cellfun('isempty', regexp(grf_names, '_vazio_'));
grf_names = grf_names(offset_idx);
% Remove walking/running files
run_idx = cellfun('isempty', regexp(grf_names, 'km_'));
grf_names = grf_names(run_idx);
% Get last modification datetimes
grf_dtms = {grf_files.date};
grf_dtms = grf_dtms';
% Remove offset and walking/running files
grf_dtms = grf_dtms(offset_idx);
grf_dtms = grf_dtms(run_idx);
grf_dtms = datetime(grf_dtms, 'Timezone', 'UTC', 'Format', 'dd-MMM-yyyy HH:mm:ss');

% Get start and end times based on the times found in the GRF files
start_time = min(grf_dtms) - minutes(5);
end_time = max(grf_dtms) + minutes(5);

% Obtain ID variables and body mass
file_ex = grf_names{1}; % Select a file to obtain the variables below
ID = str2num(file_ex(end - 6:end - 4));
trial = str2num(file_ex(end - 8:end - 8));
body_mass_data = dlmread('../data/body_mass.txt', ',', 1, 0);
ID_row = find(body_mass_data(:, 1) == ID);
body_mass = round(body_mass_data(ID_row, 3), 2);

% Display subject info
disp(['Selected subject: ID ', num2str(ID)])
disp(['Subject body mass: ', num2str(body_mass), 'kg'])
disp(['Selected acceletometer file: ', file])

% Sample frequency (Hz)
samp_freq_grf = 1000;
samp_freq_acc = 100;
disp(['Accelerometer sampling frequency: ', num2str(samp_freq_acc), 'Hz'])
disp(['Force platform sampling frequency: ', num2str(samp_freq_grf), 'Hz'])

% Read accelerometer data
disp('Reading accelerometer data')
acc_data = readtable([path, file], 'HeaderLines', 10);
warning('off', 'MATLAB:table:ModifiedAndSavedVarnames');

% Format accelerometer timestamp variable
acc_tmstp = acc_data.Timestamp;
acc_tmstp = datetime(acc_tmstp, 'Timezone', 'UTC', 'Format', 'yyyy-MM-dd''T''HH:mm:ss.S');
acc_tmstp = datetime(acc_tmstp, 'Timezone', 'UTC', 'Format', 'dd-MM-yyyy HH:mm:ss.S');

% Get accelerometer data start and end time indices
acc_start_idx = find(acc_tmstp == start_time);
acc_end_idx = find(acc_tmstp == end_time);
% Crop timestamp between these boundaries
acc_tmstp = acc_tmstp(acc_start_idx:acc_end_idx);

% Extract accelerometry data per axis
aX = acc_data.AccelerometerX(acc_start_idx:acc_end_idx);
aY = acc_data.AccelerometerY(acc_start_idx:acc_end_idx);
aZ = acc_data.AccelerometerZ(acc_start_idx:acc_end_idx);

% Read all force platform files
disp('Reading force plates data')
fX = [];
fY = [];
fZ = [];
grf_tmstp = [];
for i = 1:size(grf_names)
	grf_filename = [path, char(grf_names(i))];
	grf_data = dlmread(grf_filename);
	% Get data from plate 1 (GRF in N)
	[X, Y, Z] = deal(grf_data(:, 1), grf_data(:, 2), grf_data(:, 3));

	% Resample force plates data to the accelerometer sampling frequency
	X_resamp = resample(X, samp_freq_acc, samp_freq_grf);
	Y_resamp = resample(Y, samp_freq_acc, samp_freq_grf);
	Z_resamp = resample(Z, samp_freq_acc, samp_freq_grf);

	% Create timestamp
	n_sec = size(grf_data, 1) / samp_freq_grf;
	t1 = grf_dtms(i);
	t2 = t1 + seconds(n_sec);
	tmstp = t1:seconds(1 / samp_freq_acc):t2;
	tmstp = tmstp';
	tmstp = tmstp(1:end - 1);

	% Append values to final arrays
	fX = [fX, X_resamp];
	fY = [fY, Y_resamp];
	fZ = [fZ, Z_resamp];
	grf_tmstp = [grf_tmstp, tmstp];
end
samp_freq_grf = samp_freq_acc;
disp(['Force plate signal was resampled to: ', num2str(samp_freq_grf), 'Hz']);
