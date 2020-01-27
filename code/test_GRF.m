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

% Plot platform 1 data
% Plot Vertical GRF (N) x Time (s)
plot_GRF(1, 'vertical', 'N', time, fZ1, time_pks_fZ1, pks_fZ1)
% Plot Vertical GRF (BW) x Time (s)
plot_GRF(1, 'vertical', 'BW', time, fZ1_BW, time_pks_fZ1_BW, pks_fZ1_BW)
% Plot Resultant GRF (N) x Time (s)
plot_GRF(1, 'resultant', 'N', time, fR1, time_pks_fR1, pks_fR1)
% Plot Resultant GRF (BW) x Time (s)
plot_GRF(1, 'resultant', 'BW', time, fR1_BW, time_pks_fR1_BW, pks_fR1_BW)

% Plot platform 2 data
% Plot Vertical GRF (N) x Time (s)
plot_GRF(2, 'vertical', 'N', time, fZ2, time_pks_fZ2, pks_fZ2)
% Plot Vertical GRF (BW) x Time (s)
plot_GRF(2, 'vertical', 'BW', time, fZ2_BW, time_pks_fZ2_BW, pks_fZ2_BW)
% Plot Resultant GRF (N) x Time (s)
plot_GRF(2, 'resultant', 'N', time, fR2, time_pks_fR2, pks_fR2)
% Plot Resultant GRF (BW) x Time (s)
plot_GRF(2, 'resultant', 'BW', time, fR2_BW, time_pks_fR2_BW, pks_fR2_BW)

rmpath(added_path);