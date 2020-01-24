% Imput from user ---------------------------------------------------------

% Path to data
path = '../data/119/2017-12-09_Jumps_5cm_1_m1_119.txt';
% Subject's body mass (kg)
body_mass = 71.25;
% Sample frequency (Hz)
samp_freq = 1000;
% Minimum time to consider an interval (s)
threshold = 5 * samp_freq;

% -------------------------------------------------------------------------

data = dlmread(path);

force = data(:, 3); % ground reaction force (GRF; N)
time = 1:length(force);
time = time / samp_freq;  % time in seconds

% Filter GRF data
% Create the lowpass filter
n = 4;  % Filter order
cutoff = 20;  % cut-off frequency (Hz)
fnyq = samp_freq / 2;  % Nyquist frequency (half of the sampling frequency)
Wn = cutoff / fnyq;  % Filter parameter

[b, a] = butter(n, Wn, 'low');

% Process GRF signal
force = filtfilt(b, a, force);

% Get GRF in BW
g = 9.81;  % gravity acceleration (m/s2)
body_weight = body_mass * g;  % body weight (BW; N)
force_BW = force / body_weight;  % ground reaction force (multiples of BW)

% Find peaks
height = 3 * mean(force_BW);
h_dist = 0.4 * samp_freq;  % seconds * sampling frequency

[pks, locs] = findpeaks(force_BW, 'MINPEAKHEIGHT', height, 'MINPEAKDISTANCE', h_dist);

time_of_peaks = locs / samp_freq;

% Plot
set(gcf, 'Position', get(0, 'Screensize'));
figure(1)
plot(time, force_BW);
grid on
hold on
plot(time_of_peaks, pks, 'x', 'MarkerSize', 10);
xlabel('Time (s)', 'FontSize', 20)
ylabel('Vertical ground reaction force (BW)', 'FontSize', 20)
xticks(0:5:max(time));
yticks(0:0.5:6);
ylim([0 5]);
ax = gca;
ax.FontSize = 16;