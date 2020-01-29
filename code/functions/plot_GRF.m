function plot_GRF(file, platform, vector, GRF_unit, time, GRF, time_pks, pks)
% plot_GRF plots the GRF signal x time and marks the peaks on the plot
%
% platform should be an interger, either 1 or 2
%
% vector should be a character string, either 'vertical' or 'resultant'
%
% GRF_unit should be a character string, eigther 'N' or 'BW'
%
% time should be an array, with the same length as GRF, indicating time
% in seconds
%
% GRF should be an array with the ground reaction force values
%
% time_pks should be an array with the time points of the peaks
%
% pks should be an array with the magnitude of the peaks

	if strcmp(vector, 'vertical') & strcmp(GRF_unit, 'N')
		label = 'Vertical ground reaction force (N)';
	elseif strcmp(vector, 'vertical') & strcmp(GRF_unit, 'BW')
		label = 'Vertical ground reaction force (BW)';
	elseif strcmp(vector, 'resultant') & strcmp(GRF_unit, 'N')
		label = 'Resultant ground reaction force (N)';
	elseif strcmp(vector, 'resultant') & strcmp(GRF_unit, 'BW')
		label = 'Resultant ground reaction force (BW)';
	end

	if platform == 1
		figname = join([file, ' - ', label, ' x Time (s) - Platform 1']);
	elseif platform == 2
		figname = join([file, ' - ', label, ' x Time (s) - Platform 2']);
	end

	if strcmp(GRF_unit, 'N')
		max_GRF = (ceil(max(GRF) / 500) * 500);
		GRF_ticks = 0:500:max_GRF;
	elseif strcmp(GRF_unit, 'BW')
		max_GRF = ceil(max(GRF));
		GRF_ticks = 0:0.5:max_GRF;
	end

	figure('NAME', figname)
	set(gcf, 'Position', get(0, 'Screensize'));
	plot(time, GRF);
	grid on
	hold on
	plot(time_pks, pks, 'x', 'MarkerSize', 10);
	xlabel('Time (s)', 'FontSize', 20);
	ylabel(label, 'FontSize', 20);
	xticks(0:5:max(time));
	yticks(GRF_ticks);
	xlim([0 max(time)]);
	ylim([0 max_GRF]);
	title(file, 'Interpreter', 'none')
	ax = gca;
	ax.FontSize = 16;
end