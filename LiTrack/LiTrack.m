function [zposj,dE_Ej,Ebarj,dFWpctj,ZFWmmj,z_barj,Ebarcutsj,fcutj,sigzGj,sigEGj,I_pkj,I_pkfj] = litrack_for_gui(fn,seed,z0in,dQ_Q,param,blnew,inp_struc,wake_fn)

%	[zposj,dE_Ej,Ebarj,dFWpctj,ZFWmmj,z_barj,Ebarcutsj,fcutj,sigzGj,sigEGj] = litrack_for_gui(fn[,seed,z0in,dQ_Q,param,blnew,inp_struc,wake_fn]);
%
%	TRY IT....  just type:   LiTrack('lcls0')
%
%	Function to do 2-D longitudinal phase space tracking of many
%	electrons through several accelerator sections including bunch
%	compression and the longitudinal wakefield of the accelerating
% structures.
%
%	The beam and the various sections are described in your M-file
%	called "*_lit.m" where "*" is a string contained in the above
%	input argument: fn.
%
% The initial zpos and dE/E particle coordinates can be 'LiTrack'-
%	generated Matlab gaussian distributions, uniform distributions, or
%	they can be input from a user's ASCII, 2-column file (Z/mm, dE/E/%).
%
%	If no output arguments are provided, this function generates plots
%	(see below).  If at least one output argument is provided, no plots
%	are generated and the longitudinal coordinates of the N particles
%	are returned as described below.
%
%  INPUTS:
%     fn:         A string which describes the leading characters of the beam-
%                 line M-file with name "*_lit.m" where the fn string is represented
%                 here as "*" (SEE FOR EXAMPLE the file LCLS_LIT.M which is
%                 internall documented and would be run by setting fn='lcls').
%     seed:       (Optional,DEF=1) The random generator seed used.  If argument
%                 not given the seed defaults to 1 for repeatability.
%     z0in:       (Optional,DEF=0) Initial 'phase' offset of bunch [mm].
%     dQ_Q:       (Optional,DEF=0) Relative charge error (e.g. 0.01 -> 1% more charge)
%     param:      (Optional,DEF=none) A 3-element vector of, param(1): the value of
%                 the parameter to be scanned, param(2) the row number of the 'beamline'
%                 array, and param(3) the column number of the 'beamline' array to be
%                 replaced by param(1) - use 'scan_litrack_param.m'.
%     blnew:      (Optional,DEF=none) A full beamline to replace the 'beamline' array
%                 in the *_lit.m file, so that the parameters can be randomized as
%                 is done in 'rand_litrack.m'.
%     inp_struc:  (Optional,DEF=none) Input structure to run LiTrack from a GUI, where
%                 all input parameters come from the GUI data structure, rather than
%                 from an LiTrack file such as 'spps0_lit.m'. No other input arguments
%                 are used when this structure is given (e.g., set them all = 0).
%     wake_fn:    ASCII list of wakefield file names where one get pointed to in
%                 beamline array.
%
%  OUTPUTS:       (all below evaluated at each location where cod < 0 | cod == 99)
%     zposj:	    The matrix of axial coordinates (after cuts) within
%                 the bunch [in meters - head at z<0] w.r.t. the bunch center.  If
%                 no output arguments are provided, the function will simply
%                 generate a plot of 1) Z-distr., 2) dE/E-distr., 3) Wake-induced
%                 voltage (only if the beamline described in fn ends on a linac
%                 section with the wakefields switched on), and 4) dE/E versus Z
%                 scatter plot.
%     dE_Ej:	    The matrix of dE/E coordinates (after cuts, w.r.t. the mean energy)
%                 as a unitless value (i.e. 0.01 corresponds to 1%).
%     Ebarj:	    The array of mean electron energies BEFORE ANY CUTS [GeV]
%     dFWpctj:    dE/E spread array, full-width at half-maximum [%]
%     ZFWmmj:     Z full-width array at half-maximum [mm]
%     z_barj:     Mean longitudinal bunch position array AFTER CUTS [mm]
%     Ebarcutsj:	The mean electron energy array AFTER ALL CUTS [GeV]
%     fcutj:      The fraction of particles that were cut out [ ]
%     sigzGj:     Gaussian fitted rms bunch length array [mm]
%     sigEGj:     Gaussian fitted rms relative energy spread array [%]
%     I_pkj:      Peak current anywhere in bunch [kA]
%     I_pkfj:     Peak current from maximum of a Gaussian fit [kA]

%==============================================================================================================



fontsize = 14;

% Add needed subfolders
root_folder = fileparts(mfilename('fullpath'));
addpath(genpath(root_folder))

if exist('inp_struc')				% if run from the LiTrack GUI, all input from this structure, not from file or other input arguments
  [beamline,inp,Ne,E0,sigz0,sigd0,Nesim,z0_bar,d0_bar,asym,Nbin,sz_scale,nsamp,gzfit,gdfit,plot_frac,splots,comment,contf,LSCon,LSCsize,LSCfilter] = ...
				LiTrack_struc2params(inp_struc);		% convert LiTrack GUI input data structure to nominal LiTrack parameters
  fnfm = 'GUI';
else
  start_time = get_time;
  disp(' ')
  disp(['LiTrack started:' start_time])
  disp(' ')
  if ~exist('fn')           % if beamline-file name not input... ask for it
    fn = input('LITRACK input file descriptor (*_lit.m assumed): ','s');
  end
  if ~exist('sz_scale')     % z scalar defaults to 1
    sz_scale = 1;
  end
  fnf  = [fn '_lit'];				% build string as file name of beamline-file (BL_file)
  fnfm = [fnf '.m'];				% build string as file name of beamline-file (BL_file) including ".m"
  if ~exist(fnf)                	% if file does not exist, bomb out
    error(['File: ' fnfm ' does not exist'])
  end
  Ne = 0;                   % must initialize "Ne" before "eval" to make vs. 7.0.1 work (Nov. 2, 2004)
  eval(fnf);                % run BL-file which is just an M-file (*.m)
  if exist('blnew')					% if a replacement beamline is being used...
    beamline = blnew;				% overwrite the just-read-in beamline with this (see rand_litrack.m)
  end
  if ~exist('gzfit')				% default to no gaussian fits for Z-distribution
    gzfit = 0;
  end
  if ~exist('gdfit')				% default to no gaussian fits for dE/E distribution
    gdfit = 0;
  end
  if ~exist('contf')				% default to scatter plot, rather than color z-d image
    contf = 0;
  end
  if ~exist('asym')					% default to no dist. asymmetry
    asym = 0;
  end
  if ~exist('plot_frac')		% default to 2% of particles plotted in delta-z scatter plots
    plot_frac = 0.02;
  else
    if plot_frac > 1 || plot_frac <= 0
      error('PLOT_FRAC must be > 0 and <= 1...  quitting.')
    end
  end
  if ~exist('wake_fn')			% default to SLAC.DAT point-charge S-band wakefield file
     wake_fn = 'slac.dat';
  end
  if ~exist('splots')
    splots = 0;             % default to big plots (splots=1 gives publish-size plots and no wake plots)
  end
  if ~exist('nsamp')				% default to using all input file points
    nsamp = 1;
  end
  if ~exist('LSCon','var')
      LSCon = 0;
  end
  if ~exist('LSCsize','var')
      LSCsize = 40e-6;
  end
  if ~exist('LSCfilter','var')
      LSCfilter = 0.05;
  end
  
end

if ~exist('unif_halo')
  unif_halo = 0;					% set =1 if you want uniform z and E halo (Aug. 5, 2002 - PE)
end
if ~exist('seed')					% random seed used (defaults to 1)
  seed = 1;
end
if ~exist('tail')					% default to no dist. tail
  tail = 0;
end
if ~exist('cut')					% default to no dist. cuts
  cut = 10;
end
if ~exist('halo')					% default to no dist. 1%-halo
  halo = 0;
  halo_pop = 0;           % halo relative population defaults to zero  
