clear
clc
close all

functions_path = [pwd,'/functions'];
addpath(functions_path);

% Acceleration of gravity
G = 9.81;

% Select data file through a GUI
[file, path] = uigetfile('*.csv');

% Get force plates files metadata
grf_files = dir([path, '*.txt']);
% Put file properties into a cell array
grf_files = struct2cell(grf_files)';
% Remove offset file
offset_idx = cellfun('isempty', regexp(grf_files(:, 1), '_vazio_'));
offset_file = grf_files(~offset_idx, 1);
grf_files = grf_files(offset_idx, :);
% Remove walking/running files
run_idx = cellfun('isempty', regexp(grf_files(:, 1), 'km_'));
grf_files = grf_files(run_idx, :);
% Get last modification datetimes
grf_files = sortrows(grf_files, 3);
grf_dtms = datetime(grf_files(:, 3), 'Timezone', 'UTC', ...
		    'Format', 'dd-MMM-yyyy HH:mm:ss');
% Sort array by last modification time and get filenames
grf_names = grf_files(:, 1);

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
acc_data = readtable([path, file], 'HeaderLines', 11, ...
		     'ReadVariableNames', false);

% Format accelerometer timestamp variable
acc_tmstp = table2cell(acc_data(:, 1));
if contains(file, 'RAW')
	acc_tmstp = datetime(acc_tmstp, 'Timezone', 'UTC', ...
			     'Format', 'dd-MM-yyyy HH:mm:ss.S');
elseif contains(file, 'IMU')
	acc_tmstp = datetime(acc_tmstp, 'Timezone', 'UTC', ...
			     'Format', 'yyyy-MM-dd''T''HH:mm:ss.S');
	acc_tmstp = datetime(acc_tmstp, 'Timezone', 'UTC', ...
			     'Format', 'dd-MM-yyyy HH:mm:ss.S');
end

% Get accelerometer data start and end time indices
acc_start_idx = find(acc_tmstp == start_time);
acc_end_idx = find(acc_tmstp == end_time);
% Crop timestamp between these boundaries
acc_tmstp = acc_tmstp(acc_start_idx:acc_end_idx);

% Extract accelerometry data per axis
aX = table2array(acc_data(acc_start_idx:acc_end_idx, 2));
aY = table2array(acc_data(acc_start_idx:acc_end_idx, 3));
aZ = table2array(acc_data(acc_start_idx:acc_end_idx, 4));

% Read all force platform files
disp('Reading force plates data')
if isempty(offset_file)
	disp('No force plates offset file detected; offset not removed')
else
	disp('Reading offset file')
	offset_data = dlmread(char(join([path, offset_file], '')));
	[oX, oY, oZ] = deal(offset_data(:, 1), offset_data(:, 2), ...
			    offset_data(:, 3));
end

fX = [];
fY = [];
fZ = [];
grf_tmstp = [];
for i = 1:size(grf_names)
	grf_filename = [path, char(grf_names(i))];
	grf_data = dlmread(grf_filename);
	% Get data from plate 1 (GRF in N)
	[X, Y, Z] = deal(grf_data(:, 1), grf_data(:, 2), grf_data(:, 3));
	X = remove_offset(X, oX, samp_freq_grf);
	Y = remove_offset(Y, oY, samp_freq_grf);
	Z = remove_offset(Z, oZ, samp_freq_grf);

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
disp(['Ground reaction force signal was resampled to: ', ...
     num2str(samp_freq_grf), 'Hz']);

% Filter accelerometer and force plates signals
% Create the lowpass filter
n = 4;  % Filter order
cutoff = 20;  % Cut-off frequency (Hz)
fnyq = samp_freq_acc / 2;  % Nyquist frequency
Wn = cutoff / fnyq;

[z, p, k] = butter(n, Wn, 'low');
[sos, g] = zp2sos(z, p, k);

disp('Filtering acceleration signal')
aX_filt = filtfilt(sos, g, aX);
aY_filt = filtfilt(sos, g, aY);
aZ_filt = filtfilt(sos, g, aZ);

disp('Filtering ground reaction force signal')
fX_filt = filtfilt(sos, g, fX);
fY_filt = filtfilt(sos, g, fY);
fZ_filt = filtfilt(sos, g, fZ);

% Compute resultant vectors
disp('Computing resultant vectors')
aR = sqrt(aX.^2 + aY.^2 + aZ.^2);
fR = sqrt(fX.^2 + fY.^2 + fZ.^2);
aR_filt = sqrt(aX_filt.^2 + aY_filt.^2 + aZ_filt.^2);
fR_filt = sqrt(fX_filt.^2 + fY_filt.^2 + fZ_filt.^2);

