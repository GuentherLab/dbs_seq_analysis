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
	integer Starting_file_index 1
	sentence File_name_or_initial_substring trial
    sentence File_extension wav
	sentence Tier(s) BuzzerEpoch
endform

## Choose folder
wd$ = chooseDirectory$: "Select the folder containing your sound files"
if wd$ = "" 
	exitScript: "No folder selected."
endif

if right$(wd$, 1) <> "/" 
	wd$ = wd$ + "/" 
endif


outDir$ = wd$
file_extension$ = "wav"
tg_append$ = "_buzzer-epoch"

##  Build file list
pattern$ = wd$ + file_name_or_initial_substring$ + "*." + file_extension$
strings = Create Strings as file list: "wavList", pattern$
numFiles = Get number of strings
if numFiles = 0
    exitScript: "No files matched:\n  " + pattern$
endif

## Preload names for Jump menu
for i to numFiles
    select Strings wavList
    filename'i'$ = Get string... i
endfor

## Initialize loop index
ifile = starting_file_index
if ifile < 1
    ifile = 1
endif

## Main loop
while ifile <= numFiles
    select Strings wavList
    filename$ = Get string... ifile
    sound = Read from file... 'wd$''filename$'

    # Make soundname$ = filename without extension
    soundname$ = selected$ ("Sound", 1)

    # Read or create corresponding TextGrid
    tg_fullfile$ = "'wd$''soundname$''tg_append$'.TextGrid"
    if fileReadable (tg_fullfile$)
        Read from file... 'tg_fullfile$'
        tg_string$ = tg_append$
    else
        select Sound 'soundname$'
        To TextGrid... "'tier$'"   ; (kept verbatim from Script B)
        tg_string$ = ""
    endif
    tg_obj$ = soundname$ + tg_string$

    # Open editor
    select Sound 'soundname$'
    plusObject: "TextGrid " + tg_obj$
    View & Edit

    ## Pause UI with navigation
    beginPause: "Scoring file 'ifile' of 'numFiles': 'filename$'"
        comment: "Current file: 'filename$' ('ifile' of 'numFiles')"
        optionMenu: "Navigation", 1
            option: "Continue to next file"
            option: "Jump to specific file"
            option: "Skip ahead"
        optionMenu: "Select file", 1
            for i to numFiles
                option: filename'i'$
            endfor
        optionMenu: "Skip amount", 1
            option: "1"
            option: "10"
            option: "25"
    clicked = endPause: "Continue", "Quit", 1

    ## Save & clean up current objects
    select TextGrid 'tg_obj$'
    Save as text file: tg_fullfile$
    select TextGrid 'tg_obj$'
    plus Sound 'soundname$'
    Remove
    clearinfo

    ## Quit handling
    if clicked = 2
        # User chose "Quit"
        exitScript: "Stopped by user."
    endif

    ## Handle navigation choices (Praat auto sets variables)
    if navigation = 1
        # Continue to next file
        ifile = ifile + 1
    elsif navigation = 2
        # Jump to specific file (from "Select file" menu)
        ifile = select_file
        if ifile < 1
            ifile = 1
        endif
        if ifile > numFiles
            ifile = numFiles
        endif
    elsif navigation = 3
        # Skip ahead (1, 10, 25)
        if skip_amount = 1
            skip = 1
        elsif skip_amount = 2
            skip = 10
        else
            skip = 25
        endif
        if ifile + skip <= numFiles
            ifile = ifile + skip
        else
            ifile = numFiles + 1
        endif
    endif
endwhile

## End / cleanup
select Strings wavList
Remove
clearinfo

 print You're finished! 'numFiles' files scored. Great job! :) 

## Updated 8/27 with GUI updates - Sam Hansen