end
if exist('param')
  if param == 0
    noparam = 1;
  else
    if length(param) ~= 3
      error('param must have 3 elements in order to scan a parameter - quitting.')
    end
    noparam = 0;
  end
else
  noparam = 1;
end
if exist('z0in')
  z0_bar = z0_bar + z0in*1E-3;	% add LiTrack input 'phase' offset
end
if exist('dQ_Q')
  if abs(dQ_Q) > 0.8
    error('dQ_Q is > 80%, this seems unreasonable - quitting.')
  end
  Ne1 = Ne*(1+dQ_Q);		% add LiTrack input 'charge' error
else
  Ne1 = Ne;
end
if splots == 1
  nn  = 3;					    % number of plot columns (3 for publish-size plots)
  pz  = 3;
else
  nn  = 2;					    % number of plot columns (2 for big display-only plots)
  pz  = 4;  
end


elec   = 1.6022E-9;				    % Coulombs/(1E10 e-)
cspeed = 2.99792458E8;				% light speed [m/sec]
jf     = 0;                   % start with figure window-1
jc     = 0;                   % start with zero output locations (where cod < 0 | cod == 99)

if inp == 'G'                 % if the BL-file specifies a gaussian...
  inpf = 'gaussian random';   % text to put on plots
  randn('seed',seed);         % set the gaussian random generator seed
  d0 = sigd0*randn(Nesim,1) + d0_bar;	% always gaussian dE/E
  if unif_halo==0
    z0 = asym_gaussian(Nesim,sigz0,z0_bar,...
                       asym,cut,tail,halo,halo_pop);	% generate asymmetric gaussian with cuts & tails
  else
    z0 = asym_gaussian(Nesim,sigz0,z0_bar,...
                       asym,cut,tail,0,0);	% generate asymmetric gaussian with cuts & tails
    zh = 2*halo*sigz0*(rand(Nesim*halo_pop,1)-0.5);
    dh = 2*halo*sigd0*(rand(Nesim*halo_pop,1)-0.5);
    i  = 1:round(1/halo_pop):Nesim;
    z0(i) = zh;
    d0(i) = dh;
  end
elseif inp == 'U'                 % if the BL-file specifies a uniform (rectangular) dist....
  inpf = 'uniform random';				% text to put on plots
  zwid = sqrt(12)*sigz0;			    % interpret "sigz0" as rms (=>full width = sqrt(12)*rms)
  dwid = sqrt(12)*sigd0;			    % interpret "sigd0" as rms (=>full width = sqrt(12)*rms)
  rand('seed',seed);              % set the uniform random generator seed
  z0   = zwid*(rand(Nesim,1)-0.5) + z0_bar;	% generate uniform distribution + offset for Z [m]
  d0   = dwid*(rand(Nesim,1)-0.5) + d0_bar;	% generate uniform distribution + offset for dE/E [ ]
elseif inp == 'P'                 % if the BL-file specifies a parabolic dist....
  inpf = 'parabolic';             % text to put on plots
  rand('seed',seed);              % set the uniform random generator seed
  z0   = parabolic_dist(Nesim,sigz0) + z0_bar;	% generate parabolic distribution + offset for Z [m]
  d0   = parabolic_dist(Nesim,sigd0) + d0_bar;	% generate parabolic distribution + offset for dE/E [ ]
elseif inp == 'M'                 % if the BL-file specifies a generalized (multiple gaussians) dist....
  inpf = 'generalized random';		% text to put on plots
  randn('seed',seed);             % set the gaussian random generator seed
  z0 = gen_dist(Nesim,tail,sigz0,z0_bar,asym);	% generate general distribution + offset for Z [m]
  d0 = sigd0*randn(Nesim,1) + d0_bar;	% always gaussian dE/E
else                              % if BL-file specifies the Z & dE/E are to be taken from another file (ZD-file)...
  inpf = inp;                     % text for plots
  if ~exist(inp)                  % if ZD-file dose not exists, bomb out
    error(['Z, dE/E input file ' inp ' does not exist'])
  else                            % if ZD-file does exist...
    cmnd = ['load ' inp];			    % build string to load ZD-file
    disp(' ')
    disp(['Loading z,dE/E-distribution input file: ' inp ' ...'])
    eval(cmnd);                   % load the ZD-file (ASCII flat format with 2 columns: Z/mm & dE/E/%)
  end
  i = find(inp=='.');             % ZD-file name format checking (need >0 characters leading the '.')
  if i < 2
    error(['Z, dE/E input file ' inp ' file name needs to be of the form *.*, with >0 characters leading the "."'])
  end
  zd0 = inp(1:(i(1)-1));			    % make a string variable with string = name of data file
  cmnd = ['[Nesim,col] = size(' zd0 ');'];	% find size of input data matrix
  eval(cmnd);                     % ...
  if col < 2                  		% bomb out if <2 columns (need both Z and dE/E) in ZD-file
    error(['Z, dE/E input file ' inp ' requires at least 2 columns which are Z/mm in 1st and dE/E/% in 2nd'])
  end
  if Nesim < 2                    % bomb out if <2 rows (particles) in ZD-file
    error(['Z, dE/E input file ' inp ' requires at least 2 rows for Z/mm and dE/E/% of particles'])
  end
  if nsamp >= 1                         % if we want a random subset of the input file coordinates
    irand = randperm(Nesim);            % random permutation of integers from 1 to Nesim (to select random set of file points)
    irand = irand(1:nsamp:Nesim);       % now take subset of permutations
    cmnd = [zd0 '=' zd0 '(irand,:);'];	% take only every other "nsamp" point from the full array
    eval(cmnd);                         % ...
    cmnd = ['[Nesim,col]=size(' zd0 ');'];	% find new size of input data matrix
    eval(cmnd);                         % ...
    if col < 2                          % bomb out if <2 columns (need both Z and dE/E) in ZD-file
      error(['Z, dE/E input file ' inp ' requires at least 2 columns which are Z/mm in 1st and dE/E/% in 2nd'])
    end
    if Nesim < 2                        % bomb out if <2 rows (particles) in ZD-file
      error(['Z, dE/E input file ' inp ' requires at least 2*nsamp rows for Z/mm and dE/E/% of particles'])
    end
  end
  cmnd = ['z0 = 1E-3*' zd0 '(:,1);'];   % extract the Z-coordinates [m] from the matrix from the file
  eval(cmnd);                           % ...
  cmnd = ['d0 = 1E-2*' zd0 '(:,2);'];   % extract the dE/E-coordinates [m] from the matrix from the file
  eval(cmnd);                           % ...
  sigz0 = std(z0);                      % calculate the rms bunch length [m]
  sigd0 = std(d0);                      % calculate the rms relative energy spread [ ]
  z0    = sz_scale*(z0 - mean(z0));	    % remove mean from ZD-file's z-distribution [m] and scale sigZ (you can put non-zero mean in BL-file)
  d0    = sz_scale*(d0 - mean(d0));     % remove mean from ZD-file's dE/E distribution [ ] and scale sigE/E (you can put non-zero mean in BL-file)
  disp(' ')
  disp('INFO: removing mean from file''s original z and dE/E-distributions before proceeding...')	% warn of this action
  disp(' ')
  z0 = z0 + z0_bar;				% add a potential Z-offset which is input from the BL-file [m]
  d0 = d0 + d0_bar;				% add a potential dE/E-offset which is input from the BL-file [ ]
end

if Nbin < 10              % bomb out if BL-file specifies <10 for Z and dE/E binning
  error(sprintf('Nbin = %g cannot be less than 10',Nbin))
end

% Start doing real calculations:
% ==============================

[nb,ncol] = size(beamline);		    % nb=number of beamline sections in BL-file (e.g. accelerator, compressor, ...)
if ncol ~= 6					            % BL-file needs 6 columns otherwise it's not right
  error(['"beamline" array in input file ' fnfm '.m requires at 6 columns'])
