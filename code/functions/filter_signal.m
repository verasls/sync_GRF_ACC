function filtered = filter_signal(samp_freq, signal)
% filter_signal filters the input signal using a Butterworth low-pass filter
% design
%
% samp_freq should be an interger indicating the sample frequency (Hz)
%
% signal should be an array with the signal to be filtered

	% Create the lowpass filter
	n = 4;  % Filter order
	cutoff = 20;  % Cut-off frequency (Hz)
	fnyq = samp_freq / 2;  % Nyquist frequency (half of the sampling frequency)
	Wn = cutoff / fnyq;  % Filter parameter

	[z, p, k] = butter(n, Wn, 'low');
	[sos, g] = zp2sos(z, p, k);

	% Filter GRF (N)
	filtered = filtfilt(sos, g, signal);
end
