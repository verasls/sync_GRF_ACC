function [syncData, extractedData] = syncSignals(ID, vector, grfFile,...
                                                 grfSignal, grfTime,...
                                                 accSignal, accTime,...
                                                 sampFreqAcc, bodyMass, ...
                                                 accPlacement, accType, ...
                                                 usePreSync, goDirect, ...
                                                 preAdjustedTime, ...
                                                 preXBeginning, preXEnd)
% SYNCSIGNALS synchronizes the accelerometer and force plates signals.
%
% Input arguments:
% 	ID: a double scalar with the subject identifier number.
% 	vector: a character array with the vector to be used. Either 'resultant' or
% 	vertical.
% 	grfFile: a character array with the force platform file name.
% 	grfSignal: a double array with the ground reaction force data.
% 	grfTime: a datetime array with the ground reaction force timestamp.
% 	accSignal: a double array with the acceleration data.
% 	accTime: a datetime array with the acceleration timestamp.
% 	sampFreqAcc: a double scalar with the accelerometer sample frequency in Hz.
% 	bodyMass: a double scalar with the subject body mass in kg.
% 	accPlacement: a character array with the accelerometer placement. Either
% 	'ankle', 'back' or 'waist'.
% 	accType: a character array with the accelerometer type. Either 'raw' or
% 	'imu'.
% 	usePreSync: a character array indicating whether to use a previous
% 	synchronization data. Either 'Yes' or 'No'.
% 	goDirect: a character array indicating whether to ask for user confirmation
% 	during the synchronization process. Either 'Yes' or 'No'.
% 	preAdjustedTime: a datetime array with the ground reaction force data
% 	initial timestamp when usePreSync = 'Yes', or an empty array when
% 	usePreSync = 'No'.
% 	preXBeginning: a datetime array with the timestamp of the beginning of the
% 	region of interest for data analysis when usePreSync = 'Yes', or an empty
% 	array when usePreSync = 'No'.
% 	preXEnd: a datetime array with the timestamp of the end of the region of
% 	interest for data analysis when usePreSync = 'Yes', or an empty array when
% 	usePreSync = 'No'.
%
% Output arguments:
% 	syncData: a table with data from the current synchronization process. Data
% 	from one force plate file and vector per line.
% 	extractedData: a table with data extracted from the acceleration and ground
% 	reaction force signals. Data from one force plate file and vector per line.

if ~isempty(preAdjustedTime)
	lag = preAdjustedTime - min(grfTime);
	grfTime = grfTime + lag;
end

% Crop accelerometer data around the time of the grf data
% Get start and end time indices
startTime = min(grfTime) - minutes(5);
endTime = max(grfTime) + minutes(5);
if startTime < min(accTime)
	startIdx = 1;
else
	startIdx = find(accTime == startTime);
end
if endTime > max(accTime)
	endIdx = length(accTime);
else
	endIdx = find(accTime == endTime);
end
% Crop accelerometer signal and time
accSignal = accSignal(startIdx:endIdx);
accTime = accTime(startIdx:endIdx);

% Normalize both signals to plot them together
grfRawMean = mean(grfSignal);
grfRawSd = std(grfSignal);
grfSignal = ((grfSignal - grfRawMean) / grfRawSd);
accRawMean = mean(accSignal);
accRawSd = std(accSignal);
accSignal = ((accSignal - accRawMean) / accRawSd);

% Compute the cross correlation and adjust the signals based on the maximum
% coefficient
if strcmp(usePreSync, 'No')
	r = xcorr(accSignal, grfSignal);
	[~, d] = max(r);
	lag = d - length(accSignal);
	adjust = accTime(lag) - grfTime(1);
	grfTime = grfTime + adjust;
end

% Plot both signals to synchronize
fig10 = figure('NAME', ['Plot slider (', grfFile, ') - ', vector, ' vector']);
set(gcf, 'Position', get(0, 'Screensize'));
plot(accTime, accSignal)
xticks(accTime(1):minutes(1):accTime(end));
hold on
fig11 = plot(grfTime, grfSignal);
hold off
title({'Adjust the plots using the buttons below', ...
      'Press "Continue" when done'})
legend('Acceleration', 'Ground reaction force')
ax = gca;
ax.FontSize = 15;

if strcmp(usePreSync, 'Yes') && strcmp(goDirect, 'Yes')
	adjustedTime = min(grfTime);
else
	adjustedTime = plotSlider(fig10, fig11);
end
lag = adjustedTime - min(grfTime);

