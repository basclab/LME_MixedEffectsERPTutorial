% LME Simulation Helper Function: Simulate One Data Sample

% Purpose: This function simulates a trial-level ERP data file for each subject
% in a sample. Then, all subjects' ERP files are concatenated into one file
% and the mean amplitude for the channel of interest (C4) and time window 
% (300-500 ms) is extracted for each subject and trial-specific bin. In
% addition, a subject data log file is created, which lists each subject's
% assigned age group. 

% NOTE: Compared to the LME_05_MeasureERPs.m tutorial script, subjects' ERP
% files are concatenated so that mean amplitude values can be exported for 
% all subjects in one file in long format. This step reduces processing
% time but ERPLAB will also adjust the bin numbers and labels accordingly
% (see Outputs section below for more information). In addition, the 
% setNaNForEmptyBins function is not required when exporting data because
% missing trials have not been generated at this step of the simulation yet. 

% In this function, actor intercepts are drawn from a normal
% distribution. In addition, subjects are assigned to an age group
% (younger or older) and given a corresponding age intercept. Note that
% intercept values are added to the peak amplitude of the waveform. These
% peak amplitude values were chosen to produce a specific mean amplitude 
% value when extracted over a 300-500 ms time window. For example, the
% older age group has a peak amplitude intercept of 118 �V, which
% corresponds to a mean amplitude of -2.002 �V over a 300-500 ms time window. 

% ***See SimulationScripts README.md available on the LME_MixedEffectsERPTutorial 
% GitHub for additional details: https://github.com/basclab/LME_MixedEffectsERPTutorial/tree/main/SimulationScripts 

% Format:
    % simulateOneSample(sampleN, subjectN, saveFolder, leadField, sourceLocs)

% Inputs:
    % - sampleN: Number of simulated samples.
    % - subjectN: Number of simulated subjects/sample.
    % - saveFolder: Folder for saving simulated data output files.
    %   This parent folder has two subfolders: MeanAmpOutput_PreMerge
    %   and SubjectDataLog, which are used for saving the corresponding
    %   mean amplitude output files and subject data logs (see
    %   Outputs section below for more information).  
    % - leadField: Data structure created in the simulateAllSamples
    %   function for specifying the lead field, channel montage, channel
    %   of interest, and dipole orientation.
    % - sourceLocs: Index used to identify the dipole location from the
    %   leadField structure. This variable was created in the
    %   simulateAllSamples function.
    
% Other Requirements:
    % - Needs EEGLAB v 2019_0, ERPLAB v 8.01, SEREEGA v 1.1.0
        % - For more information on EEGLAB, see: Delorme, A. & Makeig, S. (2004).
        %   EEGLAB: An open source toolbox for analysis of single-trial EEG dynamics.
        %   https://sccn.ucsd.edu/eeglab/index.php
        % - For more information on ERPLAB, see: Lopez-Calderon, J., & Luck, S. J.
        %   (2014). ERPLAB: An open-source toolbox for the analysis of event-related
        %   potentials. https://erpinfo.org/erplab/    
        % - For more information on SEREEGA, see: Krol, L. R., Pawlitzki, J., Lotte, F.,
        %   Gramann, K., & Zander, T. O. (2018). SEREEGA: Simulating event-related EEG
        %   activity. https://github.com/lrkrol/SEREEGA
    % - Pediatric Head Atlas release v 1.1, Atlas 1 (0-2 years old) files
        % - Atlas files should be requested and downloaded from: https://www.pedeheadmod.net/pediatric-head-atlases/
        % - The folder containing the atlas files should then be added
        %   to the MATLAB path (via "Home" > "Set Path" > "Add with Subfolders"). 
        
% Function Steps:
    % 1. Specify output filenames and other variables
    % 2. Define simulation parameters
    % 3. Simulate each subject's ERP file
    % 4. Export this sample's mean amplitude output file 
    % 5. Export this sample's subject data log 
    % 6. (Optional) Export this sample's .erp file

