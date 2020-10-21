function correctedVector = removeOffset(originalVector, offsetVector, sampFreq)
	% Remove end of file
	lastLine = getEvalEnd(offsetVector);
	offsetVector = offsetVector(1:lastLine);

	% Get offset time
	timeOffset = 0:lastLine - 1;
	timeOffset = timeOffset / sampFreq;

	% Get offset to be removed and correct original file
	offset = mean(offsetVector);

	correctedVector = originalVector - offset;
end