% Adjust the grf timestamp
grfTime = grfTime + lag;
% Adjust the acc timestamp
startTime = min(grfTime) - minutes(0.5);
endTime = max(grfTime) + minutes(0.5);
startIdx = find(accTime == startTime);
endIdx = find(accTime == endTime);
% Crop accelerometer signal and time
accSignal = accSignal(startIdx:endIdx);
accTime = accTime(startIdx:endIdx);

% Make a new plot with the adjusted time
figure('NAME', ['Time-adjusted signals (', grfFile, ') - ', vector, ' vector'])
set(gcf, 'Position', get(0, 'Screensize'));
plot(accTime, accSignal)
hold on
plot(grfTime, grfSignal);
hold off
legend('Acceleration', 'Ground reaction force')
ax = gca;
ax.FontSize = 15;

% Find peaks in the acceleration signal
minHeight = 5 * mean(abs(accSignal));
if ~isempty(regexp(grfFile, '\d_Jumps', 'once'))
	minDist = 0.2 * sampFreqAcc;
else
	minDist = 4 * sampFreqAcc;
end
[pksAcc, pksAccIdx] = findpeaks(accSignal, 'MINPEAKHEIGHT', minHeight, ...
                                'MINPEAKDISTANCE', minDist);
pksAccTime = accTime(pksAccIdx);

% Plot the acceleration peaks
figure('NAME', ['Define region of interest (', char(grfFile), ') - ', ...
       vector, ' vector'])
set(gcf, 'Position', get(0, 'Screensize'));
plot(accTime, accSignal)
hold on
plot(grfTime, grfSignal);
legend('Acceleration', 'Ground reaction force')
ax = gca;
ax.FontSize = 15;
plot(pksAccTime, pksAcc, 'rx', 'MarkerSize', 10, ...
     'DisplayName', 'Acceleration peaks')

% Select region of interest
yLim = get(gca, 'YLim');
% Plot the pre-defined region of interest (if exist)
if strcmp(usePreSync, 'Yes')
	line([preXBeginning, preXBeginning], yLim, 'Color', 'k', ...
	     'LineWidth', 2, 'HandleVisibility', 'off')
	line([preXEnd, preXEnd], yLim, 'Color', 'k', ...
	     'LineWidth', 2, 'HandleVisibility', 'off')
end
% Beginning
title('Click on the BEGINNING of the region of interest')
if strcmp(usePreSync, 'Yes') && strcmp(goDirect, 'Yes')
	xBeginning = preXBeginning;
else
	[xBeginning, ~] = ginput(1);
	xBeginning = num2ruler(xBeginning, ax.XAxis);
end
line([xBeginning, xBeginning], yLim, 'Color', 'k', 'LineWidth', 2, ...
     'HandleVisibility', 'off')
% End
title('Click on the END of the region of interest')
if strcmp(usePreSync, 'Yes') && strcmp(goDirect, 'Yes')
	xEnd = preXEnd;
else
	[xEnd, ~] = ginput(1);
	xEnd = num2ruler(xEnd, ax.XAxis);
end
line([xEnd, xEnd], yLim, 'Color', 'k', 'LineWidth', 2, ...
     'HandleVisibility', 'off')

% Remove the peaks out of the region of interest
pksKeep = pksAccTime > xBeginning & pksAccTime < xEnd;
pksAcc = pksAcc(pksKeep);
pksAccIdx = pksAccIdx(pksKeep);
pksAccTime = pksAccTime(pksKeep);

figure('NAME', ['Peaks in the region of interest (', grfFile, ...
       ') - ', vector, ' vector'])
set(gcf, 'Position', get(0, 'Screensize'));
plot(accTime, accSignal)
hold on
plot(grfTime, grfSignal)
plot(pksAccTime, pksAcc, 'rx', 'MarkerSize', 10)
line([xBeginning, xBeginning], yLim, 'Color', 'k', 'LineWidth', 2)
line([xEnd, xEnd], yLim, 'Color', 'k', 'LineWidth', 2)
legend('Acceleration', 'Ground reaction force', 'Acceleration peaks')
ax = gca;
ax.FontSize = 15;

