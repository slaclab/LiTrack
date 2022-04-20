% 'G'=gausian, 'U'=uniform, string.zd=name of file with z(mm) and dE/E(%) (see e.g. "atf1.zd"):
% ============================================================================================
inp = 'LCLS24MAR04_6MeV.zd';	% name of file with 2-columns [Z/mm dE/E/%] (sigz0 and sigd0 below not used in this case)
sz_scale = 1;					% =-1: reverse sign of z-coordinate in input file
nsamp = 1;                      % use random subset as if "every other nsamp" point (defaults to 1 if not provided)
%inp = 'G';			            % gaussian Z (see sigz0 =..., sigd0 =...)
% NOTE: Energy spread is always Gaussian independent of above "inp"

% The folowing items only used when "inp" = 'G', 'U' or 'M' (i.e. used when no particle coordinate file is read)
% ========================================================================================================
sigz0 = 0.831E-3;		% rms bunch length used when inp=G or U above [m]
sigd0 = 0.200E-2;		% rms relative energy spread used when inp=G or U above [ ]
Nesim = 50000;			% number of particles to generate for simulation when inp=G or U (reasonable: ~1000 to ~100000)
asym  = +0.0;			% for inp='M' or 'G': asymmetry (-1<asym<1)
tail  = 0.04;			% for inp='M' or 'G': sets rise/fall time width (0<=tail<1)
cut   = 0.8;			% for inp='G': cuts the gaussian (0.5<=cut<inf)
% ========================================================================================================

Nbin   = 100;			% number of bins for z-coordinate (for wakes and dE/E for plots)
splots = 0;			    % if =1, use small plots and show no wakes (for publish size plots)
plot_frac = 0.05;		% fraction of particles to plot in the delta-z scatter-plots (0 < plot_frac <= 1)
E0     = 0.0060;		% initial electron energy [GeV]
Ne     = 0.625E10;		% number of particles initially in bunch
z0_bar = +0.000E-3;     % axial offset of bunch [m] (used also with file input - mean of file removed first)
d0_bar = +0.000E-2;		% relative energy offset of bunch [ ]  (used also with file input - mean of file removed first)
gzfit  = 0;			    % if ==1: fit Z-distribution to gaussian (defaults to no-fit if 'gzfit' not provided)
gdfit  = 0;			    % if ==1: fit dE/E-distribution to gaussian (defaults to no-fit if 'gdfit' not provided)

% The follwing array of file names, "wake_fn", is the point-charge wakefield filename(s) to be used.  The pointer
% to the used filename appears in the 5th column (wake ON/OFF) of the 'beamline' array below.  A "zero" (i.e. 0)
% means no wake used, and a value of j (e.g. 1,2,...) directs the calculation to use the jth point-charge wakefield
% file (i.e. the jth row of "wake_fn") for that part of the beamline.

wake_fn = ['slac.dat         '
           'slacx.dat        '
           'SlacL.dat        '
           'Slac_cu_rw.dat   '
           'SS_12700um_rw.dat'
           'Al_12700um_rw.dat'
           'Ni_12700um_rw.dat' ];		% name of point-charge wakefield file(s) ["slac.dat" is default if filename not given]

comment = '24MAR04, 135 MeV injector, 19 MV X-band, -160 deg X-phase';		% text comment which appears at bottom of plots

% CODES:       |
%	           |    1		     2              3	         4		       5		        6
%==============|================================================================================================
% compressor   | code= 6        R56/m        T566/m      E_nom/GeV       U5666/m            -
% chicane      | code= 7        R56/m       E_nom/GeV       -               -               -
% acceleration | code=11  dEacc(phi=0)/GeV  phase/deg    lambda/m   wake(ON=1,2**/OFF=0)  Length/m
% E-spread add | code=22       rms_dE/E         -           -               -               -
% E-window cut | code=25      dE/E_window       -           -               -               -
% E-cut limits | code=26       dE/E_min      dE/E_max       -               -               -
% con-N E-cut  | code=27         dN/N         nocut=1       -               -               -
% Z-cut limits | code=36         Z_min         Z_max        -               -               -
% con-N z-cut  | code=37         dN/N         nocut=1       -               -               -
% STOP	       | code=99          -             -           -               -               -
%===============================================================================================================

beamline = [...
 -11	0.0  	    	0.0			0.104969	0          	0.1
 -11	0.12959  	   -1.10		0.104969	1          	6.1
  22   	3.50E-4		    0		    0		    0		    0
 -6   	0.0063   	    0.140   	0.135000 	0		    0
 -11	0.14739			-25.0		0.104969	1			8.78
 -11	0.0190			-160.0		0.026242	2			0.60
 -7  	-0.03905		0.2500  	0           0           0
 -11	5.71031			-40.8		0.104969	1			329.1
  7  	-0.0247/2		4.5400		0       	0           0
  8  	 5E4			4.5400		0.1       	0.363       0
  7  	-0.0247/2		4.5400		0       	0           0
  99   	0		        0		    0		    0		    0
 -22   	0.80E-5		    0		    0		    0		    0
  11	9.9145			-13.58		0.104969	1			552.9
  11   	0.0		        0.0		    0.105		5		    76
  11   	0.0		        0.0		    0.105		6		    275
  6   	0.000133   	    0.0063		14.1		0 		    0
 -22   	1.32E-5		    0		    0		    0		    0
  27   	0.020		    1		    0		    0		    0  
 -99   	0		        0		    0		    0		    0
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
