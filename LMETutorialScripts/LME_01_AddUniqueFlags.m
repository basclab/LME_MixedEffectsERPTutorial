% LME Tutorial Script: 1. Add Unique Event Markers

% This script adds unique 5-digit event markers (also referred to as flags)
% corresponding to a stimulus' emotion condition/actor/presentation number.
% The script loads each participants's file, extracts the original stimuli  
% event markers, and converts it to the corresponding unique 5-digit event 
% marker. 

% In this tutorial, we first convert the original event marker (e.g., 50)
% into a 3-digit preceding code (e.g., 301) using the eventMarkerMapping
% spreadsheet. The first digit corresponds to the emotion condition (e.g., 3)
% and the next two digits indicate the actor ID (e.g., 01). This 3-digit code
% is then appended with the presentation number (e.g., 01) to create the 
% final 5-digit marker (e.g., 30101). These steps can be modified depending 
% on the naming convention of your final event markers. 

% ***See Appendix D from Heise, Mon, and Bowman (submitted) for additional details. ***

% Requirements:
    % - Needs EEGLAB v 2019_0
        % - For more information on EEGLAB, see: Delorme, A. & Makeig, S. (2004).
        %   EEGLAB: an open source toolbox for analysis of single-trial EEG dynamics.
        %   https://sccn.ucsd.edu/eeglab/index.php   
    % - Filepaths to the following folders:
        % - importFolder: Folder containing preprocessed .set files. If needed,
        %   event markers in each file have been shifted to account for
        %   timing offsets. 
        % - saveUniqueFlagFolder: Folder for saving processed .set files after
        %   adding unique event markers to each file.
    % - Filepath to the following file used during processing:
        % - eventMarkerMapping: Spreadsheet with mappings between original stimuli 
        %   event markers (i.e., NumericalValue column) and unique preceding codes 
        %   representing a stimulus' emotion condition/actor (i.e., NewPrecedingCode 
        %   column). For more information about this file's columns, see the "Key" sheet in this file. 

% Script Functions:
    % 1. Import each participant's .set file
    % 2. Add unique flags based on original event marker (emotion condition/actor) and presentation number
    % 3. Save participant's updated .set file containing unique flags

% Output:
    % - Processed .set files containing unique 5-digit event markers (one
    %   file per participant).
    
% Copyright 2021 Megan J. Heise, Serena K. Mon, Lindsay C. Bowman
% Brain and Social Cognition Lab, University of California Davis, Davis, CA, USA.

% Permission is hereby granted, free of charge, to any person obtaining a 
% copy of this software and associated documentation files (the "Software"),
% to deal in the Software without restriction, including without limitation
% the rights to use, copy, modify, merge, publish, distribute, sublicense, 
% and/or sell copies of the Software, and to permit persons to whom the
% Software is furnished to do so, subject to the following conditions:

% The above copyright notice and this permission notice shall be included 
% in all copies or substantial portions of the Software.

% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
% SOFTWARE.

%% DATA ENVIRONMENT

% Specify folder location of preprocessed data 
importFolder = 'C:\Users\basclab\Desktop\LMETutorial\01_PreprocessedBeforeUniqueFlags';
cd(importFolder); % Change current folder to importFolder
importFiles = dir('*.set'); % Make a directory of all .set files (created in EEGLAB) in importFolder

% Specify folder location for saving processed data files (after adding unique flags)
saveUniqueFlagFolder = 'C:\Users\basclab\Desktop\LMETutorial\02_WithUniqueFlags';

% Import eventMarkerMapping spreadsheet, which is used to convert between 
% original stimuli event markers and unique preceding codes. NOTE: This spreadsheet
% contains 1 sheet corresponding to 'Experiment1'. If your experiment design
% is not fully crossed (e.g., participants were assigned different actors in order 
% to match the participant’s own race), you may need additional sheets for specifying
% each set of event markers.  
eventMarkerMappingFilename = 'C:\Users\basclab\Desktop\LMETutorial\LME_EventMarkerMappingKey.xlsx';
opts = detectImportOptions(eventMarkerMappingFilename, 'Sheet', 'Experiment1');
opts = setvartype(opts,'NumericalValue','string'); % Specify that these two columns are imported as strings
opts = setvartype(opts,'NewPrecedingCode','string');
eventMarkerMapping = readtable(eventMarkerMappingFilename, opts, 'Sheet', 'Experiment1'); % Import eventMarkerMapping spreadsheet

