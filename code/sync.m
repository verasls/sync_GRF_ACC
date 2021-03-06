clear
clc
close all

functionsPath = [pwd,'/functions'];
addpath(functionsPath);

% Select data file through a GUI
[file, path] = uigetfile('*.csv');

% Get selected accelerometer placement
if regexpi(file, 'ankle')
	accPlacement = 'ankle';
elseif regexpi(file, 'back')
	accPlacement = 'back';
elseif regexpi(file, 'waist')
	accPlacement = 'waist';
end
% Get selected accelerometer type
if regexpi(file, 'imu')
	accType = 'imu';
elseif regexpi(file, 'raw')
	accType = 'raw';
end
% Get force plates files metadata
grfFiles = dir([path, '*.txt']);
% Put file properties into a cell array
grfFiles = struct2cell(grfFiles)';
% Remove offset file
offsetIdx = cellfun('isempty', regexp(grfFiles(:, 1), '_vazio_'));
offsetFile = grfFiles(~offsetIdx, 1);
grfFiles = grfFiles(offsetIdx, :);
% Remove walking/running files
runIdx = cellfun('isempty', regexp(grfFiles(:, 1), 'km_'));
grfFiles = grfFiles(runIdx, :);
% Remove static balance files
balanceIdx = cellfun('isempty', regexp(grfFiles(:, 1), '_EE_'));
grfFiles = grfFiles(balanceIdx, :);
% Remove hidden files
hiddenIdx = ~startsWith(grfFiles(:, 1), '.');
grfFiles = grfFiles(hiddenIdx, :);
% Remove other files
otherIdx = cellfun('isempty', regexp(grfFiles(:, 1), '_Tacel_Tplat_'));
grfFiles = grfFiles(otherIdx, :);
% Get last modification datetimes
grfFiles = sortrows(grfFiles, 3);
grfDtms = datetime(grfFiles(:, 3), 'Timezone', 'UTC', ...
                   'Format', 'dd-MMM-yyyy HH:mm:ss');
% Sort array by last modification time and get filenames
grfNames = grfFiles(:, 1);

% Get start and end times based on the times found in the GRF files
startTime = min(grfDtms) - minutes(5);
endTime = max(grfDtms) + minutes(5);

% Obtain ID variables and body mass
fileEx = grfNames{1}; % Select a file to obtain the variables below
ID = str2double(fileEx(end - 6:end - 4));
trial = str2double(fileEx(end - 8:end - 8));
bodyMassData = dlmread('../data/body_mass.txt', ',', 1, 0);
idRow = find(bodyMassData(:, 1) == ID & bodyMassData(:, 2) == trial);
bodyMass = round(bodyMassData(idRow, 3), 2);

% Display subject info
disp(['Selected subject: ID ', num2str(ID)])
disp(['Subject body mass: ', num2str(bodyMass), 'kg'])
disp(['Selected acceletometer file: ', file])

% Sample frequency (Hz)
sampFreqGrf = 1000;
sampFreqAcc = 100;
disp(['Accelerometer sampling frequency: ', num2str(sampFreqAcc), 'Hz'])
disp(['Force platform sampling frequency: ', num2str(sampFreqGrf), 'Hz'])

% Read accelerometer data
disp('Reading accelerometer data')
accData = readtable([path, file], 'HeaderLines', 11, ...
                    'ReadVariableNames', false);

% Format accelerometer timestamp variable
accTmstp = table2cell(accData(:, 1));
if contains(file, 'RAW')
	accTmstp = datetime(accTmstp, 'Timezone', 'UTC', ...
	                    'Format', 'dd-MM-yyyy HH:mm:ss.S');
elseif contains(file, 'IMU')
	accTmstp = datetime(accTmstp, 'Timezone', 'UTC', ...
	                    'Format', 'yyyy-MM-dd''T''HH:mm:ss.S');
	accTmstp = datetime(accTmstp, 'Timezone', 'UTC', ...
	                    'Format', 'dd-MM-yyyy HH:mm:ss.S');
end

% Get accelerometer data start and end time indices
if startTime <= min(accTmstp)
	accStartIdx = 1;
else
	accStartIdx = find(accTmstp == startTime);
end
if endTime >= max(accTmstp)
	accEndIdx = length(accTmstp);
else
	accEndIdx = find(accTmstp == endTime);
