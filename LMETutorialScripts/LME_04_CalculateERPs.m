% LME Tutorial Script: 4. Calculate ERPs

% This script extracts trial-level and average ERPs based on bins assigned
% during the LME_03_BinBasedEpoch.m script. 

% Each trial-level ERP corresponds to an ERP waveform time-locked to a specific
% presentation of a stimulus. For overarching bins that include all trials
% within each condition (e.g., Angry), the average ERP is calculated over all 
% of the trials within a condition. For the "all conditions" bin, every trial 
% across every condition is averaged. 

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
        % - importFolder: Folder containing epoched .set files. Epochs 
        %   containing artifacts (e.g., identified with a voltage threshold)
        %   have also been marked in the file. 
        % - saveERPFolder: Folder for saving .erp files. 
       
% Script Functions:
    % 1. Import each subject's epoched .set file
    % 2. Compute trial-level and averaged ERPs 
    % 3. Save subject's .erp file
    
% Output:
    % - Processed .erp files containing the trial-level and averaged ERPs
    %   (one file per subject)
    
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

% Specify folder location of epoched data. Epochs containing artifacts have
% been marked in each subject's dataset. 
importFolder = 'C:\Users\basclab\Desktop\LMETutorial\14_EpochedArtifactMarked';
cd(importFolder) % Change current folder to importFolder
importFiles = dir('*.set*'); % Make a directory of all .set files in importFolder

% Specify folder location for saving ERP data files
saveERPFolder = 'C:\Users\basclab\Desktop\LMETutorial\15_ERPsetFiles';

%%  For each subject: Load .set file and perform steps for calculating average ERPs
for f = 1:length(importFiles) % Loop through each subject's file
    originalName = importFiles(f).name; % Extract filename
    filename = erase(originalName,".set"); % Remove .set from filename
    
    [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
    
%% 1. IMPORT EACH SUBJECT'S EPOCHED .SET FILE
    EEG = pop_loadset('filename', originalName, 'filepath', importFolder);
    [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, 0);
       
%% 2. CALCULATE TRIAL-LEVEL AND AVERAGED ERPS
    fprintf('Subject %s: Calculate ERPs \n\n', filename);
    
    % The ‘Criterion’ and 'good' arguments specify that artifact-containing
    % epochs should be removed from the dataset before calculating ERPs.
    % The 'ExcludeBoundary' argument specifies that boundary-containing epochs 
    % are also removed. 
    ERP = pop_averager(EEG , 'Criterion', 'good', 'DQ_flag', 1, 'ExcludeBoundary', 'on', 'SEM', 'on');

%% 3. SAVE SUBJECT'S .ERP FILE
    erpName = strcat(filename,'.erp'); % Update filename with an .erp extension
    ERP = pop_savemyerp(ERP, 'erpname', filename, 'filename', erpName, 'filepath', saveERPFolder);

    clear originalName filename erpName
end
clear % Clear variable workspace