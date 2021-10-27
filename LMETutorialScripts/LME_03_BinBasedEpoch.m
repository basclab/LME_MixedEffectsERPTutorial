% LME Tutorial Script: 3. Extract Bin-Based Epochs

% This script uses the bin descriptor file (see LME_02_CreateBinDescriptorFile.m
% script) to assign the 5-digit event markers into bins. Each subject's
% dataset is then epoched around these event marker using the desired time
% window. This epoched dataset will be used to calculate trial-level and 
% averaged ERP waveforms in the LME_04_CalculateERPs.m script. 

% This script also outputs an EventList text file for each subject. 
% This file documents the event markers and bins in each subject's
% dataset.

% ***See Appendix D from Heise, Mon, and Bowman (submitted) for additional details. ***

% Requirements:
    % - Needs EEGLAB v 2019_0 and ERPLAB v 8.01
        % - For more information on EEGLAB, see: Delorme, A. & Makeig, S. (2004).
        %   EEGLAB: An open source toolbox for analysis of single-trial EEG dynamics.
        %   https://sccn.ucsd.edu/eeglab/index.php
        % - For more information on ERPLAB, see: Lopez-Calderon, J., & Luck, S. J.
        %   (2014). ERPLAB: An open-source toolbox for the analysis of event-related
        %   potentials. https://erpinfo.org/erplab/    
    % - Filepaths to the following folders:
        % - importFolder: Folder containing processed .set files (e.g., files
        %   that have been filtered and re-referenced to the average reference. 
        % - saveEventListFolder: Folder for saving EventList .txt files (see 
        %   Outputs section below for more information).
        % - saveEpochDataFolder: Folder for saving epoched .set files. 
    % - Filepath to the following file used during processing:
        % - binDescriptorFilename: File specifying each bin's number, label,
        %   and 5-digit event markers. This file is created by the 
        %   LME_02_CreateBinDescriptorFile.m script. 
    
% Script Functions:
    % 1. Import each subject's .set file
    % 2. Create EventList 
    % 3. Assign events to bins and save final EventList containing bin
    %    information
    % 4. Extract bin-based epochs and baseline correct
    % 5. Save subject's epoched .set file
    
% Outputs:
    % - EventList .txt files documenting the event markers and bins
    %   saved for each subject's dataset. 
        % - For more information about EventLists, see the following ERPLAB
        %   resource: https://github.com/lucklab/erplab/wiki/Creating-an-EventList:-ERPLAB-Functions:-Tutorial
    % - Epoched .set files that have been time-locked to the unique 5-digit
    %   event markers for each subject.
    
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
importFolder = 'C:\Users\basclab\Desktop\LMETutorial\11_RereferencedToAvg';
cd(importFolder); % Change current folder to importFolder
importFiles = dir('*.set'); % Make a directory of all .set files in importFolder

% Specify folder location for saving EventList and epoched data files 
saveEventListFolder = 'C:\Users\basclab\Desktop\LMETutorial\12_EventList';
saveEpochDataFolder = 'C:\Users\basclab\Desktop\LMETutorial\13_Epoched';

% Specify filepath of bin descriptor file 
binDescriptorFilename = 'C:\Users\basclab\Desktop\LMETutorial\LME_BinDescriptorFile.txt';

%% For each subject: Load .set file and perform steps for epoching the data 
for f = 1:length(importFiles) % Loop through each subject's file
    originalName = importFiles(f).name; % Extract filename
    filename = erase(originalName,".set"); % Remove .set from filename
    
    [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
    
%% 1. IMPORT EACH SUBJECT'S .SET FILE
    EEG = pop_loadset ('filename', originalName, 'filepath', importFolder);
    [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, 0);
    
%% 2. CREATE EVENTLIST 
    fprintf('Subject %s: Creating EventList \n\n', filename);
    
    % The ‘BoundaryNumeric’ and ‘BoundaryString’ arguments specify that any
    % 'boundary' event markers are converted to ‘-99’ event markers.
    EEG  = pop_creabasiceventlist(EEG , 'AlphanumericCleaning', 'on', 'BoundaryNumeric', { -99 }, 'BoundaryString', { 'boundary' } );
    [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG);
    
%% 3. ASSIGN EVENTS TO BINS AND SAVE FINAL EVENTLIST CONTAINING BIN INFORMATION
    fprintf('Subject %s: Assigning Events to Bins \n\n', filename);
    
    % Create filename for saving the EventList .txt file
    saveEventListFilename = strcat(filename, '_EventList.txt');
    saveEventListFilepath = fullfile(saveEventListFolder, saveEventListFilename);
    
    % Use the binlister function to assign the 5-digit unique event markers
    % to their corresponding bins. In this tutorial, each event marker is 
    % assigned to three bins: their trial-specific bin (e.g., 30101), 
    % their overarching bin (e.g., Angry), and the "all conditions" bin.
    % The subject's EventList .txt file (with information about the event 
    % markers in the dataset and their assigned bins) is exported at the
    % end of this step. 
    EEG  = pop_binlister(EEG , 'BDF', binDescriptorFilename, 'ExportEL', saveEventListFilepath, 'IndexEL',  1, 'SendEL2', 'All', 'UpdateEEG', 'on', 'Voutput', 'EEG' );
    [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG);
    
%% 4. EXTRACT BIN-BASED EPOCHS AND BASELINE CORRECT
    fprintf('Subject %s: Extract Epochs and Baseline Correct \n\n', filename);

    % In this tutorial, data is epoched in -200 to 1000 ms time windows and
    % data is baseline corrected using the average voltage from the
    % pre-stimulus period. The epoch and baseline correction window can be
    % modified based on your processing pipeline. 
    EEG = pop_epochbin(EEG , [-200.0  1000.0],  'pre');
    [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG); % Store the epoched dataset in ALLEEG
    EEG = eeg_checkset(EEG); % Check dataset fields for consistency
    
%% 5. SAVE SUBJECT'S EPOCHED .SET FILE
    filename = strcat(filename, '_epoch.set'); % Update filename to indicate data has been epoched
    EEG = pop_saveset( EEG, 'filename', filename, 'filepath', saveEpochDataFolder); % Save file in the desired folder
    
    clear originalName filename saveEventListFilename saveEventListFilepath
end
clear % Clear variable workspace