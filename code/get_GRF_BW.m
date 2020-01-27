function GRF_BW = get_GRF_BW(body_mass, GRF_N)
% get_GRF_BW computes the ground reaction force in multiples of the body weight
%
% body mass should be a numerical value (interger or double)
%
% GRF_N should be an array with the ground reaction force values in Newton

	g = 9.81; % Gravity acceleration (m/s2)
	body_weight = body_mass * g; % Body weight (BW; N)

	GRF_BW = GRF_N / body_weight;
end