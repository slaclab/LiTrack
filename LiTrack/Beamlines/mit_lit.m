% 'G'=gausian, 'U'=uniform, string.zd=name of file with z(mm) and dE/E(%) (see e.g. "atf1.zd"):
% ============================================================================================
%inp = 'mit_25ps_1nc_6MeV.zd';	% name of file with 2-columns [Z/mm dE/E/%] (sigz and sigd not used in this case)
%inp = 'mit_10ps_200pC_6MeV.zd';	% name of file with 2-columns [Z/mm dE/E/%] (sigz and sigd not used in this case)
inp = 'G';		% gaussian Z and dE/E (see sigz0 =..., sigd0 =...)
%inp = 'U';		% uniform  Z and dE/E (see sigz0 =..., sigd0 =...[note: FW = sig*sqrt(12)]

% The folowing items only used when "inp" = 'G' or 'U' (i.e. used when no particle coordinate file is read)
% ========================================================================================================
sigz0 = 25e-12/sqrt(12)*2.99792458E8;	% rms bunch length used when inp=G or U above [m]
sigd0 = 0.050E-2;	% rms relative energy spread used when inp=G or U above [ ]
Nesim = 50000;		% number of particles to generate for simulation when inp=G or U (reasonable: ~1000 to ~100000)
asym  = -0.0;		% for inp='M' or 'G': sets rise/fall time width (-1<asym<1)
tail  = 0.1;		% for inp='M' or 'G': sets rise/fall time width (0<=tail<1)
cut   = 1;		    % for inp='G': sets rise/fall time width (0.5<=cut<inf)
% ========================================================================================================

splots = 0;			% if =1, use small plots and show no wakes (for publish size plots)
plot_frac = 0.50;   % fraction of particles to plot in the delta-z scatter-plots (0 < plot_frac <= 1)
E0     = 0.006;	% initial electron energy [GeV]
Ne     = 1.0*6.25E9;% number of particles initially in bunch
z0_bar = 0.000E-3;	% axial offset of bunch [m] (used also with file input - mean of file removed first)
d0_bar = 0.000E-2;	% relative energy offset of bunch [ ]  (used also with file input - mean of file removed first)
Nbin   = 100;		% number of bins for z-coordinate (and dE/E for plots)
gzfit  = 0;		    % if ==1: fit Z-distribution to gaussian (defaults to no-fit if 'gzfit' not provided)
gdfit  = 0;		    % if ==1: fit dE/E-distribution to gaussian (defaults to no-fit if 'gdfit' not provided)

% The follwing array of file names, "wake_fn", is the point-charge wakefield filename(s) to be used.  The pointer
% to the used filename appears in the 5th column (wake ON/OFF) of the 'beamline' array below.  A "zero" (i.e. 0)
% means no wake used, and a value of j (e.g. 1,2,...) directs the calculation to use the jth point-charge wakefield
% file (i.e. the jth row of "wake_fn") for that part of the beamline.

wake_fn = ['slac.dat         '
           'slacx.dat        '
           'SlacL.dat        '
           'TESLA.dat        '
           'TESLA_3900.dat   '
           'SS_12700um_rw.dat'
           'Al_12700um_rw.dat'];		% name of point-charge wakefield file(s) ["slac.dat" is default if filename not given]

% CODES:       |
%	           |		1				2				3				4				5				6
%==============|==============================================================================================
% compressor   |	code= 6           R56/m          T566/m          E_nom/GeV       U5666/m            -
% chicane      |	code= 7           R56/m         E_nom/GeV           -               -               -
% acceleration |	code=10       tot-energy/GeV    phase/deg        lambda/m   wake(ON=1,2**/OFF=0)  Length/m
% acceleration |	code=11     dEacc(phi=0)/GeV    phase/deg        lambda/m   wake(ON=1,2**/OFF=0)  Length/m
% E-spread add |	code=22          rms_dE/E           -               -               -               -
% E-window cut |	code=25         dE/E_window         -               -               -               -
% E-cut limits |	code=26          dE/E_min        dE/E_max           -               -               -
% con-N E-cut  |	code=27            dN/N             -               -               -               -
% Z-cut limits |	code=36            z_min           z_max            -               -               -
% con-N z-cut  |	code=37            dN/N             -               -               -               -
% modulation   |	code=44           mod-amp        lambda/m           -               -               -
% STOP	       |	code=99             -               -               -               -               -
%=============================================================================================================
% CODE<0 makes a plot here, CODE>0 gives no plot here.

comment = 'MIT compression (Feb. 2, 2004)';	% text comment which appears at bottom of plots

%50 ps FWHM pulse 0.2 nC with 3rd and 5th harmonic RF:
%beamline = [
% -11   0		   0          0.104969	    0		   0
% -11   0.094007   0.000000   0.230610 4          8.000000
% -11   0.14150 -15.472145   0.230610 4          8.000000
% -11   0.04135  -180.000000   0.076870 5          1.030648
% -11   0.0050     5.00000   0.230610/5 5          1.030648
% -6  -0.190     1.5*0.190   0.20000  -0.190*2 0
% -11   0.456045  19.552955   0.230610 4         21.814363
% -6  -0.076      1.5*0.076   0.635368   -0.076*2 0
%  11   3.365232   0.000055   0.230610 4        170.474697
%  99   0		   0		  0		        0	       0
%];
  
%20 ps FWHM pulse 0.2 nC:
%beamline = [
% -11   0		   0          0.104969	    0		   0
% -11   0.094011   0.000000   0.230610 4          8.000000
% -11   0.136688 -19.649040   0.230610 4          8.000000
% -11   0.027800 -180.000000   0.076870 5          0.969350
% -6  -0.145586   0.218379   0.200889  -0.145586*2 0
% -11   0.655769  -0.000334   0.230610 4         32.783902
% -6  -0.066      1.5*0.066   0.856567  -0.066*2 0
%  11   3.143994  -0.001859   0.230610 4        159.267278
%  99   0		   0		  0		        0	       0
%];
                                                                    
%30 ps FWHM pulse 0.2 nC:
%beamline = [
% -11   0		   0          0.104969	    0		   0
% -11   0.094009   0.000000   0.230610 4          8.000000
% -11   0.135763 -19.709720   0.230610 4          8.000000
% -11   0.027949 -180.000000   0.076870 5          1.005432
% -6   -0.146948   0.220423   0.199849  -0.146948*2 0
% -11   0.796291   0.000091   0.230610 4         39.809306
% -6   -0.066718   0.100077   0.996035  -0.066718*2 0
%  11   3.004501   0.000034   0.230610 4        152.200888
%  99   0		   0		  0		        0	       0
%                                                                    ];

%25 ps FWHM pulse 0.2 nC:
%beamline = [
% -11   0		   0          0.104969	    0		   0
% -11   0.094010   0.000000   0.230610 4          8.000000
% -11   0.134428 -18.052637   0.230610 4          8.000000
% -11   0.027332 -180.000000   0.076870 5          0.983265
% -6  -0.162766   0.244149   0.200465  -0.162766*2 0
% -11   0.5088  20.776911   0.230610 4         23.783306
% -6  -0.074487   0.111730   0.676131  -0.074487*2 0
%  11   3.324461   0.002184   0.230610 4        168.409345
%  99   0		   0		  0		        0	       0
%                                                                ];

%10 ps FWHM pulse 0.2 nC:
%beamline = [
% -11   0		   0          0.104969	    0		   0
% -11   0.094015   0.000000   0.230610 4          8.000000
% -11   0.134417 -19.766064   0.230610 4          8.000000
% -11   0.026503 -180.000000   0.076870 5          1.003859
% -6  -0.147668   0.221502   0.199893  -0.147668*2 0
% -11   0.791444  -0.000009   0.230610 4         39.566132
% -6  -0.0770      0.077*1.5   0.991215      -0.077*2 0
%  11   3.009321   0.000045   0.230610 4        152.445088
%  99   0		   0		  0		        0	       0
%];
                                                            
%10 ps FWHM pulse 0.2 nC with non-180-deg 3.9 GHz RF phase:
%beamline = [
% -11   0		   0          0.104969	    0		   0
% -11   0.094015   0.000000   0.230610 4          8.000000
% -11   0.130444 -12.937980   0.230610 4          8.000000
% -11   0.0285 -160.000000   0.076870 5          0.996241
% -6  -0.120000   1.5*0.12000   0.200104  -0.12000*2 0
% -11   1.087871   0.000471   0.230610 4         54.384329
% -6  -0.062     1.5*0.062   1.287791  -0.062*2 0
%  11   2.712693  -0.001218   0.230610 4        137.418586
%  99   0		   0		  0		        0	       0
%];

%25 ps FWHM pulse with 1 nC (or 10 ps at 0.2 nC):
%beamline = [
% -11   0		  0          0.104969	    0		   0
% -11   0.094051   0.000000   0.230610       4          8.000000
% -11   0.138414 -22.250888   0.230610       4          8.000000
% -11   0.027913 -180.000000   0.076870      5          0.974216
% -6  -0.129616   0.194423   0.200774        -0.129616*2 0
% -11   0.814469  13.177110   0.230610       4         39.468211
% -6  -0.0820     1.5*0.082  0.990138        -0.082*2    0
%  11   3.012269  -0.000518   0.230610       4        152.499688
%  99   0		   0		  0		        0	        0
%];

%50 ps FWHM pulse with 1 nC and 3rd & 5th harmonic F:
%beamline = [
% -11   0		   0          0.104969	    0		   0
% -11   0.094007   0.000000   0.230610 4          8.000000
% -11   0.14150 -15.472145   0.230610 4          8.000000
% -11   0.04106  -180.000000   0.076870 5          1.030648
% -11   0.0050     5.00000   0.230610/5 5          1.030648
% -6  -0.190     1.5*0.190   0.20000  -0.190*2 0
% -11   0.456045  19.552955   0.230610 4         21.814363
% -6  -0.085      1.5*0.085   0.635368   -0.085*2 0
%  11   3.365232   0.000055   0.230610 4        170.474697
%  99   0		   0		  0		        0	       0
%];

%backwards acc.:
%beamline = [
%  11   0		   0          0.104969	    0		   0
%  11   -0.095211   0.000000   0.230610 0          8.000000
%  99   0		   0		  0		        0	       0
%];

%25 ps FWHM pulse with 1 nC (or 10 ps at 0.2 nC) - using Parmela dist.:
%beamline = [
% -11   0		   0          0.104969	    0		   0
% -11   0.094051   1.700000   0.230610 4          8.000000
% -11   0.1513   -32.9       0.230610 4          8.000000
% -11   0.0295   -200.000000   0.076870 5          0.974216
% -6  -0.129616   0.194423   0.200774  -0.129616*2 0
% -11   0.814469  13.177110   0.230610 4         39.468211
% -6  -0.0850     1.5*0.085  0.990138  -0.085*2 0
%  11   3.012269  -0.000518   0.230610 4        152.499688
%  99   0		   0		  0		        0	       0
%];

%25 ps FWHM pulse with 1 nC
beamline = [
 -11   0		   0          0.104969	    0		   0
 -11   0.094051   0.000000   0.230610 4          8.000000
 -11   0.128462 -13.553811   0.230610 4          8.000000
 -11   0.0248   -180.000000   0.076870 5          0.996200
 -6  -0.233886   0.350829   0.200099  -0.233886*2 0
 -11   0.741247*1.005 -11.840390   0.230610 4         36.223715
 -6   -0.0475     1.5*0.0475   0.924573  -0.0475*2 0
  11   3.077886  -0.001715   0.230610 4        155.821630
  99   0		   0		  0		        0	       0
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