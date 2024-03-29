% LME Tutorial Script: 2. Create Bin Descriptor File

% This script creates a bin descriptor file used during ERPLAB processing
% (see LME_03_BinBasedEpoch.m script). It uses the eventMarkerMapping file
% to create trial-specific bins (i.e., each bin corresponds to a presentation of 
% a specific stimulus) and overarching bins that include all trials within each
% condition (e.g., used for plotting ERPs). In addition, an �all conditions� bin
% is created, which includes every trial across every condition (e.g., can be used for
% selecting ERP time windows). 

% In addition, a bin descriptor file 'key' is created, which documents each
% bin's number, label, and corresponding event markers. Each unique event marker
% corresponds to one stimulus trial and contains information about the stimulus'
% emotion condition/actor/presentation number.

% To adapt the script for your experiment design, modify the eventMarkerMapping
% spreadsheet with your event marker naming conventions (see example
% template on GitHub: https://github.com/basclab/LME_MixedEffectsERPTutorial/blob/main/LMETutorialScripts/LME_EventMarkerMappingKey.xlsx).
% In addition, see script comments below for code that can be
% customized.

% ***See Appendix D from Heise, Mon, and Bowman (2022) for additional details. ***

% Requirements:  
    % - Needs MATLAB R2019a
    % - Filepath to the following folder:
        % - saveBinDescriptorFilesFolder: Folder for saving bin descriptor file and
        %   bin descriptor file key.  
    % - Filepath to the following file used during processing:
        % - eventMarkerMappingFilename: Spreadsheet listing the preceding codes
        %   representing each stimulus' emotion condition/actor (i.e., NewPrecedingCode
        %   column) and the corresponding overarching bin (i.e., EmotionLabel column).
        %   For more information about this file's columns, see the "Key" sheet in this file. 
    % - presentNumber: Maximum presentation number of each stimulus. See
    %   comments below for more information.

% Script Functions:
    % 1. Create overarching bins that include all trials within each condition
    % 2. Create "all conditions" bin that includes every trial across every condition
    % 3. Create trial-specific bins (i.e., each presentation of a unique stimulus has a bin)
    % 4. Save bins created in steps 1-3 into a bin descriptor file key
    %    (LME_BinDescriptorFileKey.xlsx)
    % 5. Save bins created in steps 1-3 into a bin descriptor file
    %    (LME_BinDescriptorFile.txt) 
    
% Outputs:
    % - Bin descriptor file: File specifying each bin's number, label, and
    %   5-digit event markers. This file is used by ERPLAB functions in the 
    %   LME_03_BinBasedEpoch.m script. 
        % - This file formats the information from the bin descriptor file key 
        %   (see below) into a text file based on the following ERPLAB guidelines:
        %   https://github.com/lucklab/erplab/wiki/Assigning-Events-to-Bins-with-BINLISTER:-Tutorial
    % - Bin descriptor file key: Spreadsheet used to document the information in 
    %   the bin descriptor file. This key contains three columns: 
        % - binNumber: The bin's number ID. Bins are required to be numbered
        %   starting at 1 and increment by 1 without missing values.
        % - binLabel: The text description for each bin (e.g., the "Angry" bin 
        %   contains all trials of the Angry emotion condition; the "AllEmotion"
        %   bin contains every trial for all conditions; the "30101" bin only 
        %   contains the specific 30101 trial). 
        % - eventMarker: The 5-digit event markers assigned to the corresponding bin
        %   (e.g., the "Angry" bin contains 30101;30102;30103;30104;30105;etc.).

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
% preceding codes (i.e., each code corresponds to a specific stimulus) and
% their corresponding overarching bin (e.g., emotion condition).
% NOTE: This spreadsheet contains 1 sheet corresponding to 'Experiment1'.
% If your experiment design is not fully crossed (e.g., subjects were
% assigned different actors in order to match the subject�s own race),
% you may need additional sheets for specifying each set of preceding codes.  
eventMarkerMappingFilename = 'C:\Users\basclab\Desktop\LMETutorial\LME_EventMarkerMappingKey.xlsx';
opts = detectImportOptions(eventMarkerMappingFilename, 'Sheet', 'Experiment1');
opts = setvartype(opts,'NewPrecedingCode','string'); % Specify that this column is imported as a string
eventMarkerMapping = readtable(eventMarkerMappingFilename, opts, 'Sheet', 'Experiment1'); % Import eventMarkerMapping spreadsheet

