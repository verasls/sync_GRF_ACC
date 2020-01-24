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
[fX, fY, fZ] = deal(data(:, 1), data(:, 2), data(:, 3));
fR = sqrt(fX.^2 + fY.^2 + fZ.^2); % compute resultant vector
time = 1:length(data);
time = time / samp_freq;  % time in seconds
% Get GRF in BW
g = 9.81;  % gravity acceleration (m/s2)
body_weight = body_mass * g;  % body weight (BW; N)
fX_BW = fX / body_weight;
fY_BW = fY / body_weight;
fZ_BW = fZ / body_weight;
fR_BW = fR / body_weight;

% Filter GRF data
% Create the lowpass filter
n = 4;  % Filter order
cutoff = 20;  % cut-off frequency (Hz)
fnyq = samp_freq / 2;  % Nyquist frequency (half of the sampling frequency)
Wn = cutoff / fnyq;  % Filter parameter

[b, a] = butter(n, Wn, 'low');

% Filter GRF (N)
fX = filtfilt(b, a, fX);
fY = filtfilt(b, a, fY);
fZ = filtfilt(b, a, fZ);
fR = filtfilt(b, a, fR);
% Filter GRF (BW)
fX_BW = filtfilt(b, a, fX_BW);
fY_BW = filtfilt(b, a, fY_BW);
fZ_BW = filtfilt(b, a, fZ_BW);
fR_BW = filtfilt(b, a, fR_BW);

% Find peaks
height_fZ = 3 * mean(fZ); % Vertical GRF (N)
height_fR = 3 * mean(fR); % Resultant GRF (N)
height_fZ_BW = 3 * mean(fZ_BW); % Vertical GRF (BW)
height_fR_BW = 3 * mean(fR_BW); % Resultant GRF (BW)
h_dist = 0.2 * samp_freq;  % seconds * sampling frequency

% Peak GRF (N)
[pks_fZ, locs_fZ] = findpeaks(fZ, 'MINPEAKHEIGHT', height_fZ, 'MINPEAKDISTANCE', h_dist);
[pks_fR, locs_fR] = findpeaks(fR, 'MINPEAKHEIGHT', height_fR, 'MINPEAKDISTANCE', h_dist);
time_of_peaks_fZ = locs_fZ / samp_freq;
time_of_peaks_fR = locs_fR / samp_freq;
% Peak GRF (BW)
[pks_fZ_BW, locs_fZ_BW] = findpeaks(fZ_BW, 'MINPEAKHEIGHT', height_fZ_BW, 'MINPEAKDISTANCE', h_dist);
[pks_fR_BW, locs_fR_BW] = findpeaks(fR_BW, 'MINPEAKHEIGHT', height_fR_BW, 'MINPEAKDISTANCE', h_dist);
time_of_peaks_fZ_BW = locs_fZ_BW / samp_freq;
time_of_peaks_fR_BW = locs_fR_BW / samp_freq;


% Plot Vertical GRF (N) x Time (s)
figure('NAME', 'Vertical GRF (N) x Time (s)')
set(gcf, 'Position', get(0, 'Screensize'));
h11 = plot(time, fZ);
grid on
hold on
h12 = plot(time_of_peaks_fZ, pks_fZ, 'x', 'MarkerSize', 10);
xlabel('Time (s)', 'FontSize', 20)
ylabel('Vertical ground reaction force (N)', 'FontSize', 20)
xticks(0:5:max(time));
yticks(0:500:(ceil(max(fZ) / 500) * 500));
xlim([0 max(time)]);
ylim([0 (ceil(max(fZ) / 500) * 500)]);
ax = gca;
ax.FontSize = 16;

% Plot Vertical GRF (BW) x Time (s)
figure('NAME', 'Vertical GRF (BW) x Time (s)')
set(gcf, 'Position', get(0, 'Screensize'));
h21 = plot(time, fZ_BW);
grid on
hold on
h22 = plot(time_of_peaks_fZ_BW, pks_fZ_BW, 'x', 'MarkerSize', 10);
xlabel('Time (s)', 'FontSize', 20)
ylabel('Vertical ground reaction force (BW)', 'FontSize', 20)
xticks(0:5:max(time));
yticks(0:0.5:ceil(max(fZ_BW)));
xlim([0 max(time)]);
ylim([0 ceil(max(fZ_BW))]);
ax = gca;
ax.FontSize = 16;

% Plot Resultant GRF (N) x Time (s)
figure('NAME', 'Resultant GRF (N) x Time (s)')
set(gcf, 'Position', get(0, 'Screensize'));
h11 = plot(time, fR);
grid on
hold on
h12 = plot(time_of_peaks_fR, pks_fR, 'x', 'MarkerSize', 10);
xlabel('Time (s)', 'FontSize', 20)
ylabel('Resultant ground reaction force (N)', 'FontSize', 20)
xticks(0:5:max(time));
yticks(0:500:(ceil(max(fR) / 500) * 500));
xlim([0 max(time)]);
ylim([0 (ceil(max(fR) / 500) * 500)]);
ax = gca;
ax.FontSize = 16;

% Plot Resultant GRF (BW) x Time (s)
figure('NAME', 'Resultant GRF (BW) x Time (s)')
set(gcf, 'Position', get(0, 'Screensize'));
h11 = plot(time, fR_BW);
grid on
hold on
h12 = plot(time_of_peaks_fR_BW, pks_fR_BW, 'x', 'MarkerSize', 10);
xlabel('Time (s)', 'FontSize', 20)
ylabel('Resultant ground reaction force (BW)', 'FontSize', 20)
xticks(0:5:max(time));
yticks(0:0.5:ceil(max(fR_BW)));
xlim([0 max(time)]);
ylim([0 ceil(max(fR_BW))]);
ax = gca;
ax.FontSize = 16;