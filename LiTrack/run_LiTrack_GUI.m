%	This file calls the LiTrack GUI version and establishes the directory names where LiTrack
%	and its subfolders have been placed. Please modify only the text string below named: "dir_str".
%
%	If you cannot run the LiTrack GUI (due to a Matlab version prior to version 7),
%	you can always run the line-command version.  Simply skip this file and, at the Matlab prompt,
%	type "LiTrack('spps0')" to run an example case (the SPPS at SLAC).  First make sure the new
%	"LiTrack" folder has been added to your Matlab path* (for both GUI and line-command versions).
%
%	*	To set the Matlab path:
%		======================
%		In the Matlab command window click the "File" pull-down menu, choose "Set Path...",
%		and click "Add with Subfolders...", browse over to the new unzipped "LiTrack" folder,
%		choose it, and then click "SAVE").
%=================================================================================================

% Add matlab paths
root_folder = fileparts(mfilename('fullpath'));
addpath(genpath(root_folder))

%dir_str = pwd;
dir_str = '/Users/ding/E/local_laptop/matlab/LiTrack_202204/LiTrack'
LiTrack_GUI('dir',[dir_str filesep 'Wakefiles'],[dir_str filesep 'ParticleFiles'],[dir_str filesep 'SaveFiles']);	% do not change this line
