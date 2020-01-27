clear
clc
close all

added_path = [pwd,'/functions'];
addpath(added_path);

% Imput from user ---------------------------------------------------------

% Path to data
[file, path] = uigetfile('*.txt');
path_to_file = join([path, file]);
% Get Subject's body mass (kg)
ID = str2num(file(end - 6:end - 4));
trial = str2num(file(end - 8:end - 8));
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

data = dlmread(path_to_file);
time = 1:length(data);
time = time / samp_freq;  % Time in seconds

% Get data from platform 1
% Ground reaction force (GRF; N)
[fX1, fY1, fZ1] = deal(data(:, 1), data(:, 2), data(:, 3));
fR1 = sqrt(fX1.^2 + fY1.^2 + fZ1.^2); % Compute resultant vector

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
[pks_fZ1, time_pks_fZ1] = find_signal_peaks(3, 0.2, samp_freq, fZ1);
[pks_fR1, time_pks_fR1] = find_signal_peaks(3, 0.2, samp_freq, fR1);
% Find peak GRF (BW)
[pks_fZ1_BW, time_pks_fZ1_BW] = find_signal_peaks(3, 0.2, samp_freq, fZ1_BW);
[pks_fR1_BW, time_pks_fR1_BW] = find_signal_peaks(3, 0.2, samp_freq, fR1_BW);


% Plot Vertical GRF (N) x Time (s)
plot_GRF('vertical', 'N', time, fZ1, time_pks_fZ1, pks_fZ1)

% Plot Vertical GRF (BW) x Time (s)
plot_GRF('vertical', 'BW', time, fZ1_BW, time_pks_fZ1_BW, pks_fZ1_BW)

% Plot Resultant GRF (N) x Time (s)
plot_GRF('resultant', 'N', time, fR1, time_pks_fR1, pks_fR1)

% Plot Resultant GRF (BW) x Time (s)
plot_GRF('resultant', 'BW', time, fR1_BW, time_pks_fR1_BW, pks_fR1_BW)

rmpath(added_path);