clear
clc
close all

functions_path = [pwd,'/functions'];
addpath(functions_path);

% Select data directory through a GUI
default_directory = '../data';
path_to_data = uigetdir(default_directory);
path_to_data = join([path_to_data, '/']);

% Sample frequency (Hz)
samp_freq_grf = 1000;
samp_freq_acc = 100;
disp(['Accelerometer sampling frequency: ', num2str(samp_freq_acc), 'Hz'])
disp(['Force platform sampling frequency: ', num2str(samp_freq_grf), 'Hz'])

% Read accelerometer data
disp('Reading accelerometer data')
acc_file = join([path_to_data, 'Waist__Impact__119 (2017-12-09)-IMU.csv']);
acc_data = readtable(acc_file, 'HeaderLines', 10);
warning('off', 'MATLAB:table:ModifiedAndSavedVarnames');

% Read all force platform files
grf_files = dir([path_to_data, '*.txt']);
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
% Ask user input for body mass
prompt = {'Enter subject body mass (in kg)'};
dlgtitle = 'Body mass';
definput = {num2str(body_mass)};
opts.Interpreter = 'tex';
opts.Resize = 'on';
answer = inputdlg(prompt, dlgtitle, [1 50], definput, opts);
body_mass = str2num(answer{1});
