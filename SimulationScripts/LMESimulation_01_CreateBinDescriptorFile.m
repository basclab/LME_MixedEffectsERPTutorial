% LME Simulation Script: 1. Create Bin Descriptor File

% This script is adapted from the LME_02_CreateBinDescriptorFile.m
% tutorial script and creates a bin descriptor file used during ERPLAB 
% processing (see simulateOneSubject function). It uses the eventMarkerMapping
% file to create trial-specific bins (i.e., each bin corresponds to a
% presentation of a specific stimulus).

% Compared to the LME_02_CreateBinDescriptorFile.m tutorial script,
% this script does not create overarching bins that include all trials 
% within each condition or an "all conditions" bin. These aggregated 
% bins are not needed for analyzing simulated data (e.g., an "all 
% conditions" bin is not needed for selecting an ERP time window because
% the window is already specified by the simulated data parameters). 

% In addition, a bin descriptor file 'key' is created, which documents each
% bin's number, label, and corresponding event markers. Each unique event marker
% corresponds to one simulated stimulus trial and contains information about
% the stimulus' emotion condition/actor/presentation number.

% ***See SimulationScripts README.md available on the LME_MixedEffectsERPTutorial 
% GitHub for additional details: https://github.com/basclab/LME_MixedEffectsERPTutorial/tree/main/SimulationScripts 

% Requirements:        
    % - Filepaths to the following folder:
        % - saveBinDescriptorFilesFolder: Folder for saving bin descriptor file and
        %   bin descriptor file key.  
    % - Filepath to the following file used during processing:
        % - eventMarkerMapping: Spreadsheet listing all the preceding codes
        %   representing each simulated stimulus' emotion condition/actor 
        %   (i.e., NewPrecedingCode column). 
        %   For more information about this file's columns, see the "Key" sheet in this file. 

% Script Functions:
    % 1. Generate all simulated trial event markers 
    % 2. Create trial-specific bins (i.e., each presentation of a unique stimulus has a bin)
    % 3. Save trial-specific bins into a bin descriptor file key
    %    (LMESimulation_BinDescriptorFileKey.xlsx)
    % 4. Save trial-specific bins into a bin descriptor file
    %    (LMESimulation_BinDescriptorFile.txt) 
    
% Outputs:
    % - Bin descriptor file: File specifying each bin's number, label, and
    %   5-digit event markers. This file is used by ERPLAB functions in the
    %   simulateOneSubject function. 
        % - This file formats the information from the bin descriptor file key 
        %   (see below) into a text file based on the following ERPLAB guidelines:
        %   https://github.com/lucklab/erplab/wiki/Assigning-Events-to-Bins-with-BINLISTER:-Tutorial
    % - Bin descriptor file key: Spreadsheet used to document the information in 
    %   the bin descriptor file. This key contains three columns: 
        % - binNumber: The bin's number ID. Bins are required to be numbered
        %   starting at 1 and increment by 1 without missing values.
        % - binLabel: The text description for each bin (e.g., the "30101"
        %   bin only contains the specific 30101 trial).
        % - eventMarker: The 5-digit event marker assigned to the corresponding bin
        %   (e.g., the "30101" bin contains the 30101 event marker).

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

% Import eventMarkerMapping spreadsheet, which contains all of the unique
% preceding codes (i.e., each code corresponds to a specific stimulus).
% NOTE: This spreadsheet contains 1 sheet corresponding to 'Experiment1'. 
eventMarkerMappingFilename = 'C:\Users\basclab\Desktop\LMESimulation\LMESimulation_EventMarkerMappingKey.xlsx';
opts = detectImportOptions(eventMarkerMappingFilename, 'Sheet', 'Experiment1');
opts = setvartype(opts,'NewPrecedingCode','string'); % Specify that this column is imported as a string
eventMarkerMapping = readtable(eventMarkerMappingFilename, opts, 'Sheet', 'Experiment1'); % Import eventMarkerMapping spreadsheet

