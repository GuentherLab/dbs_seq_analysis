###Description of this script
##  This script allows for scoring of duration on trials for the DBS-SEQ experiment. The script will create 
##  and open a TextGrid accompanying each sound file in a directory. 
##  
##  This script does not contain accuracy or stop-response-type tiers, and is useful for when you are only scoring speech epoch. 

## Tier 1: SpeechEpoch - indicate speech onset, vowel offset, and (if present) coda consonant offset
##	-if the offset is released, mark 4 timepoints: speech onset, voicing onset, voicing offset, and final-consonant offset
##	-if the offset is not released, mark 3 timepoints: speech onset, voicing onset, and voicing/syllable offset
##	...	
##	... click the ‘SpeechEpoch’ tier (it should turn yellow)
##	... select the onset or offset individually and press Enter
##  Tier 2: Comments - use this Tier to add comments about the trial, e.g. if background noise makes it hard to hear a possible utterance. 
##  Tier 3: UnusableTrial - fill this in with a 1 if something makes the trial unusable... 
##	...e.g. the experimenter and subject are talking to each other rather than subject doing the task
##  Tier 4: DifficultToScore -  fill this in with 1 if the StopResponse is ambiguous (e.g. you can almost hear a response initiation)... 
##	...note in Comments why it's difficult to score

##  To run this script, you will need to have all sound files (one per trial) in a single directory. 
##
##  Script currently works only for .wav files but code can be edited to instead flexibly accept any file extension, as specified in the "file_extension" variable
##  Edit the names or number of Tiers in the "sentence Tier(s)" line below, or in the GUI that opens when you run the script. 
##  To start at a file other than the first one listed in the directory, use the Starting_file_index field
#
###End of description

clearinfo

## Set subject, file type, and desired tiers (opens GUI)
 
form Select subject, file type, and tiers
        sentence SubName 1044
	sentence Starting_file_index 1
	sentence File_name_or_initial_substring trial
        sentence File_extension wav
	sentence Tier(s) SpeechEpoch Comments UnusableTrial DifficultToScore
endform

# wd$ =     "C:\Users\amsme\Downloads\ses-intraop_go-trials\"
# wd$ =     "Y:\DBS\derivatives\" + "sub-DM" + subName$ + "\analysis\task-smsl_trial-audio\ses-intraop_go-trials\"
# wd$ =     "Y:\DBS\derivatives\" + "sub-DM" + subName$ + "\analysis\task-smsl_trial-audio\ses-intraop_go-trials-durations\"
wd$ =     "C:\temp\task-smsl_trial-audio\ses-intraop_go-trials\"

outDir$ = wd$

file_extension$ = "wav"

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
	
	## Look for grid, if found, open it, otherwise make new one
	full$ = "'wd$''soundname$'.TextGrid"
     		if fileReadable (full$)
  		Read from file... 'full$'
  		#Rename... 'soundname$'
     		
		else
  		select Sound 'soundname$'
  		To TextGrid... "'tier$'"
     		endif
	
	#Read from file... 'wd$''soundname$'.TextGrid
	#grid = To TextGrid: "Analysis", ""
	select Sound 'soundname$'
	plusObject: "TextGrid " + soundname$
	View & Edit

    	#Annotate the TextGrid while script paused
    	#plus Sound 'short$'
     	#Edit
     	pauseScript: "Click Continue when you're done scoring this file"
     	#minus Sound 'short$'
     	Write to text file... 'wd$''soundname$'.TextGrid

	selectObject: "TextGrid " + soundname$

		##   Now we query the TextGrid to get the label from each tier, 
		##   storing each value in a variable
		select TextGrid 'soundname$'
		speechEpoch$ = Get label of interval... 1 1
		comments$ = Get label of interval... 2 1
		unusableTrial$ = Get label of interval... 3 1
		difficultToScore$ = Get label of interval... 4 1
     
     #  Code has now extracted all labels for all tiers for the current sound object and
     #  textgrid, and written all the appropriate values to our log file.  
     #  Now close any objects we no longer need, and end for loop
	
	select TextGrid 'soundname$'
	Save as text file: wd$ + soundname$ + ".TextGrid"
	select TextGrid 'soundname$'
    	plus Sound 'soundname$'
	Remove
	clearinfo
	select Strings wavList
endfor

#select Strings list
select Strings wavList
Remove
clearinfo

 print You're finished! 'numFiles' files scored. Great job! :) 



#### modified 2021/08/08 by Andrew Meier for use with richardson lab data
## by Hilary Miller, 2021 for SEQ-FTD study, BU
## hilarym@bu.edu
## Parts inspired by Jill Thorson and Liz Heller Murray