end
% Crop timestamp between these boundaries
accTmstp = accTmstp(accStartIdx:accEndIdx);

% Extract accelerometry data per axis
aX = table2array(accData(accStartIdx:accEndIdx, 2));
aY = table2array(accData(accStartIdx:accEndIdx, 3));
aZ = table2array(accData(accStartIdx:accEndIdx, 4));

% Read all force platform files
disp('Reading force plates data')
if isempty(offsetFile)
	disp('No force plates offset file detected; offset not removed')
else
	disp('Reading offset file')
	offsetData = dlmread(char(join([path, offsetFile], '')));
	[oX, oY, oZ] = deal(offsetData(:, 1), offsetData(:, 2), ...
                      offsetData(:, 3));
end

fX = [];
fY = [];
fZ = [];
grfTmstp = [];
for i = 1:size(grfNames)
	grfFilename = [path, char(grfNames(i))];
	grfData = dlmread(grfFilename);
	% Get data from plate 1 (GRF in N)
	[X, Y, Z] = deal(grfData(:, 1), grfData(:, 2), grfData(:, 3));
	if exist('oX', 'var')
		X = removeOffset(X, oX);
		Y = removeOffset(Y, oY);
		Z = removeOffset(Z, oZ);
	end

	% Resample force plates data to the accelerometer sampling frequency
	xResamp = resample(X, sampFreqAcc, sampFreqGrf);
	yResamp = resample(Y, sampFreqAcc, sampFreqGrf);
	zResamp = resample(Z, sampFreqAcc, sampFreqGrf);

	% Create timestamp
	nSec = size(grfData, 1) / sampFreqGrf;
	t1 = grfDtms(i);
	t2 = t1 + seconds(nSec);
	tmstp = t1:seconds(1 / sampFreqAcc):t2;
	tmstp = tmstp';
	tmstp = tmstp(1:end - 1);

	% Append values to final arraysfX = [fX, X_resamp];
	fX = [fX, xResamp];
	fY = [fY, yResamp];
	fZ = [fZ, zResamp];
	grfTmstp = [grfTmstp, tmstp];
end
sampFreqGrf = sampFreqAcc;
disp(['Ground reaction force signal was resampled to: ', ...
     num2str(sampFreqGrf), 'Hz']);

% Filter accelerometer and force plates signals
% Create the lowpass filter
n = 4;  % Filter order
cutoff = 20;  % Cut-off frequency (Hz)
fnyq = sampFreqAcc / 2;  % Nyquist frequency
wn = cutoff / fnyq;

[z, p, k] = butter(n, wn, 'low');
[sos, g] = zp2sos(z, p, k);

disp('Filtering acceleration signal')
aXFilt = filtfilt(sos, g, aX);
aYFilt = filtfilt(sos, g, aY);
aZFilt = filtfilt(sos, g, aZ);

disp('Filtering ground reaction force signal')
fXFilt = filtfilt(sos, g, fX);
fYFilt = filtfilt(sos, g, fY);
fZFilt = filtfilt(sos, g, fZ);
% Compute resultant vectors
disp('Computing resultant vectors')
aR = sqrt(aX.^2 + aY.^2 + aZ.^2);
fR = sqrt(fX.^2 + fY.^2 + fZ.^2);
aRFilt = sqrt(aXFilt.^2 + aYFilt.^2 + aZFilt.^2);
fRFilt = sqrt(fXFilt.^2 + fYFilt.^2 + fZFilt.^2);

% Start synchronization process for the resultant vector
disp(' ')
disp('----------------------------------------')
disp('------------RESULTANT VECTOR------------')
disp('----------------------------------------')
disp(' ')
vector = 'resultant';
% Check if there is a sync_data .mat file available and ask to use it
if ~isempty(dir([path, 'sync_data_', accPlacement, '_', accType, '.mat']))
	toLoad = dir([path, 'sync_data_', accPlacement, '_', accType, '*.mat']);
	toLoad = toLoad.name;
	goDirect = 'Yes';
	usePreSync = questdlg(['A previous synchronization was found', ...
	                      ' for the resultant vector of the', ...
	                      ' selected accelerometer placement and', ...
	                      ' type. Do you want to use it?'], ...
	                      '', 'No', 'Yes', 'Yes');