end
if nb < 1					                % need at least one beamline section (even a 99 to indicate the dump)
  error(['"beamline" array in input file ' fnfm '.m requires at least 1 row'])
end

if noparam==0
  beamline(param(2),param(3)) = param(1);	% used to scan a parameter using 'scan_litrack_param.m'
end

Ne0    = Ne1;           % save N electrons to get fraction lost
Nesim0 = Nesim;					% save N macro-particles to get fraction lost
iswake = 0;					    % default until a wake is calculated (=0 turns off wake-induced voltage plot)
ecuts  = 0;					    % default to no dE/E cuts shown on plots
zcuts  = 0;					    % default to no Z cuts shown on plots
z      = z0;            % axial position within bunch w.r.t. mean position [m]
d      = d0;      			% relative energy deviation w.r.t. mean energy [ ]
E      = E0*(1 + d0);		% absolute energy of particles [GeV]
Ebar   = mean(E);				% mean particle energy [GeV]
Ebarcuts = mean(E);			% mean particle energy after later cuts [GeV]
z_bar  = 1E3*mean(z);		% mean z-position [mm]
sigz   = sigz0;      		% rms bunch length (w.r.t. mean) [m]
sigd   = sigd0;      		% rms relative energy spread [ ]
for j  = 1:nb           % loop over all beamline sections of BL-file
  cod  = beamline(j,1);	% beamline section code (e.g. 11=accelerator section - from K. Bane convention)

  if (abs(cod)==1)			% do-nothing code (e.g., used to plot input beam)
%	do nothing - plot only if cod=-1 (see below)
  end
  
  if (abs(cod)==2)			% dump z,dE/E ASCII file
    fnout = 'LiTrack_zd_output.dat';
    dump_LiTrack_output(1E3*z,100*d,fnout);
    disp(['2-column ASCII output file written: [z(mm) dE/E(%)]: ' fnout])
  end
  
  if (abs(cod)==11)	|| (abs(cod)==10)	% ACCELERATION SECTION (11 and 10)
    ecuts = 0;                % no dE/E cuts shown on plots
    zcuts = 0;                % no Z cuts shown on plots
    Eacc   = beamline(j,2);		% nominal acc (w/o wake and for phi=crest(=0)) [GeV]
    phi    = beamline(j,3);		% acc phase (crest=0, low-E head at phi < 0) [deg]
    lam    = beamline(j,4);		% RF wavelength [m]
    if lam<=0
      error('RF wavelength cannot be <= 0')
    end
    wakeon = beamline(j,5);		% wakeON=1,2, wakeOFF=0
    Lacc   = beamline(j,6);		% length of acc section (scales wake) [m]
    phir   = phi*pi/180;      % RF phase in radians
    if wakeon                 % if wakes calc switched ON...
      iswake = 1;             % turns wake plot on
      nwake_fn = length(wake_fn(:,1));		        % count number of files provided
      if wakeon > nwake_fn
        error('Need multiple wake function file names when "wakeON/OFF" > 1')
      end
      wake_fn1 = wake_fn(wakeon,:);			        % select proper wake function depending on wakeon (=1,2,...)
      disp(['Using wake function: ' wake_fn1])		% echo wake file being used
      [dE_wake,zc_wake] = long_wake(z,Lacc,Ne1,...
                          Nbin,wake_fn1);	        % calculate dE_wake in MeV from Z-coordinates, acc length, N-particles, etc.
      dE_wakes = interp1(zc_wake,dE_wake,z,'*linear');	% inerpolate between wake calc points in bunch to evaluate dE for each e-
      dE_loss = 1E-3*mean(dE_wakes);	% wake loss [GeV]
    else                    			% if wake calc switched OFF...
      iswake = 0;                 % no wake plot
      dE_wake = zeros(Nbin,1); 		% dE_wake is all zeros
      dE_loss = 0;                % wake loss = 0 without wakes ON
    end
    if abs(cod) == 10             % special case where Eacc is final energy, rather than acc-Voltage
      Eacc = -dE_loss + (Eacc - mean(E))/cos(phir);	% Eacc was final energy, now is acc-volts again [GeV]
    end
    Erf = E + Eacc*cos(phir + 2*pi*z/lam);	% energy of each particle from RF shape alone (no wake yet)
    if LSCon
        E0 = mean(E);
        E1 = mean(Erf);
        NLSC = 10;
        Eref = linspace(E0,E1,NLSC+1);
        disp(['zmax = ',num2str(max(z))])
        t = z/3e8;
        t = t - mean(t);
        Q = Ne1*1.6e-19;
        disp(['Q = ',num2str(Q)])
        dp = zeros(size(E));
        for mm = 1:NLSC
            pavg = (Eref(mm)+Eref(mm+1))/2*1000/0.511;
            dp = dp + LSC_liTrack(t,pavg,Q,Nbin,LSCsize,Lacc/NLSC,LSCfilter);
        end
        Erf = Erf + dp*0.511/1000;
    end
    
    if wakeon
      E = Erf + dE_wakes*1E-3;		% energy from RF phase and wake added [GeV]
    else
      E = Erf;                % energy from RF phase and NO wake added [GeV]
    end
    
    Ebar = mean(E);				    % mean particle energy [GeV]
    Ebarcuts = Ebar;          % mean energy after cuts - same as Ebar here [GeV]
    d     = (E - Ebar)/Ebar;	% relative energy deviation w.r.t. mean energy [ ]
  end
  
  if abs(cod) == 12           % zero-out all energy deviations for diagnostics ONLY
    d = zeros(size(d));
    E = mean(E)*ones(size(E));
  end
  
  if abs(cod) == 13           % energy feedback with two phase-opposed sections, each of eV0 volts @ crest
    ecuts = 0;                % no dE/E cuts shown on plots
    zcuts = 0;                % no Z cuts shown on plots
    Efin   = beamline(j,2);		% Energy setpoint (goal) [GeV]
    eV0    = beamline(j,3);		% acc. voltage available at crest for each of two fdbk sections [GeV]
    if eV0==0
      error('Feedback voltage of zero will not correct energy')
    end
    phi1r  = beamline(j,4)*pi/180;  % acc phase of 1st section (crest=0, low-E head at phi < 0) [deg]
    phi2r  = beamline(j,5)*pi/180;	% acc phase of 2nd section (crest=0, low-E head at phi < 0) [deg]
    lam    = beamline(j,6);         % RF wavelength [m]
    if lam<=0
      error('RF wavelength cannot be <= 0')
    end
    iswake  = 0;				    	% no wake plot
    options = optimset;
    dphi    = fminsearch('fdbk_fun',0,options,phi1r,phi2r,(Efin-mean(E))/eV0);
    disp(sprintf('Energy feedback phase set to %8.3f deg',dphi*180/pi))
    En      = mean(E) + eV0*cos(phi1r+dphi) + eV0*cos(phi2r-dphi);
    if abs(En-Efin)/Efin > 1E-4
      disp(sprintf('Energy feedback phase maxed out at %8.3f deg',dphi*180/pi))
    end
    E = E  + eV0*cos(phi1r+dphi+2*pi*z/lam) + eV0*cos(phi2r-dphi+2*pi*z/lam);
    Ebar = mean(E);             % mean particle energy [GeV]
    Ebarcuts = Ebar;            % mean energy after cuts - same as Ebar here [GeV]
    d     = (E - Ebar)/Ebar;	% relative energy deviation w.r.t. mean energy [ ]
  end                           % end code==13, energy feedback card
  
  if abs(cod)==15               % resistive-wall wakefield (15)
    r0   = beamline(j,2);		% Beam-pipe radius [m]
    Lng  = beamline(j,3);		% Beam-pipe length [m]
    sigc = beamline(j,4);		% Surface conductivity [(Ohm-m)^-1]
	tau  = beamline(j,5);		% relaxation time (sec) - if =zero, use DC wake
	rf   = beamline(j,6);		% rf=1: cylindrical chamber,  rf=2: parallel plates chamber
    if r0<=0
      error('Resistive-wall wake cannot be calculated for negative or zero radius')
    end
    if sigc<=0
      error('Resistive-wall wake cannot be calculated for negative or zero conductivity')
    end
    if tau<0
      error('Resistive-wall wake cannot be calculated for negative relaxation time')
    end
    if rf<0 || rf>2
      error('Last paremeter in resistive-wall wake must be 1 or 2, for cylindrical or rectangular chambers')
    end
    iswake = 1;				% turns wake plot on
	  Z0 = 120*pi;			% free-space impedance [Ohm]
	  s0 = (2*r0^2/(Z0*sigc))^(1/3);
	  zmax = 2.01*(max(z) - min(z));
    zpc = 0:(zmax/1000):zmax;
    if tau==0
  	  pcwakeW = rw_wakefield(zpc,r0,s0);        % DC-wake
	  else
  	  pcwakeW = rw_wakefield(zpc,r0,s0,tau,rf);	% AC-wake
    end
	  pcwake = [zpc(:) -pcwakeW(:)];
    [dE_wake,zc_wake] = long_wake(z,Lng,Ne1,...
								  Nbin,0,pcwake);	        % calculate dE_wake in MeV from Z-coordinates, acc length, N-particles, etc.
    dE_wakes = interp1(zc_wake,dE_wake,z,'*linear');		% inerpolate between wake calc points in bunch to evaluate dE for each e-
    
    if LSCon
        E0 = mean(E);
        E1 = mean(E);
        NLSC = 1;
        Eref = linspace(E0,E1,NLSC+1);
        disp(['zmax = ',num2str(max(z))])
        t = z/3e8;
        t = t - mean(t);
        Q = Ne1*1.6e-19;
        disp(['Q = ',num2str(Q)])
        dp = zeros(size(E));
        for mm = 1:NLSC
            pavg = (Eref(mm)+Eref(mm+1))/2*1000/0.511;
            dp = dp + LSC_liTrack(t,pavg,Q,Nbin,LSCsize,Lng/NLSC,LSCfilter);
        end
        dE_LSC = dp*0.511/1000;
    else
        dE_LSC = E*0;
    end
    
    E = E + dE_wakes*1E-3 + dE_LSC;      % energy from RF phase and wake added [GeV]
    Ebar = mean(E);             % mean particle energy [GeV]
    Ebarcuts = Ebar;            % mean energy after cuts - same as Ebar here [GeV]
    d     = (E - Ebar)/Ebar;		% relative energy deviation w.r.t. mean energy [ ]
  end

  if abs(cod)==16               % de-chirper longitudinal wakefield (16)
    r0   = beamline(j,2);		% Pipe radius [m]
    Lng  = beamline(j,3);		% Pipe length [m]
