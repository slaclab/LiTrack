function [dE,zc,sigz] = long_wake(z,L,Ne,Nbin,fn,pcwake)

%        [dE,zc,sigz] = long_wake(z[,L,Ne,Nbin,fn,pcwake])
%
%	Function to return the wakefield induced energy profile vs. z for
%	a set of given axial coordinates "z".
%
%  INPUTS:	z:		The internal axial coordinates, within the bunch, of
%					each electron with respect to any fixed point [m]
%			L:		(Optional, DEF=1 m) The length of the linac [m]
%			Ne:		(Optional, DEF=1  ) The number of electrons in the bunch
%			Nbin:   (Optional, DEF=100) The number of bins to use
%			fn:		(Optional, DEF='slac.dat') File name containing longitudinal
%					point wake (DEF='slac.dat')
%			pcwake:	(Optional, DEF=none) Point-charge wake used instead of file
%
%  OUTPUTS:	dE:		The energy loss per binned bunch slice [MeV]
%			zc:		The sample points along z where dE is calculated [m]
%					[e.g. plot(zc,dE)]
%			sigz:	rms bunch length (standard deviation) [m]
%
%           (2013-02-25) This version revised by Tim Maxwell primarily
%           per Spencer Gessner's changes to optimize redundant nested for-loop.
%           Modifications to preload wakefield externally not included.
%           Forced extrapolation of wake to zero added, with warning.
%=============================================================================

% Number of simulated particles.
nn   = length(z);
% RMS z-spread
sigz = std(z);

if nn < 100
  disp(' ')
  disp('Probably too few particles in your input "z" array')            
  disp(' ')
end
if nn > 5E6
  disp(' ')
  disp('>5E6 particles in your "z" array - let''s not get carried away now')
  disp(' ')
end
if sigz < 1E-6
  disp(' ')
  disp('Bunch length of <1 micron may be too short for this Green''s function')
  disp(' ')
end

if ~exist('L')
  L = 1; 					% default length of S-band linac [m]
end
if ~exist('Ne')
  Ne = 1; 					% default number of e- in bunch      
end
if ~exist('Nbin')
  Nbin = 100;  				% default number simulation particles
end
if ~exist('fn')
  fn = 'slac.dat';  		% default point wake
end  
if ~exist('pcwake')			% if a point-charge wake is not passed in, load default file
  cmnd = ['load ' fn];
  eval(cmnd);
  idot = find(fn=='.');
  if isempty(idot)
    error('Point wake file name needs "." in name string')
  end
  cmnd   = ['A = ' fn(1:(idot(1)-1)) ';'];
  eval(cmnd);
else
  [rpc,cpc] = size(pcwake);
  if cpc ~=2
    error('Point-charge wake function needs two columns')
  end
  A = pcwake;				% pcwake is 2-columns, 1st is z [m], 2nd is Wake [V/C/m]
end

zfnvar = A(:,1);			% m
Wfnvar = A(:,2);			% V/C/m
nA     = length(zfnvar);
% Histogram particles into Nbins with zeros at ends for interpolation
[N,zc] = hist(z,Nbin-2);
%dzc = mean(diff(zc));
dzc = zc(2)-zc(1);			% (TJM 2013-02-25) Above line replaced: hist returns constant-spacing in zc.  (Credit: Spencer)

% Add zero padding to close ends. (Note that extrapolation beyond limits is
% now explicitly set to zero below. using EXTRAPVAL parameter for interp1.)
zc = [zc(1)-dzc zc zc(Nbin-2)+dzc];
N = [0 N 0];

maxz_fn = zfnvar(nA-1);			% max Z in wake file (last point usually projected estimate)
% if (max(z)-min(z)) > maxz_fn
if (zc(Nbin)-zc(1)) > maxz_fn % (TJM 2013-02-25) Above line replaced: Bunch extents already defined by binned axis. (Credit: Spencer)
  disp(' ')
  if ~exist('pcwake')
    disp(['WARNING: maximum axial spread is > ' num2str(maxz_fn*1e3) ' mm and ' fn ' is inaccurate there.'])
    disp('         Wake will be extrapolated to zero as needed');
  else
    disp(['WARNING: maximum axial spread is > ' num2str(maxz_fn*1e3) ' mm and the RW-wake is inaccurate there'])
    disp('         Wake will be extrapolated to zero as needed');
  end
  disp(' ')
end

% delta vector
dE  = zeros(Nbin,1);
% electron charge (SI units, coulombs)
e   = 1.602176565E-19;
% Beam current normalization factor times drift length.
% Units of [C-m] with additional scale factor of 1e-6
% to convert final answer to MeV (instead of eV)
scl = -e*(Ne/nn)*L*1E-6;

%{
% (TJM 2013-02-25) This block removed in favor of interpolation and indexed
% multiplication used below (Thank you, Spencer Gessner).
% [If satisfied, this block can be deleted.]
for j = 1:Nbin				% jth bin is test-bin
  zcj = zc(j);				% save test bin z
  for k = 1:Nbin			% kth bin is field-bin
    zck = zc(k);
    if zck > zcj			% no wake when field-bin behind test-bin
      break
    end
    dz = zcj - zck;			% separation of field & test-bins (>=0)
    [ddz,ii] = min(abs(zfnvar-dz));
    ddz = sign(zfnvar(ii)-dz)*ddz;
    if ddz > 0
      i1 = ii - 1;
      i2 = ii;
      if i1 == 0
        error('Index into zeroth entry of wakefield array - try finer steps in wake file');
      end  
      dz1 = zfnvar(i1);
      dz2 = zfnvar(i2);
      W1  = Wfnvar(i1);
      W2  = Wfnvar(i2);
      W   = W2 - (W2-W1)*ddz/(dz2-dz1);
    elseif ddz < 0
      i1 = ii;
      i2 = ii + 1;
      if i2 > length(zfnvar)
        error('WARN: Index to a point beyond wakefield array - try extending the wake file');
      end
      dz1 = zfnvar(i1);
      dz2 = zfnvar(i2);
      W1  = Wfnvar(i1);
      W2  = Wfnvar(i2);
      W   = W1 - (W2-W1)*ddz/(dz2-dz1);
    else
      W   = Wfnvar(ii)/2;		% use 1/2 wake for self loading of bin
    end
    dE(j) = dE(j) + scl*N(k)*W;		% add each field-bin's wake to each test-bin's energy loss
  end
end
% End of old block.
%}

% Following code replaces commented block above.
N = N.';
zc = zc.';
% Bin separation vector
dzi = dzc*((1:Nbin)' - 1);
% Interpolated wake vector
Wf = interp1(A(:,1),A(:,2),dzi,'linear',0);
% Self-wake bin
Wf(1) = Wf(1)/2;
% Sum delta due to wake from leading bins
for j =1:Nbin
    dE(j) = sum(scl*N(j:-1:1).*Wf(1:j));
end
% End of new block.
