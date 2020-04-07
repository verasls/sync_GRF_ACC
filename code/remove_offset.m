clear
clc
close all

body_mass = 72.7

% Read offset data
off_filename = '../data/119/2017-12-09_vazio_1m_119.txt';

off_data = dlmread(off_filename);
time = 1:length(off_data);
time = time / 1000;

[offset_X1, offset_Y1, offset_Z1] = deal(off_data(:, 1), ...
	off_data(:, 2), ...
	off_data(:, 3));
offset_R1 = sqrt(offset_X1.^2 + offset_Y1.^2 + offset_Z1.^2);

offset = mean(offset_Z1(1:10000)) % seconds 1:10

% Read data
filename = '../data/119/2017-12-09_Jumps_5cm_1_m1_119.txt';

data = dlmread(filename);
time = 1:length(off_data);
time = time / 1000;

[fX1, fY1, fZ1] = deal(data(:, 1), data(:, 2), data(:, 3));
fR1 = sqrt(fX1.^2 + fY1.^2 + fZ1.^2);

% Subtract offset
fZ1_corrected = fZ1 - offset;


% Mean GRF
mean_fZ1 = mean(fZ1(1:40000))
mean_fZ1_corrected = mean(fZ1_corrected(1:40000))

% Plot offset
figure('NAME', 'Offset')
set(gcf, 'Position', get(0, 'Screensize'));
plot(time, offset_Z1);
grid on
xlabel('Time (s)', 'FontSize', 20);
ylabel('Vertical ground reaction force (N)', 'FontSize', 20);
xticks(0:5:max(time));
yticks(0:500:ceil(max(offset_Z1) / 500) * 500);
xlim([0 max(time)]);
ylim([min(offset_Z1) ceil(max(offset_Z1) / 500) * 500]);
title(off_filename, 'Interpreter', 'none')
ax = gca;
ax.FontSize = 16;

% Plot GRF
figure('NAME', 'Vertical GRF')
set(gcf, 'Position', get(0, 'Screensize'));
plot(time, fZ1);
grid on
xlabel('Time (s)', 'FontSize', 20);
ylabel('Vertical ground reaction force (N)', 'FontSize', 20);
xticks(0:5:max(time));
yticks(0:500:ceil(max(fZ1) / 500) * 500);
xlim([0 max(time)]);
ylim([0 ceil(max(fZ1) / 500) * 500]);
title(off_filename, 'Interpreter', 'none')
ax = gca;
ax.FontSize = 16;

% Plot corrected GRF
figure('NAME', 'Vertical GRF CORRECTED')
set(gcf, 'Position', get(0, 'Screensize'));
plot(time, fZ1_corrected);
grid on
xlabel('Time (s)', 'FontSize', 20);
ylabel('Vertical ground reaction force (N)', 'FontSize', 20);
xticks(0:5:max(time));
yticks(0:500:ceil(max(fZ1_corrected) / 500) * 500);
xlim([0 max(time)]);
ylim([0 ceil(max(fZ1_corrected) / 500) * 500]);
title(off_filename, 'Interpreter', 'none')
ax = gca;
ax.FontSize = 16;