%   p    = beamline(j,4);		% period of corrugation (m) (p << r0)
%	g    = beamline(j,5);		% gap between corregations (m)
    p_g  = beamline(j,4);		% period/gap of corrugation ( ) (0 < p/g < 2)
%	d    = beamline(j,6);		% depth of corrugation (m) (d << r0, d >~ p)
	d    = beamline(j,5);		% depth of corrugation (m) (d << r0)
    rc   = beamline(j,6);		% rc=0: cylindrical chamber,  rc=1: rectangular chamber
    if r0<=0
      error('De-chirper wake cannot be calculated for negative or zero radius')
    end
%    if p<=0
%      error('De-chirper wake cannot be calculated for negative or zero corregation period')
%    end
%    if g<=0
%      error('De-chirper wake cannot be calculated for negative or zero corregation gap')
%    end
    if p_g<=1
      error('period/gap cannot be less than or equal to 1')
    end
    if d<=0
      error('De-chirper wake cannot be calculated for negative or zero corregation depth')
    end
%    if p>=r0/2
%      warning('Corregation period should be < radius/2')
%    end
%    if d<p/2
%      warning('Corregation depth should be > period/2')
%    end
    if rc~=0 && rc~=1
      error('Last paremeter in dechirper wake must be 0 or 1, for rectangular or cylindrical chambers')
    end
    iswake = 1;				% turns wake plot on
	zmax = 2.01*(max(z) - min(z));
    zpc = 0:(zmax/1000):zmax;
    p = 1E-3;                                               % p is taken as 1 mm [p/g is all that matters]
    g = p/(p_g);                                            % g is then as p*(g/p)
    if rc == 0
  	  pcwakeW = dechirper_wakefield(zpc,r0,p,g,d);          % cylindrical dechirper-wake
    else
  	  pcwakeW = rec_dechirper_wakefield(zpc,r0,p,g,d);      % rectangular dechirper-wake
    end
	pcwake = [zpc(:) -pcwakeW(:)];
    [dE_wake,zc_wake] = long_wake(z,Lng,Ne1,...
								  Nbin,0,pcwake);	        % calculate dE_wake in MeV from Z-coordinates, acc length, N-particles, etc.
    dE_wakes = interp1(zc_wake,dE_wake,z,'*linear');		% inerpolate between wake calc points in bunch to evaluate dE for each e-
    E = E + dE_wakes*1E-3;        % energy from RF phase and wake added [GeV]
    Ebar = mean(E);               % mean particle energy [GeV]
    Ebarcuts = Ebar;              % mean energy after cuts - same as Ebar here [GeV]
    d     = (E - Ebar)/Ebar;      % relative energy deviation w.r.t. mean energy [ ]
  end

  if abs(cod)==17           % CSR (17)
    L    = beamline(j,2);		% Bend magnet length [m]
    theta= beamline(j,3);		% Bend magnet angle [rad]
    Nbends = beamline(j,4);	% Number of bend magnets [ ]
    if L<0
      error('CSR bend cannot be calculated for negative length')
    end
    iswake = 1;                           % turns wake plot on
    [f,zc_wake] = hist(z,Nbin-2);         % bin z-data to get temporal dist.
    dZc = mean(diff(zc_wake));            % bin size
    zc_wake = [zc_wake(1)-dZc zc_wake zc_wake(Nbin-2)+dZc];	% so particles in end bins get interpolated
    f = [0 f 0];                          % ...properly
    f = f/integrate(zc_wake,f);           % f(z) must be normalized
    [dE_wake,dE_mean,dE_std] = csr_wakefield(zc_wake,sigz,1/Nbin,f,L,theta,E0*1E9,Ne1);  % dE/E(z) of CSR-wake
    dE_wake = Nbends*dE_wake*E0*1E3;      % scale by N-bends and convert to MV
    dE_wakes = interp1(zc_wake,dE_wake,z,'*linear');		% inerpolate between wake calc points in bunch to evaluate dE for each e-
    E = E + dE_wakes*1E-3;                % energy from RF phase and wake added [GeV]
    Ebar = mean(E);                       % mean particle energy [GeV]
    Ebarcuts = Ebar;                      % mean energy after cuts - same as Ebar here [GeV]
    d    = (E - Ebar)/Ebar;               % relative energy deviation w.r.t. mean energy [ ]
  end
  
  if abs(cod) == 18
      Ld = beamline(j,2);
      E2 = beamline(j,3);
      Ns = beamline(j,4);
      rb = beamline(j,5);
      ref_length = beamline(j,6);
      E1 = mean(E);
      Eref = linspace(E1,E2,Ns+1);
      t = z/cspeed;
      t = t - mean(t);
      dp = zeros(size(E));
      Nbin = 300;
      for mm = 1:Ns
          pavg = (Eref(mm)+Eref(mm+1))/2*1000/0.511;
          Q = Ne1*elec*1e-10;
          dp = dp + LSC_liTrack2(t,pavg,Q,Nbin,rb,Ld/Ns,ref_length);
      end
      E = E + dp*0.511/1000;
      zc_wake = z;
      dE_wake = dp*0.511;
      [zc_wake,II] = sort(zc_wake,'ascend');
      dE_wake = dE_wake(II);
      Ebar = mean(E);
      d = (E - Ebar)/Ebar;
  end
  
  if abs(cod) == 26           % USER'S ENERGY CUTS (26) - doesn't change Ebar
    ecuts = 1;                % show dE/E cuts on plots
    d1 = beamline(j,2);				% minimum dE/E to allow through [ ]
    d2 = beamline(j,3);				% maximum dE/E "   "     "      [ ]
    if d1 >= d2               % bomb out if max<min (BT-file error)
      error(['Energy cuts (26) must have dE/E_min (col 2) < dE/E_max (col3) in ' fnfm])
    end
    i = find(d>d1 & d<d2);		% bomb out if cuts too tight
    if length(i) < 1
      error(sprintf('Energy cuts (26) Emin=%7.4f %% and Emax=%7.4f %% threw out all particles',d1*100,d2*100))
    end
    Ni = length(i);				% count particles left after cuts
    Ne1 = Ne1*Ni/Nesim;   % rescale N-particles to reflect cuts
    d = d(i);					    % reduce dE/E array inpose cuts
    z = z(i);					    % reduce Z array inpose cuts
    E = E(i);					    % reduce energy array inpose cuts
    Ebarcuts = mean(E);		% mean energy after cuts [GeV]
    disp([sprintf('E-cut (26): %6.3e',100*(1-Ni/Nesim)) '% of bunch'])  
    Nesim = Ni;					  % reduce number of simulation particles
  end
  
  if abs(cod) == 28         % Notch collimator for M. Hogan
