# LiTrack Installation (Feb. 18, 2005):

To install and initially run the LiTrack Matlab 2D electron tracking code,
do the following:

1).  Download the 'LiTrack.zip' file from:
     http://www.slac.stanford.edu/~emma/codes.shtml

2).  Unzip the file (simply double-click it in Windows?)

3).  Place the unzipped folder called "LiTrack" (no double quotes)
     into the folder of your choice (e.g., under 'C:/Matlab/work').

4).  Add this folder and all of its subfolders to your Matlab path* (see * below).

5).  Edit the file 'run_LiTrack_GUI.m' and change the directory
     text string within, as described inside that file. (Note
     this step is only necessary if you want to run the GUI
     version - see more below).

6).  If you have Matlab version 7.0 or higher (release 14, SP-1), you can
     run the GUI (graphical user interface). Otherwise you can only
     run the line-command version.

7).  Start up Matlab.

# To run the GUI (Matlab v. 7.0 or higher):

8a). At the command prompt, type "run_LiTrack_GUI"
     (case insensitive, no double quotes). A color panel will appear.
     Click "TRACK" for a very fast demo, or double-click one of the
     "Save/Restore Files" and then "TRACK", to track SPPS, LCLS, or
     an older TESLA-XFEL, etc.

9a). (Optional) You can also arrange to have LiTrack start up at a
     simple click. After you have typed "run_LiTrack_GUI" (above),
     open the "Desktop" pull-down menu in the Matlab command window,
     choose "Command History" (if not already chosen), and note
     the command "run_LiTrack_GUI" appears here at the bottom of
     the command history list. Right-click this string and drag it
     up to the shortcuts bar. The Shortcut Editor window will ask for
     a shortcut label and an icon type (choose, for example, 'LiTrack'
     and 'MATLAB icon', or as you like). This shortcut will be available
     in future Matlab sessions as a quick LiTrack startup.

# To run the line-command version (any Matlab version?):

8b). At the command prompt, type "LiTrack('spps0')" (case insensitive,
     no double quotes). Several plots should soon appear on the screen
     and the tracking should finish in <1 minute (for a reasonable CPU).

A separate text file describes how to use and interpret LiTrack,
but this should at least get you started.

Please E-mail Paul Emma (SLAC) at: Emma@SLAC.Stanford.edu, for
questions or problems.

    *  To set the Matlab path:
       ======================
       Start Matlab, then in its command window, click the "File" pull-down menu, choose
       "Set Path...", and click "Add with Subfolders...", browse over to the new unzipped
       "LiTrack" folder, choose it, and then click "SAVE".
