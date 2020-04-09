function end_eval = get_eval_end(resultant_vector)
% get_eval_end gets the array index corresponding to the end of the evaluation.
% The end is assumed when there are at least two consecutive seconds of 0
% standard deviation. The resultant vector should be used as input.
%
% resultant_vector should be an array with the resultant vector signal.

	block_size = 1000 % 1 sec * 1000 Hz samp_freq
	n_blocks = size(resultant_vector, 1) / block_size;
	data_std = zeros(n_blocks, 1);
	for i = 1:n_blocks
		start_line = i * block_size - (block_size - 1);
		end_line = i * block_size;
		data_std(i) = std(resultant_vector(start_line:end_line));
	end

	% Find where the array goes from non-zero to zero and vice versa
	transitions = diff([0; data_std == 0; 0]);
	% Get first and last transitions
	first_transition = find(transitions == 1);
	last_transition = find(transitions == -1);
	% Get length of transition
	lenght_transition = last_transition - first_transition;

	if lenght_transition > 2
		end_block = find(transitions == 1);
	else
	end

	end_block = end_block - 1;
	end_eval = end_block * block_size;
end