%    ecuts = 1;             % show dE/E cuts on plots
    d1 = beamline(j,2);     % minimum dE/E for notch-collimator edge [ ]
    d2 = beamline(j,3);     % maximum dE/E for notch-collimator edge [ ]
    if d1 >= d2             % bomb out if max<min (BT-file error)
      error(['Notch-collimator (28) must have dE/E_min (col 2) < dE/E_max (col3) in ' fnfm])
    end
    i = find(d<d1 | d>d2);  % bomb out if notch too wide
    if length(i) < 1
      error(sprintf('Notch-collimator (28) Emin=%7.4f %% and Emax=%7.4f %% threw out all particles',d1*100,d2*100))
    end
    Ni = length(i);				  % count particles left after cuts
    Ne1 = Ne1*Ni/Nesim;     % rescale N-particles to reflect cuts
    d = d(i);               % reduce dE/E array inpose cuts
    z = z(i);               % reduce Z array inpose cuts
    E = E(i);               % reduce energy array inpose cuts
    Ebarcuts = mean(E);			% mean energy after cuts [GeV]
    disp([sprintf('Notch-collimator (28) cut: %6.3e',100*(1-Ni/Nesim)) '% of bunch'])  
    Nesim = Ni;					    % reduce number of simulation particles
  end
  
  if abs(cod) == 29         % USER'S ABSOLUTE ENERGY CUTS (29)
    ecuts = 1;					    % show dE/E cuts on plots
    E1 = beamline(j,2);			% minimum E to allow through [GeV]
    E2 = beamline(j,3);			% maximum E "   "     "      [GeV]
	d1 = E1/Ebar - 1;
	d2 = E2/Ebar - 1;
    if E1 >= E2					    % bomb out if max<min (BT-file error)
      error(['Absolute energy cuts (29) must have E_min (col 2) < E_max (col 3) in ' fnfm])
    end
    i = find(E>E1 & E<E2);	% bomb out if cuts too tight
    if length(i) < 1
      error(sprintf('Absolute energy cuts (29) Emin=%7.4f GeV and Emax=%7.4f GeV threw out all particles',E1,E2))
    end
    Ni = length(i);				  % count particles left after cuts
    Ne1 = Ne1*Ni/Nesim;			% rescale N-particles to reflect cuts
    d = d(i);               % reduce dE/E array inpose cuts
    z = z(i);               % reduce Z array inpose cuts
    E = E(i);               % reduce energy array inpose cuts
    Ebarcuts = mean(E);			% mean energy after cuts [GeV]
    Ebar = mean(E);					% mean energy after cuts [GeV]
    disp([sprintf('E-cut (29): %6.3e',100*(1-Ni/Nesim)) '% of bunch'])  
    Nesim = Ni;					    % reduce number of simulation particles
  end
  
  if abs(cod) == 25				  % AUTO-APERTURTE ENERGY WINDOW CUTS (25) - doesn't change Ebar
    ecuts = 1;					    % show dE/E cuts on plots
    iswake = 0;					    % turn off induced voltage plot
    dw = beamline(j,2);			% energy width to allow (max and min set to maximize transmission) [ ]
    dspan = max(d) - min(d);  		% get full span of dE/E
    if dw >= dspan/2				% if E-window is >= 1/2 of full dE/E span...
      Nbin0 = 1;				    % 1-bin needed
    else                    % if E-window < 1/2 of full dE/E span...
      Nbin0 = round(dspan/dw);		% bin dE/E initially (>1)
    end
    Nbin0_max = 250;				% reasonable lower limit on 25-code E-width (dE/E full span/Nbin0_max)
    if Nbin0 > Nbin0_max		% limit N-bins to reasonable scale
      disp(sprintf(['Auto aperture (25) of Ewid=%7.4f%% is just too narrow in ' fnfm],dw*100))
      fprintf('...estimate %7.4f%% at minimum acceptable for this beam\n',100*dspan/Nbin0_max)
      error('QUITIING')
    end
    if Nbin0 > 1                    % if E-window is < 1/2 dE/E full span...
      [Nd0,D0] = hist(d,Nbin0);     % bin all dE/E to find rough location of max density
      [Nd0max,iNd0max] = max(Nd0);	% find max bin as rough location of most dense population
      dD0 = mean(diff(D0));         % dE/E bin size [ ]
      d10 = D0(iNd0max) - dD0;      % rough minimum dE/E of beam core with dw width
      d20 = D0(iNd0max) + dD0;      % rough maximum dE/E of beam core with dw width
      icore = find(d>d10 & d<d20);	% pointers to core particles
      [Nd,D] = hist(d(icore),Nbin);	% re-bin only core dE/E to find more precise integration limits (d1 and d1+dw)
    else
      [Nd,D] = hist(d,Nbin);        % re-bin all dE/E to find more precise integration limits (d1 and d1+dw)
    end
    dD = mean(diff(D));             % dE/E bin size [ ]
    nj = min([round(dw/dD) Nbin]);	% number of bins which approx. add up to the dw width wanted (max allowed = Nbin)
    if nj < 2                       % bomb if window to narrow
      error(sprintf(['Auto aperture (25) of Ewid=%7.4f%% is too narrow in ' fnfm],dw*100))
    end
    A = zeros(Nbin-nj+1,1);         % initialize area array
    for jj = 1:(Nbin-nj+1)
      A(jj) = sum(Nd(jj:(jj+nj-1)));% find transmission for each possible integration 1st-limit (const width)
    end
    [Amax,iAmax] = max(A);		% find set of bins with most beam
    if iAmax == Nbin-nj+1			% if most beam is near the high energy edge of dE/E distribution...
      derr = 0;               % bias window 1/2-bin low so that the high-E dense are is not cut off
    elseif iAmax == 1         % if most beam is near the low energy edge of dE/E distribution...
      derr = dD;              % bias window 1/2-bin high so that the low-E dense are is not cut off
    else                      % if dense portion of beam is not near edge...
      derr = dD/2;				    % no window bias (1/2-bin shift is necessary for accuracy)
    end 
    d1 = D(iAmax) - derr;			% find first integration limit (low energy cut) for max transmission
    d2 = d1 + dw;             % find high energy cut
    i = find(d>d1 & d<d2);    % bomb if window too tight...
    if length(i) < 2
      error(sprintf('Auto aperture (25), Ewid=%7.4f%% sets Emin=%7.4f%%, Emax=%7.4f%% and throws out all particles',dw*100,d1*100,d2*100))
    end
    Ni = length(i);				    % count particles left after cuts
    Ne1 = Ne1*Ni/Nesim;				% rescale N-particles to reflect cuts
    d = d(i);                 % reduce dE/E array inpose cuts
    z = z(i);                 % reduce Z array inpose cuts
    E = E(i);                 % reduce energy array inpose cuts
    Ebarcuts = mean(E);				% mean energy after cuts [GeV]
    disp([sprintf('E-window-cut (25): %6.3f',100*(1-Ni/Nesim)) '% of bunch'])  
    Nesim = Ni;               % reduce number of simulation particles
  end
  
  if abs(cod) == 27                     % USER'S constant-dN/N dE/E cuts (27)
