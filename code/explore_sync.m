close all
clear
clc

functions_path = [pwd,'/functions'];
addpath(functions_path);

samp_freq = 1000;
data_dir = '/Volumes/LVERAS/sync_GRF_ACC/data/119/';
% Read accelerometer data
acc_file = join([data_dir, 'Waist__Impact__119 (2017-12-09)-IMU.csv']);
data = readtable(acc_file, 'HeaderLines', 10);
warning('off', 'MATLAB:table:ModifiedAndSavedVarnames');

% Read all force platform files
grf_files = dir([data_dir, '*.txt']);
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

% Format accelerometer timestamp variable
timestamp = data.Timestamp;
timestamp = datetime(timestamp, 'Timezone', 'UTC', 'Format', 'yyyy-MM-dd''T''HH:mm:ss.S');
timestamp = datetime(timestamp, 'Timezone', 'UTC', 'Format', 'dd-MM-yyyy HH:mm:ss.S');

% Get accelerometer data start and end time indices
acc_start_idx = find(timestamp == start_time);
acc_end_idx = find(timestamp == end_time);

% Crop timestamp between these boundaries
timestamp = timestamp(acc_start_idx:acc_end_idx);
% Exctract accelerometry data per axis
aX = data.AccelerometerX(acc_start_idx:acc_end_idx);
aY = data.AccelerometerY(acc_start_idx:acc_end_idx);
aZ = data.AccelerometerZ(acc_start_idx:acc_end_idx);
aR = sqrt(aX.^2 + aY.^2 + aZ.^2); % Compute resultant vector

% Read GRF files
grf_filename = join([data_dir, char(grf_names(1))]);
grf = dlmread(grf_filename);
% Get data from platform 1
% Ground reaction force (GRF; N)
[fX1, fY1, fZ1] = deal(grf(:, 1), grf(:, 2), grf(:, 3));
fR1 = sqrt(fX1.^2 + fY1.^2 + fZ1.^2); % Compute resultant vector
% Create timestamp
n_sec = size(grf, 1) / samp_freq;
t1 = grf_dtms(1);
t2 = grf_dtms(1) + seconds(n_sec);
grf_tmstp = t1:seconds(1 / samp_freq):t2;
grf_tmstp = grf_tmstp';
grf_tmstp = grf_tmstp(1:end - 1);

% Plot acceleration over time
figure('NAME', 'Resultant acceleration X Time')
set(gcf, 'Position', get(0, 'Screensize'));
yyaxis left
plot(timestamp, aR, 'DisplayName', 'Accelerometer');
grid on
yticks(0:1:ceil(max(aR)));
xticks(timestamp(1):minutes(10):timestamp(end));
yyaxis right
plot(grf_tmstp, fR1, 'DisplayName', 'Force plates');
lgd = legend;
lgd.FontSize = 18;

rmpath(functions_path);
