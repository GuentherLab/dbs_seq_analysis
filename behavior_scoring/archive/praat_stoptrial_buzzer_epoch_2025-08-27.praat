##  This script allows for manual demarcation of the buzzer epoch during STOP trials.
##  The script will create and open a TextGrid accompanying each sound file in a directory. 
##
##  Tier 1: BuzzerEpoch - indicate buzzer onset and offset
##	... select the onset or offset individually and press Enter
##	... or highlight the buzzer epoch and press Enter to demarcate both timepoints
##
##  Running this script again after having previously scored trials in this directly will allow you to revise prior scorings.
##  To skip to a specific file in this directory, change the 'Starting_file_index' value when starting the script. 
##
## For reference, the original buzzer stim file is contained in the github repository in:
## ..... https://github.com/Brain-Modulation-Lab/Task_SpeechMotorSequenceLearning/tree/main/stim/mixkit-game-show-buzz-in-3090.wav
##
## by Andrew Meier

clearinfo

form Select subject, file type, and tiers
        sentence SubName 1024
	sentence Starting_file_index 1
	sentence File_name_or_initial_substring trial
        sentence File_extension wav
	sentence Tier(s) BuzzerEpoch
endform

wd$ =     "C:\Users\amsme\Downloads\1005_ses-intraop_stop-trials-ambientmic\"
#wd$ =     "Y:\DBS\derivatives\" + "sub-DM" + subName$ + "\analysis\task-smsl_trial-audio\ses-intraop_stop-trials\"


outDir$ = wd$
file_extension$ = "wav"
tg_append$ = "_buzzer-epoch"

##  Make a list of all the sound files in the directory we're using/number of files (numFiles):
strings = Create Strings as file list: "wavList", wd$ + "'file_name_or_initial_substring$'*'file_extension$'"
numFiles = Get number of strings

# Analyze files including and following starting_file_index file
select Strings wavList
for ifile from number(starting_file_index$) to numFiles
	
	#    Query the file-list to get the first filename from it, then read that file in:
	filename$ = Get string... ifile 
	sound = Read from file... 'wd$''filename$'

	#Make a variable  "soundname$" that will be equal to the filename minus the ".wav" extension:
	soundname$ = selected$ ("Sound", 1)
	
	#Read in corresponding TextGrid
	## Look for grid, if found, open it, otherwise make new one
	tg_fullfile$ = "'wd$''soundname$''tg_append$'.TextGrid"
     	if fileReadable (tg_fullfile$)
  		Read from file... 'tg_fullfile$'
		tg_string$ = tg_append$
	else
  		select Sound 'soundname$'
		To TextGrid... "'tier$'"
		tg_string$ = ""
	endif
	tg_obj$ = soundname$ + tg_string$

    	#Annotate the TextGrid while script paused
	select Sound 'soundname$'
	plusObject: "TextGrid " + tg_obj$
	View & Edit
     	pauseScript: "Click Continue when you're done scoring this file"

     #  Code has now extracted all labels for all tiers for the current sound object and textgrid 
     #  Now close any objects we no longer need, and end for loop
	select TextGrid 'tg_obj$'
	Save as text file: tg_fullfile$
	select TextGrid 'tg_obj$'
    	plus Sound 'soundname$'
	Remove
	clearinfo
	select Strings wavList
endfor

select Strings wavList
Remove
clearinfo

 print You're finished! 'numFiles' files scored. Great job! :) 
