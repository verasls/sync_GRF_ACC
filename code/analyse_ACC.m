close all
clear
clc

functions_path = [pwd,'/functions'];
addpath(functions_path);

% Read data
filename = '/Volumes/LVERAS/sync_GRF_ACC/data/119/Waist__Impact__119 (2017-12-09)-IMU.csv';
data = readtable(filename, 'HeaderLines', 10);
warning('off', 'MATLAB:table:ModifiedAndSavedVarnames');

% Exctract accelerometry data per axis
aX = data.AccelerometerX;
aY = data.AccelerometerY;
aZ = data.AccelerometerZ;
aR = sqrt(aX.^2 + aY.^2 + aZ.^2); % Compute resultant vector

% Format timestamp variable
timestamp = data.Timestamp;
timestamp = datetime(timestamp, 'Timezone', 'UTC', 'Format', 'yyyy-MM-dd''T''HH:mm:ss.S');

% Plot acceleration over time
figure('NAME', 'Resultant acceleration X Time')
set(gcf, 'Position', get(0, 'Screensize'));
plot(timestamp, aR);
grid on
yticks(0:1:ceil(max(aR)));
xticks(timestamp(1):minutes(10):timestamp(end));

rmpath(functions_path);
