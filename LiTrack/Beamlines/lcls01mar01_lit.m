% 'G'=gausian, 'U'=uniform, string.zd=name of file with z(mm) and dE/E(%) (see e.g. "atf1.zd"):
% ============================================================================================
inp = 'lclscdr_10MeV.zd';		% name of file with 2-columns [Z/mm dE/E/%] (sigz0 and sigd0 below not used in this case)
nsamp = 1;                      % use random subset as if "every other nsamp" point (defaults to 1 if not provided)
%inp = 'G';			            % gaussian Z (see sigz0 =..., sigd0 =...)
%inp = 'U';			            % uniform  Z (see sigz0 =..., sigd0 =...[note: FW = sig*sqrt(12)]
%inp = 'M';			            % general Z (see sigz0 =..., sigd0 =...[note: FW = sig*sqrt(12)]
% NOTE: Energy spread is always Gaussian independent of above "inp"

% The folowing items only used when "inp" = 'G', 'U' or 'M' (i.e. used when no particle coordinate file is read)
% ========================================================================================================
sigz0 = 0.831E-3;		% rms bunch length used when inp=G or U above [m]
sigd0 = 0.200E-2;		% rms relative energy spread used when inp=G or U above [ ]
Nesim = 100000;			% number of particles to generate for simulation when inp=G or U (reasonable: ~1000 to ~100000)
asym  = +0.0;			% for inp='M' or 'G': asymmetry (-1<asym<1)
%tail  = 0.05;			% for inp='M' or 'G': sets rise/fall time width (0<=tail<1)
%cut   = 0.6;			% for inp='G': cuts the gaussian (0.5<=cut<inf)
tail  = 0.04;			% for inp='M' or 'G': sets rise/fall time width (0<=tail<1)
cut   = 0.8;			% for inp='G': cuts the gaussian (0.5<=cut<inf)
% ========================================================================================================

Nbin   = 100;			% number of bins for z-coordinate (for wakes and dE/E for plots)
splots = 1;			    % if =1, use small plots and show no wakes (for publish size plots)
plot_frac = 0.05;		% fraction of particles to plot in the delta-z scatter-plots (0 < plot_frac <= 1)
E0     = 0.0100;		% initial electron energy [GeV]
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
           'Al_12700um_rw.dat'];		% name of point-charge wakefield file(s) ["slac.dat" is default if filename not given]

comment = 'LCLS with two-undulator 0.4% FWHM chirp (01MAR01)';	% text comment which appears at bottom of plots

% CODES:       |
%	           |    1		     2              3	         4		       5		        6
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
%   11   0.140373  -1.500000   0.104969 1          6.100000
%  -6   0.010400   0.220000   0.150000 0 0
%   11   0.134503 -34.783326   0.104969 1          8.800000
%   11   0.010079 170.000000   0.026242 2          0.604591
%  -6  -0.045617   0.068426   0.249923  -0.045617*2 0
%   11   5.758326 -41.447255   0.104969 1        329.042046
%   6  -0.022632   0.033949   4.540472  -0.022632*2 0
%  -22   	0.80E-5		    0		    0		    0		    0
%   11  10.322867 -16.989858   0.104969 1        552.973407
%   11   	0.0		        0.0		    0.105		5		    76
%   11   	0.0		        0.0		    0.105		6		    106
%   6   0.000000   0.073000  14.350000 0 0
%   22   	1.32E-5		    0		    0		    0		    0
%   27   	0.020		    0		    0		    0		    0  
%  -99   	0		        0		    0		    0		    0
%
%   11   0.140373  -1.500000   0.104969 1          6.100000
%  -6   0.010400   0.220000   0.150000 0 0
%   11   0.142081 -35.639128   0.104969 1          8.800000
%   11   0.015169 170.000000   0.026242 2          0.603540
%  -6  -0.044178   0.066267   0.249911  -0.044178*2 0
%   11   5.796007 -41.859475   0.104969 1        329.074100
%   6  -0.022253   0.033379   4.540878  -0.022253*2 0
%  -22   	0.80E-5		    0		    0		    0		    0
%   11  10.327895 -17.088667   0.104969 1        552.950522
%   11   	0.0		        0.0		    0.105		5		    76
%   11   	0.0		        0.0		    0.105		6		    106
%   6   0.000000   0.073000  14.350000 0 0
%   22   	1.32E-5		    0		    0		    0		    0
%   27   	0.020		    0		    0		    0		    0  
%  -99   	0		        0		    0		    0		    0
% 
%   11   0.140373  -1.500000   0.104969 1          6.100000
%  -6   0.010400   0.220000   0.150000 0 0
%   11   0.137707 -32.244463   0.104969 1          8.800000
%   11   0.015930 170.000000   0.026242 2          0.593859
%  -6  -0.050867   0.076301   0.250164  -0.050867*2 0
%   11   5.796437 -41.861317   0.104969 1        329.114665
%   6  -0.022225   0.033337   4.541659  -0.022225*2 0
%  -22   	0.80E-5		    0		    0		    0		    0
%   11  10.325386 -17.058217   0.104969 1        552.906485
%   11   	0.0		        0.0		    0.105		5		    76
%   11   	0.0		        0.0		    0.105		6		    106
%   6   0.000000   0.073000  14.350000 0 0
%   22   	1.32E-5		    0		    0		    0		    0
%   27   	0.020		    0		    0		    0		    0  
%  -99   	0		        0		    0		    0		    0
%
%   11   0.140373  -1.500000   0.104969 1          6.100000
%  -6   0.010400   0.220000   0.150000 0 0
%   11   0.134760 -31.850390   0.104969 1          8.800000
%   11   0.013971 170.000000   0.026242 2          0.596002
%  -6  -0.051191   0.076787   0.250093  -0.051191*2 0
%   11   5.758533 -41.479055   0.104969 1        328.921629
%   6  -0.022506   0.033759   4.539071  -0.022506*2 0
%  -22   	0.80E-5		    0		    0		    0		    0
%   11  10.229510 -15.155014   0.104969 1        553.052347
%   11   	0.0		        0.0		    0.105		5		    76
%   11   	0.0		        0.0		    0.105		6		    106
%   6   0.000000   0.073000  14.350000 0 0
%   22   	1.32E-5		    0		    0		    0		    0
%   27   	0.020		    0		    0		    0		    0  
%  -99   	0		        0		    0		    0		    0
%  
   11   0.140373  -1.500000   0.104969 1          6.100000
  -6   0.010400   0.220000   0.150000 0 0
   11   0.130003 -28.295913   0.104969 1          8.800000
   11   0.013773 180.000000   0.026242 2          0.596645
  -6  -0.050899   0.076348   0.250078  -0.050899*2 0
   11   5.807592 -42.000465   0.104969 1        329.040370
   6  -0.022007   0.033011   4.540605  -0.022007*2 0
  -22   	0.80E-5		    0		    0		    0		    0
   11  10.033481 -10.286777   0.104969 1        552.965913
   11   	0.0		        0.0		    0.105		5		    76
   11   	0.0		        0.0		    0.105		6		    106
   6   0.000000   0.073000  14.350000 0 0
   22   	1.32E-5		    0		    0		    0		    0
   27   	0.020		    0		    0		    0		    0  
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
