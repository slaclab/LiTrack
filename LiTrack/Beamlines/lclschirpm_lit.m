% 'G'=gausian, 'U'=uniform, string.zd=name of file with z(mm) and dE/E(%) (see e.g. "atf1.zd"):
% ============================================================================================
%inp = 'lcls_145.zd';		% name of file with 2-columns [Z/mm dE/E/%] (sigz0 and sigd0 below not used in this case)
inp = 'G';			% gaussian Z (see sigz0 =..., sigd0 =...)
%inp = 'U';			% uniform  Z (see sigz0 =..., sigd0 =...[note: FW = sig*sqrt(12)]
%inp = 'M';			% general Z (see sigz0 =..., sigd0 =...[note: FW = sig*sqrt(12)]
% NOTE: Energy spread is always Gaussian independent of above "inp"

% The folowing items only used when "inp" = 'G', 'U' or 'M' (i.e. used when no particle coordinate file is read)
% ========================================================================================================
sigz0 = 0.840E-3;		% rms bunch length used when inp=G or U above [m]
sigd0 = 0.200E-2;		% rms relative energy spread used when inp=G or U above [ ]
Nesim = 50000;			% number of particles to generate for simulation when inp=G or U (reasonable: ~1000 to ~100000)
asym  = +0.0;			% for inp='M' or 'G': sets rise/fall time width (-1<asym<1)
tail  = 0.05;			% for inp='M' or 'G': sets rise/fall time width (0<=tail<1)
cut   = 0.6;			% for inp='G': sets rise/fall time width (0.5<=cut<inf)
% ========================================================================================================

Nbin   = 100;			% number of bins for z-coordinate (for wakes and dE/E for plots)
splots = 1;			% if =1, use small plots and show no wakes (for publish size plots)
plot_frac = 0.05;		% fraction of particles to plot in the delta-z scatter-plots (0 < plot_frac <= 1)
E0     = 0.010000;		% initial electron energy [GeV]
Ne     = 0.625E10*1.0;		% number of particles initially in bunch
z0_bar = +0.000E-3;		% axial offset of bunch [m] (used also with file input - mean of file removed first)
d0_bar = +0.000E-2;		% relative energy offset of bunch [ ]  (used also with file input - mean of file removed first)
gzfit  = 0;			% if ==1: fit Z-distribution to gaussian (defaults to no-fit if 'gzfit' not provided)
gdfit  = 0;			% if ==1: fit dE/E-distribution to gaussian (defaults to no-fit if 'gdfit' not provided)

% The follwing array of file names, "wake_fn", is the point-charge wakefield filename(s) to be used.  The pointer
% to the used filename appears in the 5th column (wake ON/OFF) of the 'beamline' array below.  A "zero" (i.e. 0)
% means no wake used, and a value of j (e.g. 1,2,...) directs the calculation to use the jth point-charge wakefield
% file (i.e. the jth row of "wake_fn") for that part of the beamline.

wake_fn = ['slac.dat         '
           'slacx.dat        '
           'SlacL.dat        '
           'Slac_cu_rw.dat   '
           'SS_12700um_rw.dat'
           'Al_12700um_rw.dat'];		% name of point-charge wakefield file(s) ["slac.dat" is default if filename not given]

comment = 'LCLS 0.5 nC w/chirp with asym. gun-dist.';	% text comment which appears at bottom of plots

% CODES:	|
%		|    1		    2		 3	     4		     5		     6
%===============|======================================================================================
% compressor	| code= 6        R56/m        T566/m      E_nom/GeV       U5666/m            -
% acceleration	| code=11  dEacc(phi=0)/GeV  phase/deg    lambda/m   wake(ON=1,2**/OFF=0)  Length/m
% E-spread add	| code=22       rms_dE/E         -           -               -               -
% E-window cut	| code=25      dE/E_window       -           -               -               -
% E-cut limits	| code=26       dE/E_min      dE/E_max       -               -               -
% con-N E-cut	| code=27         dN/N           -           -               -               -
% Z-cut limits	| code=36         Z_min         Z_max        -               -               -
% con-N z-cut	| code=37         dN/N           -           -               -               -
% STOP		| code=99          -             -           -               -               -
%======================================================================================================
beamline = [
  11   0.140372  -1.500000   0.105000 1          6.100000
  6   0.010400   0.220000   0.150000   0.0	 0
  11   0.159450 -40.377710   0.105000 1          8.807000
  11   0.020694 -180.000000   0.026250 2          0.495645
 -6  -0.038678   0.058017   0.250183  -0.038678*2 0
  11   5.988258 -43.825901   0.105000 1        331.949274
 -6  -0.0370   0.0555   4.538236  -0.0370*2 0
  11  10.177941  14.022781   0.105000 1        555.999967
  6   0.000900   0.061000  14.350000   0.0 	0
  22	1.32E-5	0		0	0		0
 -27	0.020	0		0	0		0
  99	0	0		0	0		0
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
%     on the most dense region (i.e. maximum number of particles).
% **  1:=1st wake file (e.g. S-band) is used, 2:=2nd wake file (e.g. X-band)
