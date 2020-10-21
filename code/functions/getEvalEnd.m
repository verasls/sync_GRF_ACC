function endEval = getEvalEnd(vector)
% getEvalEnd gets the array index corresponding to the end of the evaluation.
% The end is assumed when there are at least two consecutive seconds of 0
% standard deviation.
%
% vector should be an array with the ground reaction force vector signal.

	blockSize = 1000; % 1 sec * 1000 Hz samp_freq
	nBlocks = size(vector, 1) / blockSize;
	dataSd = zeros(nBlocks, 1);
	for i = 1:nBlocks
		startIdx = i * blockSize - (blockSize - 1);
		endIdx = i * blockSize;
		dataSd(i) = std(vector(startIdx:endIdx));
	end

	% Find where the array goes from non-zero to zero and vice versa
	transitions = diff([0; dataSd == 0; 0]);
	% Get first and last transitions
	firstTransition = find(transitions == 1);
	lastTransition = find(transitions == -1);
	% Get length of transition
	lenghtTransition = lastTransition - firstTransition;

	if lenghtTransition > 2
		endBlock = find(transitions == 1);
	else
	end

	endBlock = endBlock - 1;
	endEval = endBlock * blockSize;
end