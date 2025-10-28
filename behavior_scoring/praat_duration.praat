###Description of this script
##  This script allows for scoring of duration on trials for the DBS-SEQ experiment. The script will create 
##  and open a TextGrid accompanying each sound file in a directory. 
##  
##  This script does not contain accuracy or stop-response-type tiers, and is useful for when you are only scoring speech epoch. 

## Tier 1: SpeechEpoch - indicate speech onset, vowel offset, and (if present) coda consonant offset
##	-if the offset is released, mark 4 timepoints: speech onset, voicing onset, voicing offset, and final-consonant offset
##	-if the offset is not released, mark 3 timepoints: speech onset, voicing onset, and voicing/syllable offset
##	...	
##	... click the 'SpeechEpoch' tier (it should turn yellow)
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

### DBS-SEQ scoring helper (macOS-safe, 4 tiers guaranteed)

clearinfo

# ---------- GUI ----------
form Select subject, file type, tiers, and directory
    sentence subName 1047
    integer starting_file_index 1
    sentence file_name_or_initial_substring trial
    sentence file_extension wav
    sentence tiers SpeechEpoch Comments UnusableTrial DifficultToScore
    sentence data_directory
endform

# ---------- Normalize inputs ----------
if starting_file_index < 1
    starting_file_index = 1
endif
if file_extension$ = ""
    file_extension$ = "wav"
endif

# Replace any non-breaking spaces etc. in tiers string
tiers$ = replace_regex$(tiers$, "[ \t]+", " ", 0)

# ---------- Resolve working directory (paste or picker) ----------
wd$ = data_directory$

# Expand ~ to HOME on macOS/Linux
if wd$ <> "" and left$(wd$,1) = "~"
    home$ = environment$ ("HOME")
    if length (wd$) = 1
        wd$ = home$
    elsif mid$(wd$,2,1) = "/"
        wd$ = home$ + mid$(wd$,3)
    endif
endif

# If empty or invalid, open a folder picker (also grants macOS permissions)
if wd$ = ""
    wd$ = chooseDirectory$: "Select the folder containing your sound files"
endif

# Normalize trailing slash
if wd$ <> "" and right$(wd$,1) <> "/"
    wd$ = wd$ + "/"
endif

# Validate the directory by attempting to list any files
if wd$ = ""
    exitScript: "No folder selected."
endif

testList = Create Strings as file list: "dirSmokeTest", wd$ + "*"
select Strings dirSmokeTest
nStrings = Get number of strings
if nStrings = 0
    Remove
    wd2$ = chooseDirectory$: "Folder seemed empty or unreadable. Pick a folder?"
    if wd2$ = ""
        exitScript: "No usable folder."
    endif
    if right$(wd2$,1) <> "/"
        wd2$ = wd2$ + "/"
    endif
    wd$ = wd2$
else
    Remove
endif


# ---------- Build file list ----------
pattern$ = wd$ + file_name_or_initial_substring$ + "*." + file_extension$
strings = Create Strings as file list: "wavList", pattern$
select Strings wavList
numFiles = Get number of strings
if numFiles = 0
    # try listing all with this extension
    pattern$ = wd$ + "*." + file_extension$
    strings = Create Strings as file list: "wavList", pattern$
    select Strings wavList
    numFiles = Get number of strings
    if numFiles = 0
        exitScript: "No files matched:\n  " + pattern$
    endif
endif

# Preload names for the Jump menu
for i to numFiles
    select Strings wavList
    filename'i'$ = Get string... i
endfor

# ---------- Main loop ----------
ifile = starting_file_index
while ifile <= numFiles
    select Strings wavList
    filename$ = Get string... ifile

    Read from file... 'wd$''filename$'
    soundname$ = selected$ ("Sound", 1)

    # ----- Open or create the TextGrid beside the WAV -----
    full$ = wd$ + soundname$ + ".TextGrid"
    if fileReadable (full$)
        Read from file... 'full$'
        select TextGrid 'soundname$'
        nTiers = Get number of tiers
        if nTiers <> 4
            Remove
            select Sound 'soundname$'
    			To TextGrid... "SpeechEpoch Comments UnusableTrial DifficultToScore" ""
        endif
    else
        select Sound 'soundname$'
    		To TextGrid... "SpeechEpoch Comments UnusableTrial DifficultToScore" ""
    endif

    # ----- Edit -----
    select Sound 'soundname$'
    plus TextGrid 'soundname$'
    View & Edit

    # ----- Navigation -----
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

    # ----- Save & cleanup current objects -----
    select TextGrid 'soundname$'
    Save as text file: wd$ + soundname$ + ".TextGrid"
    select TextGrid 'soundname$'
    plus Sound 'soundname$'
    Remove

    if clicked = 2
        exitScript: "Stopped by user."
    endif

    # ----- Handle navigation choices (Praat auto-sets variables) -----
    if navigation = 1
        ifile = ifile + 1
    elsif navigation = 2
        ifile = select_file
        if ifile < 1
            ifile = 1
        endif
        if ifile > numFiles
            ifile = numFiles
        endif
    elsif navigation = 3
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

    clearinfo
endwhile

# ---------- Cleanup ----------
select Strings wavList
Remove
clearinfo
printline Done. Processed 'numFiles' files.

#### modified 2025/08/09 by Sam Hansen to improve GUI
#### modified 2021/08/08 by Andrew Meier for use with richardson lab data
## by Hilary Miller, 2021 for SEQ-FTD study, BU
## hilarym@bu.edu
## Parts inspired by Jill Thorson and Liz Heller Murray