function corrected_vector = remove_offset(original_vector, offset_vector, samp_freq)
	% Remove end of file
	last_line = get_eval_end(offset_vector);
	offset_vector = offset_vector(1:last_line);

	% Get offset time
	time_offset = 0:last_line - 1;
	time_offset = time_offset / samp_freq;

	% Get offset to be removed and correct original file
	offset = mean(offset_vector);

	corrected_vector = original_vector - offset;
end
