function adjustedTime = plotSlider(fig, plotGrf)
% PLOTSLIDER lets the user adjust the ground reaction force signal in relation
% to the acceleration signal through a GUI.
%
% Input arguments:
% 	fig: a figure object which contains the acceleration and ground reaction
% 	force plots.
% 	plotGrf: a line plot of the ground reaction force signal.
%
% Output arguments:
% 	ajustedTime: a datetime array with the ground reaction force data initial
% 	timestamp after adjustment.

	figPos = get(fig, 'Position');
	figLeft = figPos(1);
	figWidth = figPos(3);

	sldrWidth = 100;
	sldrHeight = 20;
	sldrLeft = figLeft + figWidth / 2 - sldrWidth / 2;
	sldrBottom = 20;

	value = 0;

	uicontrol(fig, 'Style', 'slider', ...
		  'Position', [sldrLeft, sldrBottom, sldrWidth, sldrHeight], ...
		  'Min', - 60, 'Max', 60, 'Value', value,...
		  'Callback', {@sliderCallback})

	bttnWidth = 100;
	bttnHeight = 20;
	bttnLeft = figWidth - 4 * bttnWidth;
	bttnBottom = 20;

	uicontrol(fig, 'Style', 'pushbutton', ...
		  'String', 'Continue', ...
		  'Position', [bttnLeft, bttnBottom, bttnWidth, bttnHeight], ...
		  'Callback', 'uiresume(gcbf)')

	uiwait

	adjustedTime = min(get(plotGrf, 'Xdata'));

	function sliderCallback(hObj, ~)
		value = round(get(hObj, 'Value') - value);
		set(hObj, 'Value', value)

		xData = get(plotGrf, 'Xdata');
		adjust = seconds(value);
		set(plotGrf, 'Xdata', xData + adjust)
	end
end
