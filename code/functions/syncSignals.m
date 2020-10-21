function [syncData, extractedData] = syncSignals(ID, vector, grfFile,...
                                                 grfSignal, grfTime,...
                                                 accSignal, accTime,...
                                                 sampFreqAcc, bodyMass, ...
                                                 accPlacement, accType, ...
                                                 usePreSync, goDirect, ...
                                                 preAdjustedTime, ...
                                                 preXBeginning, preXEnd)
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
	adjustedTime = plot_slider(fig10, fig11);
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
minHeight = 4;
minDist = 3;
[pksAcc, pksAccIdx] = find_signal_peaks(minHeight, minDist, ...
                                        sampFreqAcc, accSignal);
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
pksAccTime = pksAccTime(pksKeep);
pksAccIdx = pksAccIdx(pksKeep);

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
	idxMin = pksAccTime(i) - seconds(minDist);
	idxMin = find(grfTime == idxMin);
	idxMax = pksAccTime(i) - seconds(minDist);
	idxMax = find(grfTime == idxMax);

	pksGrf(i) = max(grfSignal(idxMin:idxMax));
	pksGrfIdx(i) = find(grfSignal(idxMin:idxMax) == pksGrf(i), ...
	                    1, 'first') + idxMin - 1;
end
pksGrfTime = grfTime(pksGrfIdx);

plot(pksGrfTime, pksGrf, 'gx', 'MarkerSize', 10, ...
     'DisplayName', 'Ground reaction force peaks')

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
nPeaks = length(pksGrf);
pAccGMean = mean(accRawMean + pksAcc * accRawSd);
pAccGSd = std(accRawMean + pksAcc * accRawSd);
pAccMs2Mean = pAccGMean * 9.81;
pAccMs2Sd = pAccGSd * 9.81;
pGrfNMean = mean(grfRawMean + pksGrf * grfRawSd);
pGrfNSd = std(grfRawMean + pksGrf * grfRawSd);
pGrfBwMean = pGrfNMean / (bodyMass * 9.81);
pGrfBwSd = pGrfNSd / (bodyMass * 9.81);

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
disp(' ')

% Put values in a table
extractedData = table(ID, {grfFile}, accPlacement, accType, jumpType, ...
                      jumpHeight, bodyMass, vector, nPeaks, pAccGMean, ...
                      pAccGSd, pAccMs2Mean, pAccMs2Sd, pGrfNMean, ...
                      pGrfNSd, pGrfBwMean, pGrfBwSd);
extractedData.Properties.VariableNames{2} = 'filename';

% Get and write synchronization values
syncData = table({grfFile}, adjustedTime, xBeginning, xEnd, ...
                 {pksAccTime}, {pksGrfTime});
syncData.Properties.VariableNames{1} = 'filename';
syncData.Properties.VariableNames{5} = 'pksAccTime';
syncData.Properties.VariableNames{6} = 'pksGrfTime';

end