% Specify the maximum presentation number of each stimulus. NOTE: This variable 
% assumes that each stimulus will be presented the same number of times. 
% The following two lines of code can be modified based on your experiment design.
presentNumber = 10; 
presentNumberArray = pad(string(1:presentNumber),2,'left','0')'; % Create a formatted string array containing the specified presentation numbers

% Create a table structure for saving bin numbers and labels and the
% corresponding 5-digit event markers belonging to each bin
binDescriptorTable = table({}, {}, {},'VariableNames',{'binNumber','binLabel','eventMarker'});

% Specify folder location for saving bin descriptor file and bin descriptor file key
saveBinDescriptorFilesFolder = 'C:\Users\basclab\Desktop\LMETutorial';
saveBinDescriptorFileKey = fullfile(saveBinDescriptorFilesFolder,'LME_BinDescriptorFileKey.xlsx'); % Filename for bin descriptor file key (used for documentation)
saveBinDescriptorFile = fullfile(saveBinDescriptorFilesFolder,'LME_BinDescriptorFile.txt'); % Filename for bin descriptor file (used for ERPLAB processing)

%% 1. CREATE OVERARCHING BINS THAT INCLUDE ALL TRIALS WITHIN EACH CONDITION

% Extract all overarching bin labels (e.g., all unique emotion conditions)
% The 'stable' argument specifies that the order that overarching bins are
% listed in the eventMarkerMapping spreadsheet is maintained.
uniqueOverarchingBins = unique(eventMarkerMapping.EmotionLabel, 'stable'); 

% Create array for storing all trial-specific 5-digit event markers across
% all overarching bins. This array will be used for creating the "all
% conditions" bin in step 2. 
allConditionsArray = []; 

for i =1:length(uniqueOverarchingBins) % Loop through each possible overarching bin
    overarchingBinLabel = uniqueOverarchingBins{i}; % Extract overarching bin label from array
   
    overarchingBinIndex = strcmp(eventMarkerMapping.EmotionLabel, overarchingBinLabel); % Locate this bin's rows in the eventMarkerMapping's EmotionLabel column
    overarchingBinPrecCode = eventMarkerMapping.NewPrecedingCode(overarchingBinIndex); % Extract this bin's unique preceding codes using the overarchingBinIndex variable

    % Generate all possible 5-digit event markers by appending each unique 
    % preceding code (e.g., 301) with all possible presentation numbers 
    % (e.g., ["30101", "30102", "30103", "30104", "30105", "30106", "30107",
    % "30108", "30109", "30110"])
    overarchingBinEventMarkers = strcat(repelem(overarchingBinPrecCode,10), repmat(presentNumberArray,length(overarchingBinPrecCode),1));
    
    % Create a string that lists each event markers and separates them with 
    % semicolons (e.g., "30101;30102;30103;30104;30105;30106;30107;30108;30109;30110;").
    % Note that the final event marker is followed by a semicolon, which will be
    % removed in line 150 with the (1:end-1) indexing. 
    eventMarkersStringSpec = '%s;'; 
    overarchingBinEventMarkers_output = sprintf(eventMarkersStringSpec, overarchingBinEventMarkers); 
    
    % Create a row in the binDescriptorTable with this overarching bin's number
    % (specified in line 126 with the i variable), label (specified in line 127
    % with the overarchingBinLabel), and corresponding 5-digit event markers 
    % (formatted in line 143). NOTE: The table's columns are formatted as cell arrays.
    binDescriptorTable = [binDescriptorTable; {num2cell(i), cellstr(overarchingBinLabel)}, ...
        {overarchingBinEventMarkers_output(1:end-1)}];
    
    % The event markers saved in the overarchingBinEventMarkers array are also 
    % saved in the allConditionsArray for use in step 2. 
    allConditionsArray = vertcat(allConditionsArray, overarchingBinEventMarkers); 