% Outputs:
    % - Mean amplitude .txt files with one mean amplitude value per bin/
    %   channel/subject. There is one file for each simulated sample.
    %   Each file contains the following columns:
        % - value: The mean amplitude for this simulated subject�s specified
        %   bin and channel. This value is extracted from C4 (corresponding 
        %   to E104 of the EGI HydroCel GSN 128-channel montage) over a 
        %   300-500 ms time window. 
        % - chindex: The channel number (e.g., channel #2 corresponds to 
        %   E104 in this simulation).
        % - chlabel: The label for this channel (e.g., E104).
        % - bini: A number generated by ERPLAB when concatenating ERP
        %   data files across each sample's subjects. NOTE: This bin number
        %   does NOT correspond to the bin number in the bin descriptor
        %   file (created in LMESimulation_01_CreateBinDescriptorFile.m)
        %   and is NOT used for subsequent processing. 
        % - binlabel: A label composed of [SUBJECTID]_:_[trial-specific bin label].
        %   The trial-specific bin label corresponds to the labels from the
        %   bin descriptor file (created in LMESimulation_01_CreateBinDescriptorFile.m).
        %   This label is used to identify subject ID and stimuli-related information in
        %   LMESimulation_03_OrganizeDataFiles.R. 
        % - ERPset: This column is intentionally empty because it is NOT needed 
        %   for identifying subject ID (see binlabel column above). 
    % - Subject data log .txt files with one row corresponding to each subject.
    %   There is one file for each simulated sample. Each file contains the 
    %   following columns:
        % - SUBJECTID: Simulated subject ID (e.g., 01, 02, �).
        % - age: Simulated age group (e.g., youngerAgeGroup, olderAgeGroup).
    % - (Optional) .erp files containing the trial-level waveforms for all
    %   subjects in a sample. There is one file for each simulated sample
    %   and they are saved directly in the saveFolder specified above (not
    %   in a subfolder). These files are useful for visualizing waveforms
    %   or troubleshooting. 

% Usage Example:
    % >> sample = 1;
    % >> subjectN = 50;
    % >> saveFolder = 'C:\Users\basclab\Desktop\LMESimulation';
    % >> leadField = lf_generate_frompha('0to2','128','labels',{'E36','E104'});
    % >> sourceLocs = lf_get_source_nearest(leadField, [10 46 18]);
    % >> leadField.orientation(sourceLocs,:) = [0.57 -0.70 -0.01];
    % >> simulateOneSample(sample, subjectN, saveFolder, leadField, sourceLocs);
    
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