% Find peaks in the ground reaction force signal
pksGrf = zeros(size(pksAcc));
pksGrfIdx = zeros(size(pksAcc));
for i = 1:length(pksAcc)
	idxMin = pksAccTime(i) - seconds(minDist / sampFreqAcc);
	if idxMin < min(grfTime)
		idxMin = 1;
	else
		idxMin = find(grfTime == idxMin);
	end
	idxMax = pksAccTime(i) + seconds(minDist / sampFreqAcc);
	if idxMax > max(grfTime)
		idxMax = length(grfSignal);
	else
		idxMax = find(grfTime == idxMax);
	end

	pksGrf(i) = max(grfSignal(idxMin:idxMax));
	pksGrfIdx(i) = find(grfSignal(idxMin:idxMax) == pksGrf(i), ...
	                    1, 'first') + idxMin - 1;
end
pksGrfTime = grfTime(pksGrfIdx);

plot(pksGrfTime, pksGrf, 'gx', 'MarkerSize', 10, ...
     'DisplayName', 'Ground reaction force peaks')

% Pause to inspect results
if strcmp(usePreSync, 'No') || strcmp(goDirect, 'No')
	pause(3)
end

% Define starting point of each curve in the ground reaction force and
% acceleration signals
nPeaks = length(pksGrf);
curveStartGrf = zeros(nPeaks, 1);
curveStartAcc = zeros(nPeaks, 1);
for  i = 1:nPeaks
	for j = pksGrfIdx(i)-1:-1:2
		df = grfSignal(j + 1) - grfSignal(j -1);
		if df < 0
			curveStartGrf(i) = j;
			break
		end
	end
end
for i = 1:nPeaks
	for j = pksAccIdx(i)-1:-1:2
		df = accSignal(j + 1) - accSignal(j - 1);
		if df < 0
			curveStartAcc(i) = j;
			break
		end
	end
end

figure('NAME', ['Start and end points of each curve (', grfFile, ...
       ') - ', vector, ' vector'])
set(gcf, 'Position', get(0, 'Screensize'));
subplot(2, 1, 1)
plot(grfSignal)
hold on
plot(curveStartGrf + 1, grfSignal(curveStartGrf + 1), 'gx', 'MarkerSize', 10)
plot(pksGrfIdx, pksGrf, 'rx', 'MarkerSize', 10)
legend('Ground reaction force', 'Curve start', 'Curve end (peak)')
ax = gca;
ax.FontSize = 12;

subplot(2, 1, 2)
plot(accSignal)
hold on
plot(curveStartAcc + 1, accSignal(curveStartAcc + 1), 'gx', 'MarkerSize', 10)
plot(pksAccIdx, pksAcc, 'rx', 'MarkerSize', 10)
legend('Acceleration', 'Curve start', 'Curve end (peak)')
ax = gca;
ax.FontSize = 12;

% Pause to inspect results
if strcmp(usePreSync, 'No') || strcmp(goDirect, 'No')
	pause(3)
end

% Get values
if ~isempty(regexp(grfFile, '\d_\d*cm', 'once'))
	jumpType = {'drop jumps'};
elseif ~isempty(regexp(grfFile, '_Box_Jumps_', 'once'))
	jumpType = {'box jumps'};
elseif ~isempty(regexp(grfFile, '\d_Jumps', 'once'))
	jumpType = {'continuous jumps'};
end

jumpHeight = char(regexp(char(grfFile), '.\dcm', 'Match'));
jumpHeight = str2double(regexp(jumpHeight, '\d*', 'Match'));

vector = {vector};

% Compute ground reaction force and acceleration variables
pAccGMean = mean(accRawMean + pksAcc * accRawSd);
pAccGSd = std(accRawMean + pksAcc * accRawSd);
pAccMs2Mean = pAccGMean * 9.81;
pAccMs2Sd = pAccGSd * 9.81;
pGrfNMean = mean(grfRawMean + pksGrf * grfRawSd);
pGrfNSd = std(grfRawMean + pksGrf * grfRawSd);
pGrfBwMean = pGrfNMean / (bodyMass * 9.81);
pGrfBwSd = pGrfNSd / (bodyMass * 9.81);

% Compute loading rate and acceleration transient rate variables
% Preallocate a matrix for the derivatives
nRows = max((pksGrfIdx - curveStartGrf) - 1);
nCols = nPeaks;
dFdT = NaN(nRows, nCols);
% Compute the derivatives
for i = 1:nPeaks
	for j = curveStartGrf(i)+1:pksGrfIdx(i)-1
		dF = grfSignal(j + 1) - grfSignal(j - i);
		dT = 2 / sampFreqAcc;
		dFdT(j - curveStartGrf(i), i) = dF / dT;
	end
end