end

%% 2. CREATE "ALL CONDITIONS" BIN THAT INCLUDES EVERY TRIAL ACROSS EVERY CONDITION

% Specify the bin number and label for the "all conditions" bin
allConditionsBinNumber = height(binDescriptorTable) + 1; % The bin number is equal to the total number of overarching bins + 1 (the + 1 is used to add a new row)
allConditionsBinLabel = 'AllEmotion';

% Format the event markers in the allConditionsArray using the same
% specifications from line 142.
allConditionsEventMarkers_output = sprintf(eventMarkersStringSpec, allConditionsArray);

% Add a new row to binDescriptorTable for this "all conditions" bin
binDescriptorTable = [binDescriptorTable; {num2cell(allConditionsBinNumber), cellstr(allConditionsBinLabel), ...
    {allConditionsEventMarkers_output(1:end-1)}}];

%% 3. CREATE TRIAL-SPECIFIC BINS (I.E., EACH PRESENTATION OF A UNIQUE STIMULUS HAS A BIN)

% Specify the bin number for each unique stimulus presentation by first 
% counting the number of unique event markers in allConditionsArray. Each
% bin number is then adjusted based on the number of existing bins 
% (e.g., if there are already 5 bins created in steps 1-2, then the
% trial-specific bin numbers are shifted by 5). 
trialSpecificBinNumber = (1:length(allConditionsArray))';
trialSpecificBinNumber = trialSpecificBinNumber + height(binDescriptorTable); 

% Create a table storing each trial-specific bin's number, label, and
% corresponding 5-digit event marker. The bin label and event marker are
% identical because each event marker is assigned to its own bin. 
trialSpecificTable = table(num2cell(trialSpecificBinNumber), cellstr(allConditionsArray), ...
    cellstr(allConditionsArray),'VariableNames',{'binNumber','binLabel','eventMarker'});

% Update the binDescriptorTable with the trial-specific bin table
binDescriptorTable = [binDescriptorTable; trialSpecificTable];

%% 4. SAVE BINS CREATED IN STEPS 1-3 INTO A BIN DESCRIPTOR FILE KEY

% Save binDescriptorTable as a bin descriptor file key spreadsheet for
% documentation
writetable(binDescriptorTable, saveBinDescriptorFileKey);

%% 5. SAVE BINS CREATED IN STEPS 1-3 INTO A BIN DESCRIPTOR FILE

% Extract each column from binDescriptorTable and create a string array
% with dimensions 3 x height of binDescriptorTable. Each column is a bin
% and the first row is the bin number, the second row is the bin label,
% and the third row is the list of event markers. 
binNumberArray = (binDescriptorTable.binNumber)';
binLabelArray = (string(char(binDescriptorTable.binLabel)))';
binEventMarkerArray = strtrim((string(char(binDescriptorTable.eventMarker))))';
binDescriptorFile_raw = vertcat(binNumberArray, binLabelArray, binEventMarkerArray);

% Specify the format for saving the bin number/label/event markers in 
% the bin descriptor file:
    % bin number (e.g., bin 6)
    % bin label (e.g., 30101)
    % .{eventMarker1;eventMarker2;eventMarker3} (e.g., .{30101})
% For more information, see the following ERPLAB tutorial: https://github.com/lucklab/erplab/wiki/Assigning-Events-to-Bins-with-BINLISTER:-Tutorial
binDescriptorFileSpec = 'bin %.0f\n%s\n.{%s}\n \n';

% Create and save the bin descriptor file based on the above formatting guidelines 
fid = fopen(saveBinDescriptorFile, 'w');
fprintf(fid, binDescriptorFileSpec, binDescriptorFile_raw);
fclose(fid);

clear % Clear variable workspace