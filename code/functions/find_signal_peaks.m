function[pks, time_of_pks] = find_signal_peaks(min_hei, min_dist, ...
											   samp_freq, signal)
% find_signal_peaks finds peaks in a signal with min height and min distance
% as criteria
%
% min_hei should be a numeric value indicating the minimun height of a peak,
% in multiples of the average of the signal
%
% min_dist should be a numeric value indicating the minimun horizontal distance
% between peaks, in seconds
%
% samp_freq should be an interger indicating the sample frequency, in Hz
%
% signal should be an array with the signal

	min_height = min_hei * mean(signal);
	min_distance = min_dist * samp_freq;

	[pks, locs] = findpeaks(signal, 'MINPEAKHEIGHT', min_height, ...
							'MINPEAKDISTANCE', min_distance);

	time_of_pks = locs / samp_freq;

	warning('off', 'signal:findpeaks:largeMinPeakHeight')
end