% Plot the filtered and unfiltered signals
figure('NAME', 'Filtered and unfiltered signals')
set(gcf, 'Position', get(0, 'Screensize'));
subplot(2, 1, 1)
plot(acc_tmstp, aR)
hold on
plot(acc_tmstp, aR_filt)
ylabel('Resultant acceleration (g)', 'FontSize', 14)
xlabel('Timestamp', 'FontSize', 14)
title('Acceleration signal', 'FontSize', 18)
subplot(2, 1, 2)
plot(grf_tmstp, fR, '-', 'color', [0.0000 0.4470 0.7419])
hold on
plot(grf_tmstp, fR_filt, '-', 'color', [0.8500 0.3250 0.0980])
ylabel('Resultant ground reaction force (N)', 'FontSize', 14)
xlabel('Timestamp', 'FontSize', 14)
title('Ground reaction force signal', 'FontSize', 18)
suptitle('Filtered signal (orange lines) and unfiltered signal (blue lines)')

% Start synchronization process for the resultant vector
disp(' ')
for i = 1:2%length(grf_names)
	grf_data = fR_filt(:, i);
	grf_time = grf_tmstp(:, i);

	% Crop accelerometer data around the time of the force plate data
	% Get start and end time indices
	start_time = min(grf_time) - minutes(5);
	end_time = max(grf_time) + minutes(5);
	if start_time < min(acc_tmstp)
		start_idx = 1;
	else	
		start_idx = find(acc_tmstp == start_time);
	end
	if end_time > max(acc_tmstp)
		end_idx = length(acc_tmstp);
	else
		end_idx = find(acc_tmstp == end_time);
	end
	% Crop accelerometer timestamp and filtered resultant vector
	acc_data = aR_filt(start_idx:end_idx);
	acc_time = acc_tmstp(start_idx:end_idx);

	% Normalize
	grf_raw_mean = mean(grf_data);
	grf_raw_stdv = std(grf_data);
	grf_data = ((grf_data - grf_raw_mean) / grf_raw_stdv);
	acc_raw_mean = mean(acc_data);
	acc_raw_stdv = std(acc_data);
	acc_data = ((acc_data - acc_raw_mean) / acc_raw_stdv);

	% Plot ground reaction force and acceleration signals to synchronize
	filename = char(grf_names(i));	
	fig10 = figure('NAME', ['Plot slider (', filename, ') - Resultant vector']);
	set(gcf, 'Position', get(0, 'Screensize'));
	plot(acc_time, acc_data)
	xticks(acc_time(1):minutes(1):acc_time(end));
	hold on
	fig11 = plot(grf_time, grf_data);
	hold off
	title({'Adjust the plots using the buttons bellow', ...
	       'Press "Continue" when done'})
	legend('Acceleration', 'Ground reaction force')
	ax = gca;
	ax.FontSize = 15;

	adjusted_time = plot_slider(fig10, fig11);
	lag = adjusted_time - min(grf_time);

	% Make a new plot with the adjusted_time
	% Adjust the grf timestamp
	grf_time = grf_time + lag;
	% Adjust the acc timestamp
	start_time = min(grf_time) - minutes(0.5);
	end_time = max(grf_time) + minutes(0.5);
	start_idx = find(acc_time == start_time);
	end_idx = find(acc_time == end_time);
	% Crop accelerometer timestamp and filtered resultant vector
	acc_data = acc_data(start_idx:end_idx);
	acc_time = acc_time(start_idx:end_idx);

	figure('NAME', ['Time-adjusted signals (', filename, ...
	       ') - Resultant vector'])
	set(gcf, 'Position', get(0, 'Screensize'));
	plot(acc_time, acc_data)
	hold on
	plot(grf_time, grf_data)
	legend('Acceleration', 'Ground reaction force')
	ax = gca;
	ax.FontSize = 15;


	% Find peaks in the acceleration signal
	min_height = 4;
	min_dist = 3;
	[pks_acc, pks_acc_idx] = find_signal_peaks(min_height, min_dist, ...
						   samp_freq_acc, acc_data);
	pks_acc_time = acc_time(pks_acc_idx);

	% Plot the acceleration peaks
	figure('NAME', ['Define region of interest (', filename, ...
	       ') - Resultant vector'])
	set(gcf, 'Position', get(0, 'Screensize'));
	plot(acc_time, acc_data)
	hold on
	plot(grf_time, grf_data)
	legend('Acceleration', 'Ground reaction force')
	ax = gca;
	ax.FontSize = 15;
	plot(pks_acc_time, pks_acc, 'rx', 'MarkerSize', 10, ...
	     'DisplayName', 'Acceleration peaks')


	% Select region of interest
	y_lim = get(gca, 'YLim');
	% Beginning
	title('Click on the BEGINNING of the region of interest')
	[x_beggining, y] = ginput(1);
	x_beggining = num2ruler(x_beggining, ax.XAxis);
	line([x_beggining, x_beggining], y_lim, 'Color', 'k', ...
	     'LineWidth', 2, 'HandleVisibility', 'off')
	% End
	title('Click on the END of the region of interest')
	[x_end, y] = ginput(1);
	x_end = num2ruler(x_end, ax.XAxis);
	line([x_end, x_end], y_lim, 'Color', 'k', 'LineWidth', 2, ...
	     'HandleVisibility', 'off')

	% Remove the peaks out of the region of interest
	pks_keep = pks_acc_time > x_beggining & pks_acc_time < x_end;
	pks_acc = pks_acc(pks_keep);
	pks_acc_time = pks_acc_time(pks_keep);
	pks_acc_idx = pks_acc_idx(pks_keep);

	figure('NAME', ['Peaks in the region of interest (', filename, ...
	       ') - Resultant vector'])
	set(gcf, 'Position', get(0, 'Screensize'));
	plot(acc_time, acc_data)
	hold on
	plot(grf_time, grf_data)
	plot(pks_acc_time, pks_acc, 'rx', 'MarkerSize', 10)
	line([x_beggining, x_beggining], y_lim, 'Color', 'k', 'LineWidth', 2)
	line([x_end, x_end], y_lim, 'Color', 'k', 'LineWidth', 2)
	legend('Acceleration', 'Ground reaction force', 'Acceleration peaks')
	ax = gca;
	ax.FontSize = 15;

	% Find peaks in the ground reaction force signal
	pks_grf = zeros(size(pks_acc));
	pks_grf_idx = zeros(size(pks_acc));
	for i = 1:length(pks_acc)
		idx_min = pks_acc_time(i) - seconds(min_dist);
		idx_max = pks_acc_time(i) + seconds(min_dist);

		idx_min = find(grf_time == idx_min);
		idx_max = find(grf_time == idx_max);

		pks_grf(i) = max(grf_data(idx_min:idx_max));
		pks_grf_idx(i) = find(grf_data(idx_min:idx_max) == pks_grf(i), ...
				      1, 'first') + idx_min - 1;
	end
	pks_grf_time = grf_time(pks_grf_idx);

	plot(pks_grf_time, pks_grf, 'gx', 'MarkerSize', 10, ...
	     'DisplayName', 'Ground reaction force peaks')
	
	% Get values
	if ~isempty(regexp(filename, '\d_\d*cm'))
		jump_type = 'drop jumps';
	elseif ~isempty(regexp(filename, '_Box_Jumps_'))
		jump_type = 'box jumps';
	elseif ~isempty(regexp(filename, '\d_Jumps'))
		jump_type = 'continuous jumps';
	end

	jump_height = char(regexp(filename, '.\dcm', 'Match'));
	jump_height = str2double(regexp(jump_height, '\d*', 'Match'));

	n_peaks = length(pks_grf);
	avg_pks_acc_g = mean(acc_raw_mean + pks_acc * acc_raw_stdv);
	avg_pks_acc_ms2 = avg_pks_acc_g * G;
	avg_pks_grf_N = mean(grf_raw_mean + pks_grf * grf_raw_stdv);
	avg_pks_grf_BW = avg_pks_grf_N / (body_mass * G);

	disp('----------------------------------------')
	disp(' ')
	disp(['File: ', filename])
	disp(['Jump type: ', jump_type])
	disp(['Jump height: ', num2str(jump_height), 'cm'])
	disp('Resultant vector')
	disp(['Number of peaks: ', num2str(n_peaks)])
	disp(['Average acceleration peak (m/s2): ', ...
	     num2str(round(avg_pks_acc_ms2, 1))])
	disp(['Average acceleration peak (g): ', ...
	     num2str(round(avg_pks_acc_g, 1))])
	disp(['Average ground reaction force peak (N): ', ...
	     num2str(round(avg_pks_grf_N, 1))])
	disp(['Average ground reaction force peak (BW): ', ...
	     num2str(round(avg_pks_grf_BW, 1))])
	disp(' ')

	% Get and write synchronization values
	sync_data_tmp = table({filename}, lag, x_beggining, x_end, ...
			      {pks_acc_time}, {pks_grf_time});
	sync_data_tmp.Properties.VariableNames{1} = 'filename';
	sync_data_tmp.Properties.VariableNames{5} = 'pks_acc_time';
	sync_data_tmp.Properties.VariableNames{6} = 'pks_grf_time';

	if exist('sync_data_resultant', 'var')
		sync_data_resultant = [sync_data_resultant; sync_data_tmp];
	else
		sync_data_resultant = sync_data_tmp;
	end
	

	pause(5)
end

% Save sync data into a .mat file
if contains(file, 'ankle', 'IgnoreCase', true)
	if contains(file, 'imu', 'IgnoreCase', true)
		sync_filename = [path, 'sync_data_ankle_imu.mat'];
	elseif contains(file, 'raw', 'IgnoreCase', true)
		sync_filename = [path, 'sync_data_ankle_raw.mat'];
	end
elseif contains(file, 'back', 'IgnoreCase', true)
	if contains(file, 'imu', 'IgnoreCase', true)
		sync_filename = [path, 'sync_data_back_imu.mat'];
	elseif contains(file, 'raw', 'IgnoreCase', true)
		sync_filename = [path, 'sync_data_back_raw.mat'];
	end
elseif contains(file, 'waist', 'IgnoreCase', true)
	if contains(file, 'imu', 'IgnoreCase', true)
		sync_filename = [path, 'sync_data_waist_imu.mat'];
	elseif contains(file, 'raw', 'IgnoreCase', true)
		sync_filename = [path, 'sync_data_waist_raw.mat'];
	end
end
if exist(sync_filename)
	save(sync_filename, 'sync_data_resultant', '-append')
else
	save(sync_filename, 'sync_data_resultant')
end
