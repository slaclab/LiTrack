% 'G'=gausian, 'U'=uniform, string.zd=name of file with z(mm) and dE/E(%) (see e.g. "atf1.zd"):
% ============================================================================================
%inp = 'lcls_145.zd';	% name of file with 2-columns [Z/mm dE/E/%] (sigz and sigd not used in this case)
inp = 'G';			% gaussian Z and dE/E (see sigz0 =..., sigd0 =...)
%inp = 'U';			% uniform  Z and dE/E (see sigz0 =..., sigd0 =...[note: FW = sig*sqrt(12)]

% The folowing items only used when "inp" = 'G' or 'U' (i.e. used when no particle coordinate file is read)
% ========================================================================================================
sigz0 = 9.000E-3;		% rms bunch length used when inp=G or U above [m]
sigd0 = 0.100E-2;		% rms relative energy spread used when inp=G or U above [ ]
Nesim = 10000;		% number of particles to generate for simulation when inp=G or U (reasonable: ~1000 to ~100000)
% ========================================================================================================
E0     = 3.900000;	% initial electron energy [GeV]
Ne     = 2.0000E10;	% number of particles initially in bunch
z0_bar = 0.000E-3;	% axial offset of bunch [m] (used also with file input - mean of file removed first)
d0_bar = 0.000E-2;	% relative energy offset of bunch [ ]  (used also with file input - mean of file removed first)
Nbin   = 100;		% number of bins for z-coordinate (and dE/E for plots)
gzfit  = 1;				% add a gaussian fit to the Z-ditribution
gdfit  = 1;				% add a gaussian fit to the dE/E-distribution

comment = 'TESLA comp. wiggler-compressor';	% text comment which appears at bottom of plots

% CODES:        |
%               |    1             2            3           4            5            6
%===============|================================================================================
% compressor    | code= 6        R56/m        T566/m    E_nom/GeV        -            -
% acceleration  | code=11  dEacc(phi=0)/GeV  phase/deg  lambda/m  wake(ON=1/OFF=0)  Length/m
% E-spread add  | code=22      rms_dE/E         -           -            -            -
% E-window cut* | code=25     dE/E_window       -           -            -            -
% E-cut limits  | code=26      dE/E_min      dE/E_max       -            -            -
% z-cut limits  | code=36       z_min/m       z_max/m       -            -            -
% STOP	    | code=99          -            -           -            -            -
%================================================================================================
beamline =      [...
                     11        0.4120     -107.3000	   0.23000         1         16.48
		          6       -0.362         0.362*1.5   3.7779	       0          0
                     11      248.0000       -4.000	   0.23000         1         10000.
		         36	      -0.0025        0.0025      0		       0          0
		         99        0             0           0		       0          0
		         26	      -0.090         0.090       0		       0          0
		         25	       0.0024        0           0		       0          0
                   																							];
                
% Sign conventions used:
% =====================
%
% phase = 0 is beam on accelerating peak of RF (crest)
% phase < 0 is beam ahead of crest (i.e. bunch-head sees lower RF voltage than tail)
% The bunch head is at smaller values of z than the tail (i.e. head toward z<0)
% With these conventions, the R56 of a chicane is < 0 (and R56>0 for a FODO-arc) - note T566>0 for both
% 
% * = Note, the Energy-window cut (25-code) floats the center of the given FW window in order center it
%     on the most dense region (i.e. maximum number of particles)