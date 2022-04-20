	function [dE_E,dE_E_mean,dE_E_std] = csr_wakefield(s,sig_s,dsn,f,L,theta,E0,N);

%	[dE_E,dE_E_mean,dE_E_std] = csr_wakefield(s,sig_s,dsn,f,L,theta,E0,N);
%
%	Function to calculate the steady-state CSR-induced wakefield over an electron
% bunch passing through a bend magnet of length L and angle theta with N
%	electrons in the bunch and E0 energy per electron.
%
%    Inputs:	s:      (vector) Axial position (head at s > 0) [m]
%             sig_s:  (scalar) RMS bunch length [m]
%             dsn:    (scalar) Integration step size in rms bunch length units [ ]
%           	f:      (vector) Normalized distribution function [1/m]
%             L:      (scalar) Length of bend magnet [m]
%             theta:  (scalar) Bend angle of magnet [rad]
%             E0:     (scalar) Electron energy [eV]
%             N:      (scalar) Number of electron per bunch [ ]
%
%    Outputs:	dE_E:       (vector) Relative energy variation along bunch [ ]
%             dE_E_mean:  (scalar) Relative mean energy loss per e- (loss is dE/E < 0)
%             dE_E_std:   (scalar) Relative rms energy loss per e- (wrt mean)

%===============================================================================

Z0  = 120*pi;
c   = 2.99792458E8;
re  = 2.82E-15;
mc2 = 511E3;

f     = fliplr(f);  % head at z < 0
n     = length(s);
ds    = dsn*sig_s;  % step size in meters
df_ds = diff(f);
df_ds = [df_ds df_ds(end)];

for j = 1:n
  i = 1:(j-1);
  I = df_ds(i)./(s(j)-s(i)).^(1/3);
  F(j) = sum(I);
  dE_E(j) = -2*N*re*L^(1/3)*theta^(2/3)*mc2*F(j)/(3^(1/3)*E0);
end
dE_E = fliplr(dE_E);  % head at z < 0

dE_E_mean = 0; % integrate(s,f.*dE_E);
dE_E_var  = 0; % integrate(s,f.*dE_E.^2);
dE_E_std  = 0; % sqrt(dE_E_var - dE_E_mean^2);