elseif ~isempty(dir([path, 'sync_data_', accPlacement, '*.mat']))
	toLoad = dir([path, 'sync_data_', accPlacement, '*.mat']);
	toLoad = toLoad.name;
	goDirect = 'No';
	usePreSync = questdlg(['A previous synchronization was found', ...
	                      ' for the resultant vector of the', ...
	                      ' selected accelerometer placement.', ...
	                      ' Do you want to use it?'], ...
	                      '', 'No', 'Yes', 'Yes');
elseif ~isempty(dir([path, 'sync_data_*', accType, '.mat']))
	toLoad = dir([path, 'sync_data_*', accType, '.mat']);
	toLoad = toLoad.name;
	goDirect = 'No';
	usePreSync = questdlg(['A previous synchronization was found', ...
	                      ' for the resultant vector of the', ...
	                      ' selected accelerometer type.', ...
	                      ' Do you want to use it?'], ...
	                      '', 'No', 'Yes', 'Yes');
else
	usePreSync = 'No';
	goDirect = 'No';
end

if strcmp(usePreSync, 'Yes')
	load([path, toLoad])
	showPlots = questdlg('Show plots?', '', 'No', 'Yes', 'Yes');
else
	showPlots = 'Yes';
	preAdjustedTime = [];
	preXBeginning = [];
	preXEnd = [];
end

for i = 1:length(grfNames)
	grfFile = char(grfNames(i));
	grfSignal = fRFilt(:, i);
	grfTime = grfTmstp(:, i);
	accSignal = aRFilt;
	accTime = accTmstp;
	if strcmp(usePreSync, 'Yes')
		preAdjustedTime = syncDataResultant.adjustedTime(i);
		preXBeginning = syncDataResultant.xBeginning(i);
		preXEnd = syncDataResultant.xEnd(i);
	end

	% Start synchronization
	[syncDataTmp, extractedDataTmp] = syncSignals(ID, vector, grfFile, grfSignal, ...
	                                              grfTime, accSignal, accTime, ...
	                                              sampFreqAcc, bodyMass, ...
	                                              accPlacement, accType, ...
	                                              usePreSync, goDirect, ...
	                                              showPlots, ...
	                                              preAdjustedTime, ...
	                                              preXBeginning, preXEnd);

	% Build extracted data table
	if exist('extractedDataRes', 'var')
		extractedDataRes = [extractedDataRes; extractedDataTmp];
	else
		extractedDataRes = extractedDataTmp;
	end

	% Build sync data table
	if exist('syncDataResTmp', 'var')
		syncDataResTmp = [syncDataResTmp; syncDataTmp];
        else
		syncDataResTmp = syncDataTmp;
	end
end

% Save sync data into a .mat file
if contains(file, 'ankle', 'IgnoreCase', true)
	if contains(file, 'imu', 'IgnoreCase', true)
		syncFilename = [path, 'sync_data_ankle_imu.mat'];
	elseif contains(file, 'raw', 'IgnoreCase', true)
		syncFilename = [path, 'sync_data_ankle_raw.mat'];
	end
elseif contains(file, 'back', 'IgnoreCase', true)
	if contains(file, 'imu', 'IgnoreCase', true)
		syncFilename = [path, 'sync_data_back_imu.mat'];
	elseif contains(file, 'raw', 'IgnoreCase', true)
		syncFilename = [path, 'sync_data_back_raw.mat'];
	end
elseif contains(file, 'waist', 'IgnoreCase', true)
	if contains(file, 'imu', 'IgnoreCase', true)
		syncFilename = [path, 'sync_data_waist_imu.mat'];
	elseif contains(file, 'raw', 'IgnoreCase', true)
		syncFilename = [path, 'sync_data_waist_raw.mat'];
	end
end

syncDataResultant = syncDataResTmp;
if exist(syncFilename, 'file')
	save(syncFilename, 'syncDataResultant', '-append')
else
	save(syncFilename, 'syncDataResultant')
end


% Read sync_data .mat file and check whether there is an object with vertical
% vector sync_data
syncMatfile = whos('-file', syncFilename);
if any(contains({syncMatfile.name}, 'vertical'))
	load(syncFilename)
	preAdjustedTime = syncDataVertical.adjustedTime;
else
	preAdjustedTime = syncDataResultant.adjustedTime;
end

