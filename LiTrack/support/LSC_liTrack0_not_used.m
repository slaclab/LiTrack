function [t,p,tbin,dpbin] = LSC_liTrack(t,p,Q,Nbin,rb,Lund,ref_length)
gamma0 = mean(p);
gammaz = gamma0;
tmin = min(t);
tmax = max(t);
dt = (tmax - tmin)/Nbin;
tbin = linspace(tmin-dt/2,tmax+dt/2,Nbin+1);
dt = tbin(2) - tbin(1);
nn = hist(t,tbin);
np = length(t);
I = nn*Q/np/dt;

fft_I = fftshift(fft(I));

clight = 299792458;
Z0 = 120*pi;

fmax = 1/dt;
f = linspace(-fmax/2,fmax/2,Nbin+1);
k = 2*pi*f/clight;

k0 = 2*pi/(max(tbin)-min(tbin))/clight;

ARk = k*rb/gammaz;
fft_E = (1i*k.*(1-ARk.*besselk(1,ARk))./(ARk.^2)).*fft_I.*Lund*Z0/(pi*gammaz^2).*exp(-(k*dt*Nbin*clight*ref_length/2/pi).^2);
fft_E(k==0) = 0;
E = ifft(ifftshift(fft_E));
dpbin = real(E)/1e6/0.511;
dp = interp1(tbin,dpbin,t);

figure
plot(k/k0,abs(fft_E))

figure
plot(tbin,dpbin)

p = p + dp;