pLrNsMean = mean(max(dFdT, [], 'omitnan'));
pLrNsSd = std(max(dFdT, [], 'omitnan'));
aLrNsMean = mean(mean(dFdT, 'omitnan'));
aLrNsSd = std(mean(dFdT, 'omitnan'));
pLrNsMean = grfRawMean + pLrNsMean * grfRawSd;
pLrNsSd = grfRawMean + pLrNsSd * grfRawSd;
aLrNsMean = grfRawMean + aLrNsMean * grfRawSd;
aLrNsSd = grfRawMean + aLrNsSd * grfRawSd;
pLrBwsMean = pLrNsMean / (bodyMass * 9.81);
pLrBwsSd = pLrNsSd / (bodyMass * 9.81);
aLrBwsMean = aLrNsMean / (bodyMass * 9.81);
aLrBwsSd = aLrNsSd / (bodyMass * 9.81);

% Preallocate a matrix for the derivatives
nRows = max((pksAccIdx - curveStartAcc) - 1);
nCols = nPeaks;
dFdT = NaN(nRows, nCols);
% Compute the derivatives
for i = 1:nPeaks
	for j = curveStartAcc(i)+1:pksAccIdx(i)-1
		dF = accSignal(j + 1) - accSignal(j - i);
		dT = 2 / sampFreqAcc;
		dFdT(j - curveStartAcc(i), i) = dF / dT;
	end
end

pAtrGsMean = mean(max(dFdT, [], 'omitnan'));
pAtrGsSd = std(max(dFdT, [], 'omitnan'));
aAtrGsMean = mean(mean(dFdT, 'omitnan'));
aAtrGsSd = std(mean(dFdT, 'omitnan'));
pAtrGsMean = accRawMean + pAtrGsMean * accRawSd;
pAtrGsSd = accRawMean + pAtrGsSd * accRawSd;
aAtrGsMean = accRawMean + aAtrGsMean * accRawSd;
aAtrGsSd = accRawMean + aAtrGsSd * accRawSd;
pAtrMs3Mean = pAtrGsMean * 9.81;
pAtrMs3Sd = pAtrGsSd * 9.81;
aAtrMs3Mean = aAtrGsMean * 9.81;
aAtrMs3Sd = aAtrGsSd * 9.81;

disp('----------------------------------------')
disp(' ')
disp(['File: ', grfFile])
disp(['Jump type: ', char(jumpType)])
disp(['Jump height: ', num2str(jumpHeight), 'cm'])
disp('Resultant vector')
disp(['Number of peaks: ', num2str(nPeaks)])
disp(['Average acceleration peak (m/s2): ', ...
     num2str(round(pAccMs2Mean, 1))])
disp(['Average acceleration peak (g): ', ...
     num2str(round(pAccGMean, 1))])
disp(['Average ground reaction force peak (N): ', ...
     num2str(round(pGrfNMean, 1))])
disp(['Average ground reaction force peak (BW): ', ...
     num2str(round(pGrfBwMean, 1))])
disp(['Average acceleration transient rate peak (m/s3): ', ...
     num2str(round(pAtrMs3Mean, 1))])
disp(['Average acceleration transient rate peak (g/s): ', ...
     num2str(round(pAtrGsMean, 1))])
disp(['Average loading rate peak (N/s): ', ...
     num2str(round(pLrNsMean, 1))])
disp(['Average loading rate peak (BW/s): ', ...
     num2str(round(pLrBwsMean, 1))])
disp(' ')

% Put values in a table
extractedData = table(ID, {grfFile}, accPlacement, accType, jumpType, ...
                      jumpHeight, bodyMass, vector, nPeaks, pAccGMean, ...
                      pAccGSd, pAccMs2Mean, pAccMs2Sd, pGrfNMean, ...
                      pGrfNSd, pGrfBwMean, pGrfBwSd, pAtrGsMean, ...
                      pAtrGsSd, pAtrMs3Mean, pAtrMs3Sd, pLrNsMean, ...
                      pLrNsSd, pLrBwsMean, pLrBwsSd, aAtrGsMean, ...
                      aAtrGsSd, aAtrMs3Mean, aAtrMs3Sd, aLrNsMean, ...
                      aLrNsSd, aLrBwsMean, aLrBwsSd);
extractedData.Properties.VariableNames{2} = 'filename';

% Get and write synchronization values
syncData = table({grfFile}, adjustedTime, xBeginning, xEnd, ...
                 {pksAccTime}, {pksGrfTime});
syncData.Properties.VariableNames{1} = 'filename';
syncData.Properties.VariableNames{5} = 'pksAccTime';
syncData.Properties.VariableNames{6} = 'pksGrfTime';

end