% % Start synchronization process for the vertical vector
disp(' ')
disp('----------------------------------------')
disp('------------VERTICAL VECTOR-------------')
disp('----------------------------------------')
disp(' ')
vector = 'vertical';
% Check if there is a sync_data .mat file available and ask to use it
if exist('syncDataVertical', 'var') && contains(toLoad, accType) && ...
	contains(toLoad, accPlacement)
	usePreSync = questdlg(['A previous synchronization was found', ...
	                      ' for the vertical vector of the selected', ...
	                      ' accelerometer placement and type.', ...
	                      ' Do you want to use it?'], ...
	                      '', 'No', 'Yes', 'Yes');
elseif exist('syncDataVertical', 'var') && ~contains(toLoad, accType) && ...
	contains(toLoad, accPlacement)
	usePreSync = questdlg(['A previous synchronization was found', ...
	                      ' for the vertical vector of the selected', ...
	                      ' accelerometer placement.', ...
	                      ' Do you want to use it?'], ...
	                      '', 'No', 'Yes', 'Yes');
elseif exist('syncDataVertical', 'var') && contains(toLoad, accType) && ...
	~contains(toLoad, accPlacement)
	usePreSync = questdlg(['A previous synchronization was found', ...
	                      ' for the vertical vector of the selected', ...
	                      ' accelerometer type.', ...
	                      ' Do you want to use it?'], ...
	                      '', 'No', 'Yes', 'Yes');
elseif ~exist('syncDataVertical', 'var')
	usePreSync = questdlg(['No previous synchronization was found', ...
	                      ' for the vertical vector of the selected', ...
	                      ' accelerometer placement. Do you want to', ...
	                      ' use the synchronization of the', ...
	                      ' resultant vector?'], ...
	                      '', 'No', 'Yes', 'Yes');
end

if strcmp(usePreSync, 'Yes')
	goDirect = 'Yes';
	showPlots = 'No';
end

if exist('syncDataVertical', 'var')
	syncDataToUse = syncDataVertical;
else
	syncDataToUse = syncDataResultant;
end

if strcmp(usePreSync, 'No')
	preAdjustedTime = [];
	preXBeginning = [];
	preXEnd = [];
	showPlots = 'Yes';
end

for i = 1:length(grfNames)
	grfFile = char(grfNames(i));
	grfSignal = fZFilt(:, i);
	grfTime = grfTmstp(:, i);
	% Multiply by - 1 to correct for accelerometer orientation
	accSignal = - 1 * aYFilt;
	accTime = accTmstp;
	if strcmp(usePreSync, 'Yes')
		preAdjustedTime = syncDataToUse.adjustedTime(i);
		preXBeginning = syncDataToUse.xBeginning(i);
		preXEnd = syncDataToUse.xEnd(i);
	end

	% Start synchronization
	[syncDataTmp, extractedDataTmp] = syncSignals(ID, vector, grfFile, grfSignal, ...
	                                              grfTime, accSignal, accTime, ...
	                                              sampFreqAcc, bodyMass, ...
	                                              accPlacement, accType, ...
	                                              usePreSync, goDirect, ...
	                                              showPlots, ...
	                                              preAdjustedTime, ...
	                                              preXBeginning, preXEnd);


	% Build extracted data table
	if exist('extractedDataVer', 'var')
		extractedDataVer = [extractedDataVer; extractedDataTmp];
	else
		extractedDataVer = extractedDataTmp;
	end

	% Build sync data table
	if exist('syncDataVerTmp', 'var')
		syncDataVerTmp = [syncDataVerTmp; syncDataTmp];
        else
		syncDataVerTmp = syncDataTmp;
	end
end

% Save sync data into a .mat file
syncDataVertical = syncDataVerTmp;
if exist(syncFilename, 'file')
	save(syncFilename, 'syncDataVertical', '-append')
else
	save(syncFilename, 'syncDataVertical')
end

% Concatenate data from resultant and vertical vectors
extractedData = [extractedDataRes; extractedDataVer];
dataPath = [path, 'extracted_data_', accPlacement, '_', accType, '.csv'];
writetable(extractedData, dataPath)

rmpath(functionsPath);

runAgain = questdlg('Analyse another file', '', 'No', 'Yes', 'Yes');
if strcmp(runAgain, 'Yes')
	run('sync.m')
end
