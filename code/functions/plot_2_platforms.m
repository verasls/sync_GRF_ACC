function plot_2_platforms(file, vector, GRF_unit, time, GRF1, GRF2, ...
						  time_pks1, time_pks2, pks1, pks2)
% plot_2_platforms plots the GRF signal x time and marks the peaks on the plot
% with data from both force platforms
%
% vector should be a character string, either 'vertical' or 'resultant'
%
% GRF_unit should be a character string, eigther 'N' or 'BW'
%
% time should be an array, with the same length as GRF, indicating time
% in seconds
%
% GRF1 and GRF2 should be arrays with the ground reaction force values from the
% platforms 1 and 2, respectively
%
% time_pks1 and time_pks2 should be arrays with the time points of the peaks
% from the platforms 1 and 2, respectively
%
% pks1 and pks2 should be arrays with the magnitude of the peaks from the
% platforms 1 and 2, respectively

	if strcmp(vector, 'vertical') & strcmp(GRF_unit, 'N')
		label = 'Vertical ground reaction force (N)';
	elseif strcmp(vector, 'vertical') & strcmp(GRF_unit, 'BW')
		label = 'Vertical ground reaction force (BW)';
	elseif strcmp(vector, 'resultant') & strcmp(GRF_unit, 'N')
		label = 'Resultant ground reaction force (N)';
	elseif strcmp(vector, 'resultant') & strcmp(GRF_unit, 'BW')
		label = 'Resultant ground reaction force (BW)';
	end

	figname = join([file, ' - ', label, ' x Time (s) - Platforms 1 and 2']);

	if strcmp(GRF_unit, 'N')
		max_GRF1 = (ceil(max(GRF1) / 500) * 500);
		GRF_ticks1 = 0:500:max_GRF1;
		max_GRF2 = (ceil(max(GRF2) / 500) * 500);
		GRF_ticks2 = 0:500:max_GRF2;
	elseif strcmp(GRF_unit, 'BW')
		max_GRF1 = ceil(max(GRF1));
		GRF_ticks1 = 0:0.5:max_GRF1;
		max_GRF2 = ceil(max(GRF2));
		GRF_ticks2 = 0:0.5:max_GRF2;
	end

	figure('NAME', figname)
	set(gcf, 'Position', get(0, 'Screensize'));

	subplot(2, 1, 1)
	plot(time, GRF1);
	grid on
	hold on
	plot(time_pks1, pks1, 'x', 'MarkerSize', 10);
	xlabel('Time (s)', 'FontSize', 20)
	ylabel(label, 'FontSize', 20)
	xticks(0:5:max(time));
	yticks(GRF_ticks1);
	xlim([0 max(time)]);
	ylim([0 max_GRF1]);
	title({file, '', 'Platform 1'}, 'Interpreter', 'none')
	ax = gca;
	ax.FontSize = 16;

	subplot(2, 1, 2)
	plot(time, GRF2);
	grid on
	hold on
	plot(time_pks2, pks2, 'x', 'MarkerSize', 10);
	xlabel('Time (s)', 'FontSize', 20)
	ylabel(label, 'FontSize', 20)
	xticks(0:5:max(time));
	yticks(GRF_ticks2);
	xlim([0 max(time)]);
	ylim([0 max_GRF2]);
	title('Platform 2')
	ax = gca;
	ax.FontSize = 16;
end