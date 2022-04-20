function [beamline,inp,Ne,E0,sigz0,sigd0,Nesim,z0_bar,d0_bar,asym,Nbin,sz_scale,nsamp,gzfit,gdfit,plot_frac,splots,comment,contf,LSCon,LSCsize,LSCfilter] = LiTrack_struc2params(inp_struc);

% Converts LiTrack GUI input data structure to nominal LiTrack parameters to allow LiTrack to be run from a GUI panel.

beamline	= inp_struc.beamline;
inp			= inp_struc.inp;
Ne			= inp_struc.Ne;
E0			= inp_struc.E0;
sigz0		= inp_struc.sigz0;
sigd0		= inp_struc.sigd0;
Nesim		= inp_struc.Nesim;
z0_bar		= inp_struc.z0_bar;
d0_bar		= inp_struc.d0_bar;
asym		= inp_struc.asym;
Nbin		= inp_struc.Nbin;
sz_scale	= inp_struc.sz_scale;
nsamp		= inp_struc.nsamp;
gzfit       = inp_struc.gzfit;
gdfit       = inp_struc.gdfit;
plot_frac	= inp_struc.plot_frac;
splots		= inp_struc.splots;
comment		= inp_struc.comment;
contf		= inp_struc.contourf;
LSCon       = inp_struc.LSCon;
LSCsize     = inp_struc.LSCsize;
LSCfilter   = inp_struc.LSCfilter;