% Specify the maximum presentation number of each stimulus. NOTE: This variable 
% assumes that each stimulus will be presented the same number of times. 
presentNumber = 10; 
presentNumberArray = pad(string(1:presentNumber),2,'left','0')'; % Create a formatted string array containing the specified presentation numbers

% Create a table structure for saving bin numbers and labels and the
% corresponding 5-digit event markers belonging to each bin
binDescriptorTable = table({}, {}, {},'VariableNames',{'binNumber','binLabel','eventMarker'});

% Specify folder location for saving bin descriptor file and bin descriptor file key
saveBinDescriptorFilesFolder = 'C:\Users\basclab\Desktop\LMESimulation';
saveBinDescriptorFileKey = fullfile(saveBinDescriptorFilesFolder,'LMESimulation_BinDescriptorFileKey.xlsx'); % Filename for bin descriptor file (key used for documentation)
saveBinDescriptorFile = fullfile(saveBinDescriptorFilesFolder,'LMESimulation_BinDescriptorFile.txt'); % Filename for bin descriptor file (used for ERPLAB processng)

%% 1. GENERATE ALL SIMULATED TRIAL EVENT MARKERS

% Extract all unique preceding codes from the eventMarkerMapping
% spreadsheet
allPrecCode = eventMarkerMapping.NewPrecedingCode; 

% Generate all possible 5-digit event markers by appending each unique
% preceding code (e.g., 301) with all possible presentation numbers
% (e.g., ["30101", "30102", "30103", "30104", "30105", "30106", "30107",
% "30108", "30109", "30110"])
allConditionsArray = strcat(repelem(allPrecCode,10), repmat(presentNumberArray,length(allPrecCode),1));

%% 2. CREATE TRIAL-SPECIFIC BINS (EACH PRESENTATION OF A UNIQUE STIMULUS HAS A BIN)

% Specify the bin numbers for each unique stimulus presentation by 
% counting the number of unique event markers in the allConditionsArray. 
% The first trial-specific bin is bin 1, the second trial-specific bin is
% bin 2, and so on. 
trialSpecificBinNumber = (1:length(allConditionsArray))';

% Create a table storing each trial-specific bin's number, label, and
% corresponding 5-digit event marker. The bin label and event marker are
% identical because each event marker is assigned to its own bin. 
binDescriptorTable = table(num2cell(trialSpecificBinNumber), cellstr(allConditionsArray), ...
    cellstr(allConditionsArray),'VariableNames',{'binNumber','binLabel','eventMarker'});

%% 3. SAVE TRIAL-SPECIFIC BINS INTO A BIN DESCRIPTOR FILE KEY

% Save binDescriptorTable as a spreadsheet
writetable(binDescriptorTable, saveBinDescriptorFileKey);

%% 4. SAVE TRIAL-SPECIFIC BINS INTO A BIN DESCRIPTOR FILE

% Extract each column from binDescriptorTable and create a string array
% with dimensions 3 x height of binDescriptorTable. Each column is a bin
% and the first row is the bin number, the second row is the bin label,
% and the third row is the event marker. 
binNumberArray = (binDescriptorTable.binNumber)';
binLabelArray = (string(char(binDescriptorTable.binLabel)))';
binEventMarkerArray = strtrim((string(char(binDescriptorTable.eventMarker))))';
binDescriptorFile_Raw = vertcat(binNumberArray, binLabelArray, binEventMarkerArray);

% Specify the format for saving the bin number/label/event marker in 
% the bin descriptor file:
    % bin Number (e.g., bin 1)
    % bin Label (e.g., 30101)
    % .{eventMarker1} (e.g., .{30101})
% For more information, see the following ERPLAB tutorial: https://github.com/lucklab/erplab/wiki/Assigning-Events-to-Bins-with-BINLISTER:-Tutorial
binDescriptorFileSpec = 'bin %.0f\n%s\n.{%s}\n \n';

% Create and save the bin descriptor file based on the above formatting guidelines 
fid = fopen(saveBinDescriptorFile, 'w');
fprintf(fid, binDescriptorFileSpec, binDescriptorFile_Raw);
fclose(fid);

clear % Clear variable workspace