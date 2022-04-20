	function E = rec_dechirper_wakefield(s,a,p,g,h);

%	E = rec_dechirper_wakefield(s,a,p,g,h);
%
%	Function to calculate the wakefield (Green's function) of a rectangular
% corregated pipe (dechirper) for a bunch which passing through a
% parallel plate vacuum chamber. This uses the Green's function from
% Gennady Stupakov's slides of Nov. 2, 2012.
%
%    Inputs:	s:		(vector) Axial position (s>=0) [m]
%             a:		Half gap of chamber (a>0) [m]
%             p:		Period of corrugation [m] (p << a, p>0)
%             g:    Gap between corregations [m] (g < p, g>0)
%             h:		Depth of corrugation [m] (h>0) - (was \delta in prev.
%                   papers)
%    Outputs:	E:		Green's function [V/C/m]

%===============================================================================

if any(s<0)
  error('s should be >= 0')
end
Z0 = 120*pi;
c  = 2.99792458E8;

c1 =  1.2638;  % Gennady's fit coefficients (were called a, b, d, f)
c2 =  0.3713;
c3 =  7.1126;
c4 = -0.2432;
mu = g/p;
omega_min = c/sqrt(h*a*mu);
lam0 = 2*pi*c/omega_min;  % lam0 should be << 2*pi*p for best accuracy
x = s/lam0;

F = c1*exp(-c2*x).*cos(c3*x + c4*x.^2);
E = -Z0*c/(2*pi*a^2)*F;
