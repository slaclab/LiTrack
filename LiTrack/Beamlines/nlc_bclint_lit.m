% 'G'=gausian, 'U'=uniform, string.zd=name of file with z(mm) and dE/E(%) (see e.g. "atf1.zd"):
% ============================================================================================
%inp = 'lcls_145.zd';	% name of file with 2-columns [Z/mm dE/E/%] (sigz and sigd not used in this case)
inp = 'G';				% gaussian Z and dE/E (see sigz0 =..., sigd0 =...)
%inp = 'U';				% uniform  Z and dE/E (see sigz0 =..., sigd0 =...[note: FW = sig*sqrt(12)]

% The folowing items only used when "inp" = 'G' or 'U' (i.e. used when no particle coordinate file is read)
% ========================================================================================================
sigz0 = 5.000E-3;	% rms bunch length used when inp=G or U above [m]
sigd0 = 0.100E-2;	% rms relative energy spread used when inp=G or U above [ ]
Nesim = 100000;		% number of particles to generate for simulation when inp=G or U (reasonable: ~1000 to ~100000)
unif_halo = 1;		% 0 or 1: =1 get uniform halo population in z and E (=1: get gaussian in z-only)
halo  = 15;			% for inp='G': sets a "halo_pop"-halo at halo*sigz
halo_pop  = 0.02;	% for inp='G': sets an N%-halo at halo*sigz (e.g. 0.01 is a 1% relative population)
% ========================================================================================================

splots = 0;			% if =1, use small plots and show no wakes (for publish size plots)
plot_frac = 1.00;	% fraction of particles to plot in the delta-z scatter-plots (0 < plot_frac <= 1)
E0     = 1.98;		% initial electron energy [GeV]
Ne     = 0.765E10;	% number of particles initially in bunch
z0_bar = 0.0E-3;	% axial offset of bunch [m] (used also with file input - mean of file removed first)
d0_bar = 0.000E-2;	% relative energy offset of bunch [ ]  (used also with file input - mean of file removed first)
Nbin   = 100;		% number of bins for z-coordinate (and dE/E for plots)
gzfit   = 1;		% if ==1: fit Z-distribution to gaussian (defaults to no-fit if 'gzfit' not provided)
gdfit   = 1;		% if ==1: fit dE/E-distribution to gaussian (defaults to no-fit if 'gdfit' not provided)

% The follwing array of file names, "wake_fn", is the point-charge wakefield filename(s) to be used.  The pointer
% to the used filename appears in the 5th column (wake ON/OFF) of the 'beamline' array below.  A "zero" (i.e. 0)
% means no wake used, and a value of j (e.g. 1,2,...) directs the calculation to use the jth point-charge wakefield
% file (i.e. the jth row of "wake_fn") for that part of the beamline.

wake_fn = [' slac.dat'
           'slacx.dat'
           'SlacL.dat'];	% name of point-charge wakefield file(s) ["slac.dat" is default if filename not given]

comment = 'NLC Linear Bunch Compressor System (6/03/99)';	% text comment which appears at bottom of plots

% CODES:       |
%	       	   |	1		2		3		4		5		6
%==============|==============================================================================================
% compressor   |	code= 6           R56/m          T566/m          E_nom/GeV       U5666/m            -
% acceleration |	code=11     dEacc(phi=0)/GeV    phase/deg        lambda/m   wake(ON=1,2**/OFF=0)  Length/m
% E-spread add |	code=22          rms_dE/E           -               -               -               -
% E-window cut |	code=25         dE/E_window         -               -               -               -
% E-cut limits |	code=26          dE/E_min        dE/E_max           -               -               -
% con-N E-cut  |	code=27            dN/N             -               -               -               -
% Z-cut limits |	code=36            Z_min           Z_max            -               -               -
% con-N z-cut  |	code=37            dN/N             -               -               -               -
% STOP	       |	code=99             -               -               -               -               -
%=============================================================================================================
beamline = [
		 	-11	0.0			0.0			0.2100		0		0.0
			-11	0.1390		-101.81		0.2100		3		10.0
			 6	-0.485/2	0.485*1.5/2	1.952		-0.485	0
%            26	-0.05		0.05		0			0		0
             26	-0.1		0.1			0			0		0
			-6	-0.485/2	0.485*1.5/2	1.952		-0.485	0
			 11	6.0900		-3.000		0.1050		1		356.
            -26  -0.1       0.1         0           0       0
			 6	+0.275		0.275*1.55	8.0000		0.275*2.5	0
%           -26	-0.0125		0.0125		0			0		0
            -26	-0.1		0.1			0			0		0
			-11	0.43632		-99.25		0.0262		2		10.8
			 6	-0.061/2	0.061*1.5/2	7.940		-0.061	0
%           -26	-0.075		0.075		0			0		0
             26	-0.1		0.1			0			0		0
			-6	-0.061/2	0.061*1.5/2	7.940		-0.061	0
%			-37	0.00200		0			0			0		0
			11	537.510		-9.00		0.0262		2		9000.
%           -26	-0.02		0.02		0			0		0
             26	-0.1		0.1			0			0		0
%			-37	0.0050		0			0			0		0
			 99	0			0			0			0		0
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