%    zcuts = 1;                         % show dE/E-cuts on plots
    dN_N = beamline(j,2);               % fraction of max-dE/E-amplitude particles to cut [ ]
    no_charge_loss = beamline(j,3);			% if==1, no real charge cut intended, just better binning
    [dsort,idsort] = sort(abs(d-mean(d)));	% sort the absolute value of dE/E values (min to max)
    N1 = round(Nesim*dN_N);			        % throw out last N1 particles
    z(idsort((Nesim-N1):Nesim)) = [];		% now throw them out of zpos
    d(idsort((Nesim-N1):Nesim)) = [];		% now throw them out of dE/E
    E(idsort((Nesim-N1):Nesim)) = [];		% now throw them out of E
    Ni = length(z);                     % count particles left after cuts
    if no_charge_loss==0                % if real charge cut intended...
      Ne1 = Ne1*Ni/Nesim;				        % ...rescale N-particles to reflect cuts
    end
    Ebarcuts = mean(E);                 % mean energy after cuts [GeV]
    disp([sprintf('Const-dN/N dE/E-cut (27): %6.3f',100*(1-Ni/Nesim)) '% of bunch'])  
    Nesim = Ni;                         % reduce number of simulation particles
  end
  
  if abs(cod) == 35				    		% narrow in on small z-width
    zw1 = beamline(j,2);			    % the full width in z to find peak current in [mm]
    zw2 = beamline(j,3);			    % the full width in z to find peak current in [mm]
	zbar = mean(z);                 % z mean [mm]
    dz = z - zbar;                % subtract z mean [mm]
	i  = find(abs(dz)<zw1/2);				% find all particles in this width around the mean
    [Nz,Z] = hist(dz(i),Nbin);		% bin dz in this narrow window to fine peak in current
	[mx,ix] = max(Nz);              % find maximum current in this window
	i  = find(abs(dz-Z(ix))<zw2/2);	% find all particles in this width around the mean
    Ni = length(i);				    		% count particles left after cuts
    Ne1 = Ne1*Ni/Nesim;						% rescale N-particles to reflect cuts
    d = d(i);                     % reduce dE/E array inpose cuts
    z = z(i);                     % reduce Z array inpose cuts
    E = E(i);                     % reduce energy array inpose cuts
    Ebarcuts = mean(E);						% mean energy after cuts [GeV]
    disp([sprintf('z-window-cut (35): %6.3f',100*(1-Ni/Nesim)) '% of bunch'])  
    Nesim = Ni;                   % reduce number of simulation particles
  end
  
  if abs(cod) == 36               % USER'S Z-CUTS (36)
    zcuts = 1;					          % show Z-cuts on plots
    z1 = beamline(j,2);				    % minimum Z to allow through [m]
    z2 = beamline(j,3);				    % maximum Z "   "     "      [m]
    if z1 >= z2					          % bomb out if max<min (BT-file error)
      error(['Z-cuts (36) must have Z_min (col 2) < Z_max (col3) in ' fnfm])
    end
    i = find(z>z1 & z<z2);				% bomb out if cuts too tight
    if length(i) < 1
      error(sprintf('Z-cuts (36) Zmin=%7.4f mm and Zmax=%7.4f mm threw out all particles',z1*1E3,z2*1E3))
    end
    Ni = length(i);               % count particles left after cuts
    Ne1 = Ne1*Ni/Nesim;						% rescale N-particles to reflect cuts
    d = d(i);                     % reduce dE/E array inpose cuts
    z = z(i);                     % reduce Z array inpose cuts
    E = E(i);                     % reduce energy array inpose cuts
    Ebarcuts = mean(E);						% mean energy after cuts [GeV]
    disp([sprintf('Z-cut (36): %6.3f',100*(1-Ni/Nesim)) '% of bunch'])  
    Nesim = Ni;                   % reduce number of simulation particles
  end
  
  if abs(cod) == 37                   % USER'S constant-dN/N z cuts (37)