function simulateOneSample(sampleN, subjectN, saveFolder, leadField, sourceLocs)
%% 1. SPECIFY OUTPUT FILENAMES AND OTHER VARIABLES

    % Specify filenames for output files: mean amplitude file, subject data
    % log, and (optional) .erp file. The mean amplitude filename includes 
    % 'PreMerge' to signify that the file does not contain age group
    % information yet (this information is added by the
    % LMESimulation_03_OrganizeDataFiles_20210526.R script). 
    saveSampleFilename = strcat('Sample', sprintf('%04d',sampleN)); % Format sample ID with leading zeros
    saveSampleMeanAmpFilename = strcat(saveFolder, '\MeanAmpOutput_PreMerge\', saveSampleFilename, '-MeanAmpOutput_PreMerge.txt'); 
    saveSampleSubjectDataLogFilename = strcat(saveFolder, '\SubjectDataLog\', saveSampleFilename, '-SubjectDataLog.txt');
    saveSampleERPFilename = strcat(saveSampleFilename, '.erp');
    
    % Create ALLERP structure for storing all subjects' ERP files
    ALLERP = buildERPstruct([]);
    
    % Define variables for mean amplitude extraction: 
    % In this simulation, the NC mean amplitude is extracted over a 300-500 ms
    % time window for C4 (channel #2).
    timeWindowArray = [300 500];
    channelArray = [2];

%% 2. DEFINE SIMULATION PARAMETERS 

    % Define parameters for actor intercepts:
    % Each actor has a normal distribution with one of the following mean and 
    % standard deviation values (e.g., actor 01's normal distribution has a 
    % mean of 589 and standard deviation of 295; actor 02's has a mean of
    % 295 and standard deviation of 295, and so on).
    actorInt = [589, 295, 0, -295, -589]; % Peak amplitude population mean for each actor intercept distribution (one distribution/actor; values correspond to mean amplitude of [-9.995, -5.006, 0, 5.006, 9.995] in units of �V)
    actorSD = 295; % Peak amplitude population standard deviation for all actor intercept distributions (corresponds to mean amplitude of 5.006 �V)

    % Generate actor intercepts for this sample by randomly selecting one value
    % per actor. Each subject in this sample will have the same 5 actor intercepts.
    % These values are added to the subject's peak amplitude in the
    % simulateOneSubject function below. 
    sampleActorIntArray = [normrnd(actorInt(1),actorSD), normrnd(actorInt(2),actorSD), ...
        normrnd(actorInt(3),actorSD), normrnd(actorInt(4),actorSD), ...
        normrnd(actorInt(5),actorSD)];

    % Define age intercepts for the older and younger age group. These values
    % are constant for all simulated samples (e.g., a subject in the older age 
    % group will always have an increment of -2.002 �V). Each subject's age
    % intercept is added to their peak amplitude in the simulateOneSubject
    % function below. 
    ageInt = [118, -118]; % Peak amplitude (corresponds to mean amplitude of -2.002 and 2.002 �V for older and younger group, respectively)
    subjectNHalf = subjectN/2; % Number of subjects assigned to each age group (we define subjectN as even in LMESimulation_02_SimulateERPData.m)
    sampleAgeIntArray_Original = repelem(ageInt, subjectNHalf); % Create age intercept array of length subjectN (NOTE: This array is not randomized yet)
    sampleAgeIntArray = datasample(sampleAgeIntArray_Original, subjectN, 'Replace',false); % Randomized age intercept array

%% 3. SIMULATE EACH SUBJECT'S ERP FILE

    for subject = 1:subjectN % Loop through each simulated subject
        sampleAgeInt_OneSubject = sampleAgeIntArray(subject); % Extract this subject's age intercept 
        ERP = simulateOneSubject(sampleActorIntArray, sampleAgeInt_OneSubject, leadField, sourceLocs); % Generate this subject's ERP data file 
        ALLERP(subject) = ERP; % Store this subject's ERP file in the ALLERP structure
    end

%% 4. EXPORT THIS SAMPLE'S MEAN AMPLITUDE OUTPUT FILE

    % Concatenate all simulated subjects' ERP data files into one ERP file
    ERP = pop_appenderp(ALLERP , 'Erpsets', [1:subjectN],'Prefixes',cellstr(pad(string(1:subjectN),2,'left','0')));
    
    % Calculate the mean amplitude for each bin over the time window and
    % channels specified above and save in .txt file
    ERP = pop_geterpvalues(ERP, timeWindowArray, [1:ERP.nbin], channelArray , ...
        'Baseline', 'pre', 'FileFormat', 'long', ...
        'Filename', saveSampleMeanAmpFilename, 'Fracreplace', 'NaN', 'InterpFactor',  1, ...
        'Measure', 'meanbl', 'PeakOnset',  1, 'Resolution',  3, 'Binlabel', 'on' );
    
%% 5. EXPORT THIS SAMPLE'S SUBJECT DATA LOG

    % Create string array of all subject IDs
    SUBJECTID = pad(string(1:subjectN),2,'left','0')';

    % Create string array indicating each subject's assigned age group
    age = strings(1, subjectN)';
    age(sampleAgeIntArray == ageInt(1)) = 'olderAgeGroup';
    age(sampleAgeIntArray == ageInt(2)) = 'youngerAgeGroup';

    % Combine subject IDs and assigned age groups into one table and save
    % as .txt file
    subjectDataLog = table(SUBJECTID, age);
    writetable(subjectDataLog,saveSampleSubjectDataLogFilename);
    
%% 6. (OPTIONAL) EXPORT THIS SAMPLE'S .ERP FILE
    
    % Uncomment the line below to save the concatenated .erp file containing
    % all subjects' trial-level waveforms    
    % ERP = pop_savemyerp(ERP, 'erpname', saveSampleERPFilename, 'filename', saveSampleERPFilename, 'filepath', saveFolder);

end