function correctedSignal = removeOffset(originalSignal, offsetSignal)
% REMOVEOFFSET subtracts an offset from the signal.
%
% Input arguments:
% 	originalSignal: a double array with the signal to subtract the offset from.
% 	offsetSignal: a double array with the offset signal.w
%
% Output arguments:
% 	correctedSignal: a double array with the offset subtracted from the
% 	original signal.

	% Remove end of file
	lastLine = getEvalEnd(offsetSignal);
	offsetSignal = offsetSignal(1:lastLine);

	% Get offset to be removed and correct original file
	offset = mean(offsetSignal);

	correctedSignal = originalSignal - offset;
end