%    zcuts = 1;                       % show Z-cuts on plots
    dN_N = beamline(j,2);			        % fraction of max-z-amplitude particles to cut [ ]
    no_charge_loss = beamline(j,3);		% if==1, no real charge cut intended, just better binning
    [zsort,izsort] = sort(abs(z-mean(z)));	% sort the absolute value of zpos values (min to max)
    N1 = round(Nesim*dN_N);           % throw out last N1 particles
    z(izsort((Nesim-N1):Nesim)) = [];	% now throw them out of zpos
    d(izsort((Nesim-N1):Nesim)) = [];	% now throw them out of dE/E
    E(izsort((Nesim-N1):Nesim)) = [];	% now throw them out of E
    Ni = length(z);				            % count particles left after cuts
    if no_charge_loss==0              % if real charge cut intended...
      Ne1 = Ne1*Ni/Nesim;				      % ...rescale N-particles to reflect cuts
    end
    Ebarcuts = mean(E);				        % mean energy after cuts [GeV]
    disp([sprintf('Const-dN/N Z-cut (37): %6.3f',100*(1-Ni/Nesim)) '% of bunch'])
    Nesim = Ni;                       % reduce number of simulation particles
  end
  
  if abs(cod) == 44             % add a temporal modulation
    mod_amp = beamline(j,2);    % modulation rel. amplitude (typically 0.02 - 0.05)
    mod_lam = beamline(j,3);    % modulation wavelength [m]
    z = z + mod_amp*mod_lam/2/pi*cos(2*pi*z/mod_lam);
    sigz = std(z);              % re-calc bunch length for next possible pass through wake calculations
  end
  
  if abs(cod) == 45             % add an energy modulation
    mod_amp = beamline(j,2);    % energy modulation relative amplitude (e.g., 0.001 for 0.1%) [ ]
    mod_lam = beamline(j,3);    % energy modulation wavelength [m]
    E = E.*(1 + mod_amp*sin(2*pi*z/mod_lam));	% modulate energy
    Ebar = mean(E);             % mean particle energy [GeV]
    Ebarcuts = Ebar;            % mean energy after cuts - same as Ebar here [GeV]
    d     = (E - Ebar)/Ebar;    % relative energy deviation w.r.t. mean energy [ ]
  end
  
  if abs(cod) == 6              % BUNCH COMPRESSION (R56/m, T566/m, E/GeV, U5666/m)
    ecuts = 0;                  % no dE/E cuts shown on plots
    zcuts = 0;                  % no Z cuts shown on plots
    iswake = 0;                 % turn off induced voltage plot
    R56  = beamline(j,2);       % R56 value [m]
    T566 = beamline(j,3);       % T566 value [m] (=-3*R56/2 for non-quad system)
    U5666= beamline(j,5);       % U5666 value [m] (=2*R56 for non-quad system)
    E56  = beamline(j,4);       % Nominal energy of compressor [GeV]
    if E56 < 0.020              % need positive, reasonable nominal R56-energy [GeV]
      disp(sprintf(['WARN: Compressor section (6) of R56=%7.4f m has nominal-energy too small (not ultra-relativistic) in ' fnfm],R56))
    end
    dd   = (E-E56)/E56;         % relative energy error w.r.t. nominal compressor energy
    z    = R56*dd + T566*dd.^2 + ...
           U5666*dd.^3 + z;     % compress or anti-compress bunch [m]
    sigz = std(z);              % re-calc bunch length for next possible pass through wake calculations
  end
  
  if abs(cod) == 7              % BUNCH COMPRESSION CHICANE (R56/m, E/GeV [T566=-1.5*R56, U5666=2*R56])
    ecuts    = 0;               % no dE/E cuts shown on plots
    zcuts    = 0;               % no Z cuts shown on plots
    iswake   = 0;               % turn off induced voltage plot
    R56      = beamline(j,2);   % R56 value [m]
    dR56_R56 = beamline(j,4);   % relative R56 jitter 
    eps      = dR56_R56;            
    if R56>0
      error('R56 for chicane is always <0...  quitting')
    end
    if dR56_R56>0
      disp('Switched-on jitter on R56 in chicane')
    end
    T566 = -1.5*R56;            % T566 value [m]
    U5666=  2.0*R56;            % U5666 value [m]
    E56  = beamline(j,3);       % Nominal energy of compressor [GeV]
    if E56 < 0.020              % need positive, reasonable nominal R56-energy [GeV]
      error(sprintf(['Chicane section (7) of R56=%7.4f m has nominal-energy too small (not ultra-relativistic) in ' fnfm],R56))
    end
    mean(E)
    dd   = (E-E56)/E56;         % relative energy error w.r.t. nominal compressor energy
    z    = R56*(1-eps)*dd + T566*(1-eps)*dd.^2 + ...    % modified by P. Craievich 02/05/06 (relative R56 jitter)
           U5666*(1-eps)*dd.^3 + z ...
           + eps*R56/2;         % compress or anti-compress bunch [m] 
    sigz = std(z);              % re-calc bunch length for next possible pass through wake calculations
  end
  
  if abs(cod) == 8              % octupole ?
	disp('WARN: Octupole element is not reliable yet...')
    ecuts = 0;                  % no dE/E cuts shown on plots
    zcuts = 0;                  % no Z cuts shown on plots
    iswake = 0;                 % turn off induced voltage plot
    K3   = beamline(j,2);       % octupole MAD k-value [m^-4]
    Enom = beamline(j,3);       % Nominal energy in octupole [GeV]
    Leff = beamline(j,4);       % effective magnetic length of octupole [m]
    eta  = beamline(j,5);       % dispersion in octupole [m]
    U5666 = K3*Leff*eta^4/6;
	dd   = (E-Enom)/Enom;         % relative energy error w.r.t. nominal compressor energy
    z    = U5666*dd.^3 + z;     % distort bunch as per octupole, assuming in chicane center [m]
  end
  
  if abs(cod) == 22             % INCOHERENT ENERGY SPREAD ADDITION
    ecuts  = 0;                 % no dE/E cuts shown on plots
    zcuts  = 0;                 % no Z cuts shown on plots
    iswake = 0;                 % turn off induced voltage plot
    id_rms = beamline(j,2);     % rms incoherent relative energy spread to be added in quadrature [ ]
	  d = d + id_rms*randn(length(d),1);	% incread dE/E by the incoherent addition [ ]
    E = Ebar*(1 + d);           % load energy array [GeV]
  end
  ii = find(z);
  z_bar = 1E3*mean(z(ii));      % mean z-pos AFTER CUTS [mm]

  if cod < 0 || cod == 99       % plot after each negative code point in beamline
    if nargout < 1
      zmm  = z*1E3;             % convert to [mm]
      dpct = d*100;             % convert to [%]
      sigzmm  = std(zmm);       % rms [mm]
      sigdpct = std(dpct);      % rms [%]
      jf = jf + 1;              % count plots to make separate figure windows
      fh = figure(jf);          % open new figure window
      set(gcf,'windowstyle','docked','color','w');
      clf;                      % clear figure
      fprintf('New figure %2.0f created\n',jf)
     
      subplot(2,nn,pz)
      [Nz1,Z] = hist(zmm,Nbin);       % bin the Z-distribution
      ZFWmm = fwhm(Z,Nz1,0.5);        % calc. Z-FWHM [mm]
      dZ = mean(diff(Z));             % Z bin size [mm]
      I  = Nz1*(Ne1/1E10/Nesim)*elec*cspeed/dZ;	% convert N to peak current [kA]
	  I_pk = max(I);
      nZ = length(Z);
      Z  = [Z(1)-dZ Z(:)' Z(nZ)+dZ];	% add charge=0 end-points to distribution
      I = [0 I(:)' 0];                %  "    "        "        "    "
      stairs(Z,I,'b-');               % plot in kAmps vs. mm
      if sigzmm < 0.1                 % switch to microns if sigz_rms < 0.1 mm
        zscl = 1E3;
        zunt = ' \mum';
      else
        zscl = 1;
        zunt = ' mm';
      end
	  if sigzmm < 0.0005
        zscl = 1E6;
        zunt = ' nm';
	  end
	  if splots==0
        ttl = ['{\it\sigma_z}=' sprintf('%5.3f',sigzmm*zscl) zunt ' (fwhm=' sprintf('%5.3f',ZFWmm*zscl)];
      else
        ttl = ['{\it\sigma_z}=' sprintf('%5.3f',sigzmm*zscl) zunt ' '];
      end
      if gzfit
        hold on
        [yf,q,dq] = gauss_fit(Z,I,1E-3*ones(size(I)),1);
        sigzG  = q(4);				% gaussian fit sigma_Z [mm]
        plot(Z,yf,'r:')
%        if splots==0
          ttl = [ttl ', fit=' sprintf('%5.3f',sigzG*zscl)];
%        end
      end
      if splots==0
        ttl = [ttl ')'];
      end
      zmin = min(zmm);
      zmax = max(zmm);
      zwf  = (zmax-zmin)/20;
      Imax = max(I);
      if zcuts
        axis([z1*1E3-zwf z2*1E3+zwf 0 Imax*1.05])
        ver_line(z1*1E3)
        ver_line(z2*1E3)
      else
        axis([zmin-zwf zmax+zwf 0 Imax*1.05])
      end
      axis([zmin-zwf zmax+zwf 0 Imax*1.05])
      xlabel('{\itz} /mm')
      Hy=ylabel('{\itI} /kA');
      set(Hy,'VerticalAlignment','baseline');
      if splots==0
        H = text(zmin+(zmax-zmin+2*zwf)*0.54,Imax*0.97,['{\itI_{pk}}=' sprintf('%5.3f kA',I_pk)]);
	  end  
      title(ttl)
      hold off
      enhance_plot('times',fontsize,1)
      legend off
    
      subplot(2,nn,1)
      [Nd,D] = hist(dpct,Nbin);
      Nd     = Nd/1E3;
      dFWpct = fwhm(D,Nd,0.5);			    % calc. dE/E-FWHM [%]
      dD = mean(diff(D));               % D bin size [%]
      nD = length(D);
      D  = [D(1)-dD D(:)' D(nD)+dD];		% add charge=0 end-points to distribution
      Nd = [0 Nd 0];                    %  "    "        "        "    "
      stairs(Nd,D,'g-');
%      stairs(D,Nd,'g-');
      if splots==0
        ttl = ['{\it\sigma_E}/\langle{\itE}\rangle=' sprintf('%5.3f',sigdpct) '% (fwhm=' sprintf('%5.3f',dFWpct)];
      else
        ttl = ['{\it\sigma_E}/\langle{\itE}\rangle=' sprintf('%5.3f',sigdpct) '%'];
      end
      if gdfit
        hold on
        [yf,q,dq] = gauss_fit(D,Nd,1E-3*ones(size(Nd)),0);
        sigEG = q(4);         % gaussian fit sigma_dE/E0 [%]
        plot(yf,D,'r:')
        if splots==0
          ttl = [ttl ', fit=' sprintf('%5.3f',sigEG)];
        end
      end  
      if splots==0
        ttl = [ttl ')'];
      end
      dmin = min(dpct);
      dmax = max(dpct);
      dwf  = (dmax-dmin)/20;
      Nmax = max(Nd);
      if ecuts
        axis([0 Nmax*1.05 d1*100-dwf d2*100+dwf])
        hor_line(d1*100)
        hor_line(d2*100)
      else
        axis([0 Nmax*1.05 dmin-dwf-1E-10 dmax+dwf+1E-10])
%        axis([-5 5 0 Nmax*1.05])
      end
      Hy=ylabel('\Delta{\itE}/\langle{\itE}\rangle /%');
%      Hy=xlabel('\Delta{\itE}/\langle{\itE}\rangle /%');
      set(Hy,'VerticalAlignment','baseline');
      xlabel('{\itn}/10^3')
%      ylabel('{\itn}/10^3')
      title(ttl)
      hold off
      enhance_plot('times',fontsize,1)
      legend off
      
      if splots==0
        str = ['Source: ' inpf];
        if iswake
          zc_wakemm = zc_wake*1E3;			% convert to [mm]    
          subplot(2,nn,3)
%          plot_spline(zc_wakemm,dE_wake,'.')
           plot(zc_wakemm,dE_wake,'.m-')
          wmin = min(dE_wake);
          wmax = max(dE_wake);
          wwf  = (wmax-wmin)/20;
          if (wmax-wmin)~=0
            axis([zmin-zwf zmax+zwf wmin-wwf wmax+wwf])
          end
          xlabel('{\itz} /mm')
          Hy=ylabel('\itV_{\rmind}\rm /MV');
          set(Hy,'VerticalAlignment','baseline');
          title(literal(str))
          enhance_plot('times',fontsize,1)
          legend off
        else
          H = text(scx(0.075),scy(0.2),literal(str));
          set(H,'fontname','times')
          set(H,'fontsize',12)
        end
      end 
  
      i = 1:round(1/plot_frac):Nesim;
      subplot(2,nn,2)

      if contf
  	    [X,Y,Z,dx,dy] = contour_plot(zmm,dpct,Nbin,Nbin,0);		% plot color image, rather than scatter plot
		Zs = fast_smooth2(Z);
		imagesc(X,Y,Zs);
		axis xy
        colormap(jetvar);
      else
	    plot(zmm(i),dpct(i),'.r')								% plot scatter plot, rather than color image
      end
      zmin = min(zmm(i));
      zmax = max(zmm(i));
      zwf  = (zmax-zmin)/20;
      dmin = min(dpct(i));
      dmax = max(dpct(i));
      dwf  = (dmax-dmin)/20;
      if ecuts
        hor_line(d1*100)
        hor_line(d2*100)
        dm = d1*100-dwf;
        dp = d2*100+dwf;
      else
        dm = dmin-dwf;
        dp = dmax+dwf;
      end
      if zcuts
        ver_line(z1*1E3)
        ver_line(z2*1E3)
        zm = z1*1E3-zwf;
        zp = z2*1E3+zwf;
      else
        zm = zmin-zwf;
        zp = zmax+zwf;
      end
      axis([zm zp dm-1E-10 dp+1E-10])
      xlabel('{\itz} /mm')
      Hy=ylabel('\Delta{\itE}/\langle{\itE}\rangle /%');
      set(Hy,'VerticalAlignment','baseline');
      title(['\langle{\itE}\rangle='     sprintf('%6.4f',Ebarcuts) ...
             ' GeV, {\itN_e}=' sprintf('%6.4f',Ne1/1E10) '\times10^{10}'])
      bml = num2str(beamline(j,:));
      i   = findstr(bml,'  ');
      bml(i) = [];
      if splots==0
        if abs(cod) ~= 99
          text(scx(0.075),scy(0.02),[get_time ';  [' bml ']'])
        else  
          text(scx(0.075),scy(0.02),get_time)
        end
        H = text(zmin+(zmax-zmin+2*zwf)*0.54,dm+(dp-dm)*0.97/1.05,['\langle{\itz}\rangle=' sprintf('%5.3f mm',z_bar)]);
        H = text(scx(0.075),scy(0.04),[literal(fnfm) ':  ' comment]);
      end  
      enhance_plot('times',fontsize,1,1)
      legend off
    else                                          % end nargout < 1 (i.e., end plots section)
      jc = jc + 1;                                % count output locations (where cod < 0 | cod == 99)
      dE_Ej(1:length(d),jc) = d(:);
      zposj(1:length(z),jc) = z(:);
      Ebarj(jc) = Ebar;
      if nargout > 3                              % if FWHM output parameters wanted...
        zmm     = z*1E3;                          % convert to [mm]
        dpct    = d*100;                          % convert to [%]
		ii = find(zmm);
        [Nz1,Z] = hist(zmm(ii),Nbin);             % bin the Z-distribution
        ZFWmmj(jc) = fwhm(Z,Nz1,0.5);             % calc. Z-FWHM [mm]
        dZ = mean(diff(Z));                       % Z bin size [mm]
        I  = Nz1*(Ne1/1E10/Nesim)*elec*cspeed/dZ;	% convert N to peak current [kA]
        if nargout > 8
          [If,q,dq] = gauss_fit(Z,I,1E-3*ones(size(I)),0);
          sigzGj(jc) = q(4);                      % gaussian fit sigma_Z [mm]
        end
 		ii = find(dpct);
        [Nd,D]  = hist(dpct(ii),Nbin);            % bin the dE/E-distribution
        dFWpctj(jc) = fwhm(D,Nd,0.5);             % calc. dE/E-FWHM [%]
        z_barj(jc) = z_bar;
        Ebarcutsj(jc) = Ebarcuts;
        if nargout > 9
          [yf,q,dq] = gauss_fit(D,Nd,1E-3*ones(size(Nd)),0);
          sigEGj(jc) = q(4);                      % gaussian fit sigma_dE/E0 [%]
		  I_pk1 = max(I);
          I_pkj(jc) = I_pk1;                      % peak current in bunch center [kA]
		  I_pkfj(jc) = max(If);
        end  
        fcutj(jc)    = 1 - Ne1/Ne0;               % fraction of particles cut [ ]
      end
    end
  end                                             % end cod < 0 | cod == 99 stuff

  if abs(cod) == 99
    break
  end
  
end                                               % end loop over all beamline section

%if nargout > 0
%  dE_E = d;
%  zpos = z;
%  if nargout > 3				        % if FWHM output parameters wanted...
%    zmm     = z*1E3;				    % convert to [mm]
%    dpct    = d*100;				    % convert to [%]
%    [Nz1,Z] = hist(zmm,Nbin);			% bin the Z-distribution
%    ZFWmm = fwhm(Z,Nz1,0.5);			% calc. Z-FWHM [mm]
%    dZ = mean(diff(Z));    	           	% Z bin size [mm]
%    I  = Nz1*(Ne1/1E10/Nesim)*elec*cspeed/dZ;	% convert N to peak current [kA]
%    if nargout > 8
%      [yf,q,dq] = gauss_fit(Z,I,1E-3*ones(size(I)),0);
%      sigzG   = q(4);				    % gaussian fit sigma_Z [mm]
%    end  
%    [Nd,D]  = hist(dpct,Nbin);			% bin the dE/E-distribution
%    dFWpct  = fwhm(D,Nd,0.5);			% calc. dE/E-FWHM [%]
%    if nargout > 9
%      [yf,q,dq] = gauss_fit(D,Nd,1E-3*ones(size(Nd)),0);
%      sigEG   = q(4);				    % gaussian fit sigma_dE/E0 [%]
%    end  
%    fcut    = 1 - Nesim/Nesim0;			% fraction of particles cut [ ]
%  end
%end

end_time = get_time;
disp(' ')
disp(['LiTrack ended:' end_time])
