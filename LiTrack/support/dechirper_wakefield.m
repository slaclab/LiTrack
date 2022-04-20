	function E = dechirper_wakefield(s,r,p,g,d);

%	E = dechirper_wakefield(s,r,p,g,d);
%
%	Function to calculate the wakefield (Green's function) of a corregated
%	pipe (dechirper) for a bunch which is short or long compared to the
% characteristic length for a cylindrical or parallel plate vacuum chamber.
% Uses the Green's function from Karl Bane's April 2012 Dechirper paper
% (SLAC-PUB-14925).
%
%    Inputs:	s:		(vector) Axial position (s>=0) [m]
%             r:		Radius of beam chamber (r>0) [m]
%             p:		Period of corrugation [m] (p << r, p>0)
%             g:    Gap between corregations [m] (g>0)
%             d:		Depth of corrugation [m] (d << r, d >~ p, d>0)
%    Outputs:	E:		Green's function [V/C/m]

%===============================================================================

if any(s<0)
  error('s should be >= 0')
end
Z0 = 120*pi;
c  = 2.99792458E8;
k = sqrt(2*p/(r*d*g));
kappa = Z0*c/(2*pi*r^2);

E = -2*kappa*cos(k*s);