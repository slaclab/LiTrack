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
asym  = +0.0;			% for inp='M' or 'G': asymmetry (-1<asym<1)
tail  = 0.05;			% for inp='M' or 'G': sets rise/fall time width (0<=tail<1)
cut   = 0.6;			% for inp='G': cuts the gaussian (0.5<=cut<inf)
% ========================================================================================================

Nbin   = 100;			% number of bins for z-coordinate (for wakes and dE/E for plots)
splots = 0;			% if =1, use small plots and show no wakes (for publish size plots)
plot_frac = 0.02;		% fraction of particles to plot in the delta-z scatter-plots (0 < plot_frac <= 1)
E0     = 0.010000;		% initial electron energy [GeV]
Ne     = 0.625E10;		% number of particles initially in bunch
z0_bar = +0*0.299792458E-3;	% axial offset of bunch [m] (used also with file input - mean of file removed first)
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

comment = 'X-band at 20 MV';	% text comment which appears at bottom of plots

% CODES:       |
%	       |    1		    2           3	    4		    5		    6
%==============|================================================================================================
% compressor   | code= 6        R56/m        T566/m      E_nom/GeV       U5666/m            -
% acceleration | code=11  dEacc(phi=0)/GeV  phase/deg    lambda/m   wake(ON=1,2**/OFF=0)  Length/m
% E-spread add | code=22       rms_dE/E         -           -               -               -
% E-window cut | code=25      dE/E_window       -           -               -               -
% E-cut limits | code=26       dE/E_min      dE/E_max       -               -               -
% con-N E-cut  | code=27         dN/N           -           -               -               -
% Z-cut limits | code=36         Z_min         Z_max        -               -               -
% con-N z-cut  | code=37         dN/N           -           -               -               -
% STOP	       | code=99          -             -           -               -               -
%===============================================================================================================
beamline = [...
% 		11   0		0		0.1050		0	0
% 		11   0.1406  	-1.500000   	0.105000 	1	6.1
% 		 6   0.010400   0.220000   	0.150000   	0.0	0
% 		11   0.1533 	-38.00   	0.105000 	1	8.807
% 		11   0.0203 	-180.0   	0.026250 	2	0.5
% 		 6  -0.036660   0.054990   	0.250	-0.036660*2 	0
% 		11   5.8941 	-42.90		0.105000	1	332.1
% 		 6  -0.02216   	0.02216*1.5	4.540	-0.02216*2	0
% 		22   0.83E-5	0		0		0	0
% 		11   10.0325	-10.0		0.105000	1	555.9
% 		11   0.0	0.0		0.105		5	70
% 		11   0.0	0.0		0.105		6	100
% 		 6   0.0009	0.0610		14.350   	0.0 	0
% 		22   1.32E-5	0		0		0	0
%
% 11   0.140361  -1.500000   0.105000 1          6.100000
% 6   0.010400   0.220000   0.150000   0.010400*0 0
% 11   0.153802 -38.449332   0.105000 1          8.807000
% 11   0.019717 -180.000000   0.026250 2          0.495993
% 6  -0.036277   0.054416   0.250160  -0.036277*2 0
% 11   5.889712 -42.874039   0.105000 1        332.035802
% 6  -0.022181   0.033272   4.539331  -0.022181*2 0
% 		22   0.83E-5	0		0		0	0
% 11   10.02412  -10.0   0.105000 1        555.937910
% 6   0.000900   0.061000  14.350000   0.000900*0 0
%
% 11   0.140361  -1.500000   0.105000 1          6.100000
% 6   0.010400   0.220000   0.150000   0.010400*0 0
% 11   0.149023 -37.358237   0.105000 1          8.807000
% 11   0.017720 -180.000000   0.026250 2          0.495631
% 6  -0.038393   0.057589   0.250157  -0.038393*0 0
% 11   5.878111 -42.733755   0.105000 1        332.139680
% 6  -0.022416   0.033624   4.540670  -0.022416*0 0
% 11   9.921702  -5.823987   0.105000 1        555.862040
% 6   0.000900   0.061000  14.350000   0.000900*0 0
%
% 11   0.140361  -1.500000   0.105000 1          6.100000
% 6   0.010400   0.220000   0.150000   0.010400*0 0
% 11   0.149031 -36.076507   0.105000 1          8.807000
% 11   0.020032 -180.000000   0.026250 2          0.503929
% 6  -0.039560   0.059341   0.249843  -0.039560*0 0
% 11   5.944955 -41.128030   0.105000 1        332.171987
% 6  -0.023884   0.035826   4.700807  -0.023884*0 0
% 11   9.842094  -9.385270   0.105000 1        555.853487
% 6   0.000900   0.061000  14.350000   0.000900*0 0
%
% 11   0.140361  -1.500000   0.105000 1          6.100000
% 6   0.010400   0.220000   0.150000   0.010400*0 0
% 11   0.135132 -26.954955   0.105000 1          8.807000
% 11   0.016596 -180.000000   0.026250 2          0.417488
% -6  -0.061120   0.091680   0.253300  -0.061120*2 0
% 11   6.764920 -43.046325   0.105000 1        380.262101
% -6  -0.024101   0.036152   5.165449  -0.024101*2 0
% 11   9.38439  -10.0   0.105000 1        520.457910
% 6   0.000900   0.061000  14.350000   0.000900*0 0
%
% 11   0.140366  -1.500000   0.105000 1          6.100000
% 6   0.010400   0.220000   0.150000   0.010400*0 0
% 11   0.155073 -39.032019   0.105000 1          8.807000
% 11   0.019717 -180.000000   0.026250 2          0.495996
% 6  -0.035540   0.053311   0.250160  -0.035540*2 0
% 11   5.899083 -42.965517   0.105000 1        332.034537
% 6  -0.022205   0.033307   4.539315  -0.022205*2 0
% 22   0.83E-5	0		0		0	0
% 11   9.998997  -9.108888   0.105000 1        555.938843
% 11   0.0	0.0		0.105		5	70
% 11   0.0	0.0		0.105		6	100
% 6   0.000900   0.061000  14.350000   0.000900*0 0
%
 11   0.1406  	-1.500000   	0.105000 	1	6.1
  6   0.010400   0.220000   	0.150000   	0.0	0
 11   0.1538 	-38.208646   	0.105000 	1	8.807
 11   0.0203 	-180.0   	0.026250 	2	0.78
  -6  -0.036660   0.054990   	0.250	-0.036660*2 	0
 11   5.8923 	-42.90		0.105000	1	332.1
  6  -0.0222   	0.0222*1.5	4.540	-0.0222*2	0
 -22   0.83E-5	0		0		0	0
 11   10.0318	-10.0		0.105000	1	555.9
 6   0.000900   0.061000  14.350000   0.000900*0 0
%
 22   1.32E-5	0		0		0	0
 27   0.020	0		0		0	0
 99   0		0		0		0	0
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
