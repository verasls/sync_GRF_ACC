function adjustedTime = plotSlider(fig, plotGrf)
	% Create slider
	figPos = get(fig, 'Position');
	figL = figPos(1);
	figB = figPos(2);
	figW = figPos(3);
	figH = figPos(4);

	sldrWidth = 100;
	sldrHeight = 20;
	sldrLeft = figL + figW / 2 - sldrWidth / 2;
	sldrBottom = 20;

	value = 0;
	originalTime = min(get(plotGrf, 'Xdata'));

	uicontrol(fig, 'Style', 'slider', ...
		  'Position', [sldrLeft, sldrBottom, sldrWidth, sldrHeight], ...
		  'Min', - 60, 'Max', 60, 'Value', value,...
		  'Callback', {@sliderCallback})

	bttnWidth = 100;
	bttnHeight = 20;
	bttnLeft = figW - 4 * bttnWidth;
	bttnBottom = 20;

	uicontrol(fig, 'Style', 'pushbutton', ...
		  'String', 'Continue', ...
		  'Position', [bttnLeft, bttnBottom, bttnWidth, bttnHeight], ...
		  'Callback', 'uiresume(gcbf)')

	uiwait

	adjustedTime = min(get(plotGrf, 'Xdata'));

	function sliderCallback(hObj, event)
		value = round(get(hObj, 'Value') - value);
		set(hObj, 'Value', value)

		xData = get(plot_grf, 'Xdata');
		adjust = seconds(value);
		set(plotGrf, 'Xdata', xData + adjust)
	end
end


