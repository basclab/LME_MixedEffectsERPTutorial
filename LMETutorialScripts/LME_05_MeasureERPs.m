% LME Tutorial Script: 5. Measure ERPs

% This script extracts the mean amplitude of a component from the trial-level
% and average ERP waveforms calculated in the LME_04_CalculateERPs.m script.
% Data is exported for each channel of interest.

% The mean amplitude value is extracted for each of the bins defined by
% the bin descriptor file (see the LME_02_CreateBinDescriptorFile.m and
% LME_03_BinBasedEpoch.m scripts for more information). For experiments 
% that are not fully crossed (e.g., subjects were assigned different 
% actors in order to match the subject's own race) or for any amount 
% of missing trials, some trial-level bins may not contain any data. The 
% setNaNForEmptyBins function locates these "empty" bins and sets their
% value to NaN (i.e., Not a Number) during step 3. 

% Each subject has one exported mean amplitude .txt file. The
% LME_06_OrganizeDataFiles.R script merges all of the datafiles into long
% format in R so that all subjects are saved in one dataframe. 

% This script can be modified to export other output measures (e.g., peak
% amplitude) by changing the arguments of the pop_geterpvalues function
% in step 2. For more information about this function and example code for 
% extracting a different output measure (e.g., peak amplitude), see the
% following ERPLAB resource: https://github.com/lucklab/erplab/wiki/Measuring-amplitudes-and-latencies-with-the-ERP-Measurement-Tool:-Tutorial  

% ***See Appendix D from Heise, Mon, and Bowman (submitted) for additional details. ***

% Requirements:
    % - Needs EEGLAB v 2019_0 and ERPLAB v 8.01
        % - For more information on EEGLAB, see: Delorme, A. & Makeig, S. (2004).
        %   EEGLAB: an open source toolbox for analysis of single-trial EEG dynamics.
        %   https://sccn.ucsd.edu/eeglab/index.php
        % - For more information on ERPLAB, see: Lopez-Calderon, J., & Luck, S. J.
        %   (2014). ERPLAB: An open-source toolbox for the analysis of event-related
        %   potentials. https://erpinfo.org/erplab/     
    % - Filepaths to the following folders:
        % - importFolder: Folder containing .erp files created by the LME_04_CalculateERPs.m script.  
        % - saveOutputFolder_RAW: Folder for saving exported mean amplitude .txt
        %   files created during step 2. These raw files should NOT be used for
        %   analysis because the values of the empty bins have not been
        %   corrected by the setNaNForEmptyBins function. 
        % - saveOutputFolder_FINAL: Folder for saving the FINAL mean amplitude
        %   .txt files created with the setNaNForEmptyBins function in step 3.
        % - setNaNForEmptyBinsFolder: Folder where the setNaNForEmptyBins
        %   function is stored. This variable is important so that MATLAB can
        %   locate the function and use it during the script. 
    % - Variables used to extract the mean amplitude for the desired time
    %   window and channels of interest:
        % - timeWindowArray: The start and end time window for extracting mean
        %   amplitude. 
        % - channelArray: The channel numbers for extracting mean amplitude.
        %   These numbers will vary depending on your montage.
    
% Script Functions:
    % 1. Import each subject's .erp file
    % 2. Export the raw mean amplitude output file (not for analysis)
    % 3. Use setNaNForEmptyBins to export the final mean amplitude output file
    
% Output:
    % - Output mean amplitude .txt files with one mean amplitude per bin
    %   and one file per subject. The value for empty bins have been 
    %   set to NaN. Each file contains the following columns:
        % - startWindow and endWindow: The time window used for extracting
        %   the mean amplitude value. 
        % - value: The mean amplitude for this subject’s specified bin 
        %   and channel. 
        % - channelNumber: The number for this channel in the channel montage
        %   (e.g., 49).
        % - channelLabel: The label for this channel (e.g., PO8).
        % - binNumber: The bin number used to identify the bin in the bin
        %   descriptor file (see the LME_02_CreateBinDescriptorFile.m
        %   script for more information).
        % - binLabel: The bin label used to identify the bin in the bin 
        %   descriptor file (see the LME_02_CreateBinDescriptorFile.m script 
        %   for more information). 
        % - ERPset: The subject's .erp filename. 
        
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

% Specify folder location of ERP data files
importFolder = 'C:\Users\basclab\Desktop\LMETutorial\15_ERPsetFiles';
cd(importFolder) % Change current folder to importFolder
importFiles = dir('*.erp*'); % Make a directory of all .set files in importFolder

% Specify folder location for saving RAW mean amplitude files created
% during step 2
saveOutputFolder_RAW = 'C:\Users\basclab\Desktop\LMETutorial\16_ERPsNC\RawFiles_NotForAnalysis';
% Specify folder location for saving FINAL mean amplitude files created by
% the setNaNForEmptyBins function during step 3
saveOutputFolder_FINAL = 'C:\Users\basclab\Desktop\LMETutorial\16_ERPsNC\FinalFiles';

% Specify folder location of the setNaNForEmptyBins function 
setNaNForEmptyBinsFolder = 'C:\Users\basclab\Desktop\LMETutorial';
addpath(setNaNForEmptyBinsFolder)

% Define variables for mean amplitude extraction: 
% In this tutorial, the NC mean amplitude is extracted over a 300-500 ms
% time window for each of the three following channels (from a
% 64-channel montage High Precision fabric ActiCap):
    % - C3 (channel #8) 
    % - Cz (channel #64)
    % - C4 (channel #24)
timeWindowArray = [300 500];
channelArray = [8 24 64];

%% For each subject: Load .erp file and extract the mean amplitude for each bin/channel
for f = 1:length(importFiles) % Loop through each subject's file
    originalName = importFiles(f).name; % Extract filename
    filename = erase(originalName,".erp"); % Remove .erp from filename
    
    [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
    
%% 1. IMPORT EACH SUBJECT'S .ERP FILE
    ERP = pop_loaderp('filename', originalName, 'filepath', importFolder);
   
%% 2. EXPORT THE RAW MEAN AMPLITUDE OUTPUT FILE (NOT FOR ANALYSIS)
    
    % Create filename for saving the raw mean amplitude .txt file
    saveOutputFilename_RAW = fullfile(saveOutputFolder_RAW, filename);
    
    % Calculate the mean amplitude for each bin over the time window and
    % channels specified above.
    ALLERP = pop_geterpvalues(ERP, timeWindowArray, 1:ERP.nbin, channelArray, ...
        'Baseline', 'pre', 'Binlabel', 'on', 'FileFormat', 'long', ...
        'Filename', saveOutputFilename_RAW, 'Fracreplace', 'NaN', 'IncludeLat', 'yes', ...
        'InterpFactor', 1, 'Measure', 'meanbl', 'PeakOnset', 1, 'Resolution', 3);
    
    % See ERPLAB resource listed above (line 20-24) for more information
    % about the pop_geterpvalues function and adapting the code for
    % extracting a different output measure (e.g., peak amplitude). 
    
%% 3. USE SETNANFOREMPTYBINS TO EXPORT THE FINAL MEAN AMPLITUDE OUTPUT FILE
   
    % Extract the final number of trials assigned to each bin during the
    % LME_04_CalculateERPs.m script. This array does not include any trials
    % that were rejected due to artifacts or boundary events. This array 
    % will be used by the setNaNForEmptyBins function to identify empty bins. 
    acceptedTrialArray = ERP.ntrials.accepted'; 
    
    % The final mean amplitude output file is created and saved within the
    % setNaNForEmptyBins function. The 'mean' argument specifies that we are
    % extracting mean amplitude (vs. peak amplitude). For more information
    % about this function's input arguments, see the setNaNForEmptyBins
    % function. 
    setNaNForEmptyBins(filename, saveOutputFolder_RAW, saveOutputFolder_FINAL, ...
        acceptedTrialArray, 'mean');
    
    clear originalName filename emptyBins saveOutputFilename_RAW
end
clear % Clear variable workspace