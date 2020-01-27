clear
clc
close all

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

% Retrieve data from platform 1
% Ground reaction force (GRF; N)
[fX1, fY1, fZ1] = deal(data(:, 1), data(:, 2), data(:, 3));
fR1 = sqrt(fX1.^2 + fY1.^2 + fZ1.^2); % Compute resultant vector
time = 1:length(data);
time = time / samp_freq;  % Time in seconds
% Get GRF in BW
g = 9.81;  % Gravity acceleration (m/s2)
body_weight = body_mass * g;  % Body weight (BW; N)
fX1_BW = fX1 / body_weight;
fY1_BW = fY1 / body_weight;
fZ1_BW = fZ1 / body_weight;
fR1_BW = fR1 / body_weight;

% Filter GRF data
% Create the lowpass filter
n = 4;  % Filter order
cutoff = 20;  % Cut-off frequency (Hz)
fnyq = samp_freq / 2;  % Nyquist frequency (half of the sampling frequency)
Wn = cutoff / fnyq;  % Filter parameter

[b, a] = butter(n, Wn, 'low');

% Filter GRF (N)
fX1 = filtfilt(b, a, fX1);
fY1 = filtfilt(b, a, fY1);
fZ1 = filtfilt(b, a, fZ1);
fR1 = filtfilt(b, a, fR1);
% Filter GRF (BW)
fX1_BW = filtfilt(b, a, fX1_BW);
fY1_BW = filtfilt(b, a, fY1_BW);
fZ1_BW = filtfilt(b, a, fZ1_BW);
fR1_BW = filtfilt(b, a, fR1_BW);

% Find peaks
height_fZ1 = 3 * mean(fZ1); % Vertical GRF (N)
height_fR1 = 3 * mean(fR1); % Resultant GRF (N)
height_fZ1_BW = 3 * mean(fZ1_BW); % Vertical GRF (BW)
height_fR1_BW = 3 * mean(fR1_BW); % Resultant GRF (BW)
h_dist = 0.2 * samp_freq;  % Seconds * sampling frequency

% Peak GRF (N)
[pks_fZ1, locs_fZ1] = findpeaks(fZ1, 'MINPEAKHEIGHT', height_fZ1, ...
								'MINPEAKDISTANCE', h_dist);
[pks_fR1, locs_fR1] = findpeaks(fR1, 'MINPEAKHEIGHT', height_fR1, ...
								'MINPEAKDISTANCE', h_dist);
time_of_peaks_fZ1 = locs_fZ1 / samp_freq;
time_of_peaks_fR1 = locs_fR1 / samp_freq;
% Peak GRF (BW)
[pks_fZ1_BW, locs_fZ1_BW] = findpeaks(fZ1_BW, 'MINPEAKHEIGHT', height_fZ1_BW, ...
									  'MINPEAKDISTANCE', h_dist);
[pks_fR1_BW, locs_fR1_BW] = findpeaks(fR1_BW, 'MINPEAKHEIGHT', height_fR1_BW, ...
									  'MINPEAKDISTANCE', h_dist);
time_of_peaks_fZ1_BW = locs_fZ1_BW / samp_freq;
time_of_peaks_fR1_BW = locs_fR1_BW / samp_freq;


% Plot Vertical GRF (N) x Time (s)
figure('NAME', 'Vertical GRF (N) x Time (s)')
set(gcf, 'Position', get(0, 'Screensize'));
h11 = plot(time, fZ1);
grid on
hold on
h12 = plot(time_of_peaks_fZ1, pks_fZ1, 'x', 'MarkerSize', 10);
xlabel('Time (s)', 'FontSize', 20)
ylabel('Vertical ground reaction force (N)', 'FontSize', 20)
xticks(0:5:max(time));
yticks(0:500:(ceil(max(fZ1) / 500) * 500));
xlim([0 max(time)]);
ylim([0 (ceil(max(fZ1) / 500) * 500)]);
ax = gca;
ax.FontSize = 16;

% Plot Vertical GRF (BW) x Time (s)
figure('NAME', 'Vertical GRF (BW) x Time (s)')
set(gcf, 'Position', get(0, 'Screensize'));
h21 = plot(time, fZ1_BW);
grid on
hold on
h22 = plot(time_of_peaks_fZ1_BW, pks_fZ1_BW, 'x', 'MarkerSize', 10);
xlabel('Time (s)', 'FontSize', 20)
ylabel('Vertical ground reaction force (BW)', 'FontSize', 20)
xticks(0:5:max(time));
yticks(0:0.5:ceil(max(fZ1_BW)));
xlim([0 max(time)]);
ylim([0 ceil(max(fZ1_BW))]);
ax = gca;
ax.FontSize = 16;

% Plot Resultant GRF (N) x Time (s)
figure('NAME', 'Resultant GRF (N) x Time (s)')
set(gcf, 'Position', get(0, 'Screensize'));
h11 = plot(time, fR1);
grid on
hold on
h12 = plot(time_of_peaks_fR1, pks_fR1, 'x', 'MarkerSize', 10);
xlabel('Time (s)', 'FontSize', 20)
ylabel('Resultant ground reaction force (N)', 'FontSize', 20)
xticks(0:5:max(time));
yticks(0:500:(ceil(max(fR1) / 500) * 500));
xlim([0 max(time)]);
ylim([0 (ceil(max(fR1) / 500) * 500)]);
ax = gca;
ax.FontSize = 16;

% Plot Resultant GRF (BW) x Time (s)
figure('NAME', 'Resultant GRF (BW) x Time (s)')
set(gcf, 'Position', get(0, 'Screensize'));
h11 = plot(time, fR1_BW);
grid on
hold on
h12 = plot(time_of_peaks_fR1_BW, pks_fR1_BW, 'x', 'MarkerSize', 10);
xlabel('Time (s)', 'FontSize', 20)
ylabel('Resultant ground reaction force (BW)', 'FontSize', 20)
xticks(0:5:max(time));
yticks(0:0.5:ceil(max(fR1_BW)));
xlim([0 max(time)]);
ylim([0 ceil(max(fR1_BW))]);
ax = gca;
ax.FontSize = 16;