%% For each participant: Load .set file, add unique flags, and save updated file
for f = 1:length(importFiles) % Loop through each participant's file
    originalName = importFiles(f).name; % Extract filename
    filename = erase(originalName,".set"); % Remove .set from filename
   
    [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
    
%% 1. IMPORT EACH PARTICIPANT'S .SET FILE
    EEG = pop_loadset ('filename', originalName, 'filepath', importFolder);
    [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, 0);
    
%% 2. ADD UNIQUE FLAGS BASED ON ORIGINAL EVENT MARKER (EMOTION CONDITION/ACTOR) AND PRESENTATION NUMBER
    fprintf('Participant %s: Adding Unique Event Flags \n\n', filename);
   
    % 2a. Extract the participant's event marker array from the file
    allEventArray = {EEG.event.type}';
    
    % 2b. Use the eventMarkerMapping spreadsheet to identify original event markers 
    % of interest in the participant's allEventArray (for example, we are interested 
    % in identifying emotional face stimuli markers, but not fixation markers)
    for w = 1:length(eventMarkerMapping.NumericalValue) % Loop through each row of the eventMarkerMapping's NumericalValue column
        eventMarkerOriginal = eventMarkerMapping.NumericalValue(w); % Extract each original event marker 
        eventMarkerPreCode = eventMarkerMapping.NewPrecedingCode(w); % Extract corresponding 3-digit preceding code from the NewPrecedingCode column
        
        % Extract all occurrences of this specific event marker from the participant's allEventArray
        eventMarkerOriginalIdx = find(strcmp(allEventArray, eventMarkerOriginal));
        
        % 2c. For each occurrence of this original marker, add a new event with the corresponding
        % preceding code (e.g., for the 50 event marker, the corresponding preceding code 
        % is 301). This new event marker has the same latency as the original marker. 
        for x = 1:length(eventMarkerOriginalIdx)
            numEvents = length(EEG.event); % This variable is used in the next two lines to add a new event at the end of the participant's event array
            EEG.event(numEvents+1).type = eventMarkerPreCode{:}; % Name this new event marker as the preceding code
            EEG.event(numEvents+1).latency = EEG.event(eventMarkerOriginalIdx(x)).latency; % Copy latency from the original event marker to the new event marker
        end
    end
    EEG = eeg_checkset(EEG, 'eventconsistency'); % After adding new preceding code events, sort all events based on latency    
    allEventArray_Updated = {EEG.event.type}'; % Create a variable with the participant's updated event marker array (containing both original event markers and newly added markers)
   
    % 2d. Add the presentation number to each new event (e.g., convert the first instance of 301 to 30101;
    % convert the second instance of 301 to 30102)
    uniquePrecCode = unique(eventMarkerMapping.NewPrecedingCode); % Extract all unique preceding codes from the eventMarkerMapping's NewPrecedingCode column
    for y = 1:length(uniquePrecCode) % Loop through each unique preceding code
        precCode = uniquePrecCode(y); 
        
        % Extract all new events with this preceding code from the participant's allEventArray
        precCodeIdx = find(strcmp(allEventArray_Updated, precCode));
        
        % Generate presentation number array based on the number of occurrences
        % of this preceding code (e.g., if this code occurs 10 times in this participant's 
        % allEventArray, then the following array is created: ["01", "02", "03", "04",
        % "05", "06", "07", "08", "09", "10"])
        presentNumberArray = pad(string(1:length(precCodeIdx)),2,'left','0')';
        
        % Update each new event with the corresponding presentation number 
        % (e.g., "30101", "30102", ...). NOTE: This assumes that events 
        % have been sorted chronologically! (see line 124)
        allEventArray_Updated(precCodeIdx) = strcat(allEventArray_Updated(precCodeIdx), cellstr(presentNumberArray));
        [EEG.event.type] = deal(allEventArray_Updated{:});
    end
    [ALLEEG, EEG] = eeg_store(ALLEEG, EEG, CURRENTSET); % Store the updated dataset in ALLEEG 
    EEG = eeg_checkset(EEG, 'eventconsistency'); % Sort all events based on latency
    
    % 2e. Remove original event markers (e.g., 50). This step is performed after adding
    % the final 5-digit event markers in case debugging is needed. 
    allEventArray_Final = {EEG.event.type}'; % Create a new variable with the participant's updated event marker array (containing both original event markers and final 5-digit markers)
    
    % Extract location of all original event markers from the participant's allEventArray_Final
    eventMarkerOriginalIdx_Final = find(ismember(allEventArray_Final, eventMarkerMapping.NumericalValue));  
    EEG = pop_editeventvals(EEG,'delete',eventMarkerOriginalIdx_Final); % Delete these original event markers 
    [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG); % Store the updated dataset in ALLEEG
    EEG = eeg_checkset(EEG, 'eventconsistency'); % Sort all events based on latency
    
%% 3. SAVE PARTICIPANT'S UPDATED .SET FILE CONTAINING UNIQUE FLAGS
    filename = strcat(filename, '_uniqueFlag'); % Update filename to indicate that unique flags have been added
    EEG = pop_saveset(EEG, 'filename', filename, 'filepath', saveUniqueFlagFolder); % Save file in the desired folder

end
clear % Clear variable workspace