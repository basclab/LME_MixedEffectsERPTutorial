% LME Simulation Helper Function: Simulate One Subject's ERP Data File

% Purpose: This function simulates an ERP data file for one subject. The file
% contains trial-level ERP waveforms that have been generated for 100 trials
% consisting of 2 emotion conditions and 5 different 'actors' (with 10
% presentations each). 

% In this function, the following simulation parameters are specified:
% epoch window, sampling rate, presentation number of each stimulus,
% emotion peak amplitude and latency, subject peak amplitude intercept
% and latency shift, trial-level noise amplitude, and event marker
% preceding codes. 

% Note that peak amplitude values were chosen to produce a specific mean 
% amplitude value when extracted over a 300-500 ms time window. For example, 
% emotion A has a peak amplitude of 589 µV, which corresponds to a mean 
% amplitude of -9.995 µV over a 300-500 ms time window. 

% Note that sections of this function are adapted from the LME tutorial
% scripts. For more information, see comments below in steps 4-6.

% ***See SimulationScripts README.md available on the LME_MixedEffectsERPTutorial 
% GitHub for additional details: https://github.com/basclab/LME_MixedEffectsERPTutorial/tree/main/SimulationScripts 

% Format:
    % ERP = simulateOneSubject(sampleActorIntArray, sampleAgeInt_OneSubject, leadField, sourceLocs)

% Inputs:
    % - sampleActorIntArray: Array of actor intercepts randomly generated in
    %   the simulateOneSample function. The first value corresponds to the
    %   intercept for actor 01, the second value corresponds to actor 02, etc.
    % - sampleAgeInt_OneSubject: Age intercept for this subject's assigned
    %   age group. This value was created in the simulateOneSample
    %   function.
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
    % - Filepath to the following file used during processing:
        % - binDescriptorFilename: File specifying each bin's number, label, 
        %   and 5-digit event markers. This file is created by the
        %   LMESimulation_01_CreateBinDescriptorFile.m script. 
        
% Function Steps:
    % 1. Define simulation parameters
    % 2. Define functions for generating ERP and noise signal classes
    % 3. Generate trial-level waveforms with parameters and functions from steps 1-2
    % 4. Update event marker preceding codes with presentation number
    % 5. Extract bin-based epochs
    % 6. Calculate trial-level ERPs

% Outputs:
    % - ERP: ERP file containing the subject's trial-level waveforms.

% Usage Example:
    % >> sampleActorIntArray = [747.6118, 835.9961, -646.3598, -40.6589, -494.9643];
    % >> sampleAgeInt_OneSubject = 118;
    % >> leadField = lf_generate_frompha('0to2','128','labels',{'E36','E104'});
    % >> sourceLocs = lf_get_source_nearest(leadField, [10 46 18]);
    % >> leadField.orientation(sourceLocs,:) = [0.57 -0.70 -0.01];
    % >> ERP = simulateOneSubject(sampleActorIntArray, sampleAgeInt_OneSubject, leadField, sourceLocs)

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

function ERP = simulateOneSubject(sampleActorIntArray, sampleAgeInt_OneSubject, leadField, sourceLocs)
%% 1. DEFINE SIMULATION PARAMETERS 

    % Specify filepath of bin descriptor file
    binDescriptorFilename = 'C:\Users\basclab\Desktop\LMESimulation\LMESimulation_BinDescriptorFile.txt';

    % Define parameters for simulated epoch window 
    preStimPeriod = 200; % Pre-stimulus/baseline period (ms)
    postStimPeriod = 600; % Post-stimulus period (ms)
    samplingRate = 250; % Sampling rate (Hz)

    % Define parameters for presentation of each emotion condition/actor
    presentN = 10; % Number of presentations of each stimulus (emotion condition/actor)
    presentNumberArray = repmat(pad(string(1:presentN),2,'left','0')',presentN,1); % Create a string array with values 1, 2, ..., presentN

    % Create epoch structure based on above parameters: each stimulus is
    % presented 10 times, data is sampled at 250 Hz, and the epoch consists of
    % a 200 ms pre-stimulus period and 600 ms post-stimulus period.
    epochs = struct('n', presentN, 'srate', samplingRate, 'length', preStimPeriod+postStimPeriod,'prestim',preStimPeriod);

    % Define parameters for each emotion condition (A and B):
    % For each trial, the emotion condition's peak amplitude value is drawn 
    % from a normal distribution with the following mean and standard 
    % deviation values.
    emotionIntArray = [589, 707]; % Peak amplitude population mean for each emotion condition distribution (one distribution/condition; values correspond to mean amplitude of -9.995 and -11.997 µV for A and B, respectively)
    emotionDv = 295*3; % Peak amplitude deviation (defined as 3*standard deviation where a peak amplitude standard deviation of 295 corresponds to a mean amplitude standard deviation of 5.006 µV)
    emotionSlope = -795; % Peak amplitude slope (i.e., change in amplitude with each successive presentation). This value corresponds to a mean amplitude increase of 1.499 µV.
    emotionPeakLatency = 600; % Peak latency (400 ms post-stimulus)
    emotionPeakWindow = 200; % Window length (i.e., a window of 300-500 ms has a length of 200 ms)

    % Define parameters for each subject:
    % For the subject's peak amplitude intercept, one value is drawn from a
    % normal distribution with the following parameters. This amplitude
    % intercept is then added to the subject's peak amplitude. 
    subjectMean = 0; % Peak amplitude population mean for subject intercept distribution
    subjectSD = 589; % Peak amplitude population standard deviation for subject intercept distribution (corresponds to mean amplitude of 9.995 µV)
    % For the subject's peak latency shift, one value is drawn from the
    % following array using a uniform sampling distribution and used to
    % shift the subject's waveform. This latency shift is constant across
    % all trials and corresponds to a minimal mean amplitude difference
    % between subjects (ranging from -0.02 to 0.06 µV). 
    subjectPeakLatencyShiftArray = [-20 20]; 
    
    % Specify number of unique actors (based on sampleActorIntArray input argument)
    actorN = length(sampleActorIntArray);

    % Specify each stimulus' 3-digit preceding code used for creating event  
    % markers. Each preceding code corresponds to one emotion condition and actor. 
    % The first digit (e.g., 6) corresponds to the emotion condition (e.g., A)
    % and the last two digits correspond to the actor ID. For more
    % information, see the LMESimulation_EventMarkerMappingKey.xlsx spreadsheet
    emotionPrecCodes = ["601", "602", "603", "604", "605", "301", "302", "303", "304", "305"];
    % NOTE: The above array is ordered based on emotion condition such that all
    % markers starting with "6" belong to emotion condition A and are listed
    % first. Markers starting with "3" belong to emotion B and are listed
    % second. This is important for ensuring that the correct emotion condition
    % population mean is assigned in step 3.
    
    % Define amplitude of pink Gaussian noise (corresponds to trial-level
    % mean amplitude noise that are normally distributed with a mean of
    % approximately 0 µV and a standard deviation of 3 µV). 
    noiseAmplitude = 246; 

%% 2. DEFINE FUNCTIONS FOR GENERATING ERP AND NOISE SIGNAL CLASSES

    % Anonymous function to generate an ERP "signal class" with the specified
    % peak amplitude and latency. The signal class is then used by the
    % generate_scalpdata function to simulate trial-level waveforms.  
    % - Inputs:
        % - emotionPeakAmplitude: Peak amplitude summed over the amplitude values
        %   for emotion condition population mean, subject intercept, actor intercept, 
        %   and age intercept. 
        % - subjectPeakLatencyWithShift: Peak latency summed over the default peak
        %   latency for this component (i.e., emotionPeakLatency) and the subject's
        %   peak latency shift (i.e., a value drawn from the subjectPeakLatencyShiftArray).   
        % - Other variables (e.g., emotionPeakWindow) are defined above and held
        %   constant for all simulated subjects. 
    % - Output: 
        % - ERP signal class with the specified parameters. 
    erp = @(emotionPeakAmplitude, subjectPeakLatencyWithShift) ...
        utl_check_class(struct( ...
        'type', 'erp', ...
        'peakLatency', subjectPeakLatencyWithShift, ...
        'peakWidth', emotionPeakWindow, ...
        'peakAmplitude', emotionPeakAmplitude, ...
        'peakAmplitudeSlope', emotionSlope, ...
        'peakAmplitudeDv', emotionDv, ...
        'peakLatencyDv', 0, ...
        'peakLatencyShift', 0));

    % Anonymous function to generate a pink Gaussian noise "signal class" 
    % with the specified amplitude. The noise signal class is then combined  
    % with the ERP signal class and used by the generate_scalpdata function  
    % to simulate trial-level waveforms.  
    % - Input: This function does not require any inputs. The noise amplitude
    %   is defined above and held constant for all simualted subjects. 
    % - Output: 
        % - Noise signal class with the specified parameters. 
    noise = @() ...
        utl_check_class(struct( ...
        'type', 'noise', ...
        'amplitude', noiseAmplitude, ... 
        'amplitudeDv', 0, ... 
        'color', 'pink'));

%% 3. GENERATE TRIAL-LEVEL WAVEFORMS WITH PARAMETERS AND FUNCTIONS FROM STEPS 1-2

    % Randomly select this subject's peak amplitude intercept from a normal distribution with above parameters
    subjectIncrementInt = normrnd(subjectMean,subjectSD); 
    
    % Generate peak amplitude array with one value for each unique stimulus
    % (emotion condition/actor). Each value consists of the sum of the emotion
    % condition population mean, actor intercept, subject intercept, and age
    % intercept. (NOTE: While the emotion condition and actor intercept
    % varies by stimulus, the subject and age intercepts do not.) 
        % - For example, the first value of subjectEmotionModelInt is the sum
        %   of the peak amplitudes for emotion condition A + actor 01 + subject
        %   intercept + age intercept. The second value is the sum of emotion
        %   A + actor 02 + subject intercept + age intercept, and so on. 
        % - The emotionDv deviation (based on the emotion condition population
        %   standard deviation) is taken into account later with the erp function.
    subjectEmotionModelInt = repelem(emotionIntArray,actorN) + repmat(sampleActorIntArray, 1, length(emotionIntArray)) + repmat(subjectIncrementInt,1,presentN) + repmat(sampleAgeInt_OneSubject,1,presentN);
    
    % Randomly select this subject's peak latency shift from the array
    % specified above and add it to the emotionPeakLatency variable (used
    % to define the peak latency of this subject's waveform)
    subjectPeakLatencyWithShift = emotionPeakLatency + randi(subjectPeakLatencyShiftArray,1,1); 

    % Simulate the first stimulus' 10 trial-level waveforms (corresponding to
    % 10 presentations/stimulus). The waveform's amplitude reduces with 
    % each unique presentation based on the emotionSlope variable. 
    v = 1; % Counter variable indexing subjectEmotionModelInt
    % Define a component consisting of a neural source, dipole orientation and signal (ERP + noise)
    componentTemp1 = struct('source', sourceLocs, ... 
        'signal', {{erp(subjectEmotionModelInt(v),subjectPeakLatencyWithShift), ...
        noise()}});
    % Validate the component structure
    componentTemp1 = utl_check_component(componentTemp1, leadField);
    % Simulate the trial-level waveforms with the specified component,
    % leadfield, and epoch structure
    dataTemp1 = generate_scalpdata(componentTemp1, leadField, epochs, 'showprogress', 0);
    % Format the simulated data as an EEGLAB .set file and add the
    % corresponding event marker preceding code (e.g., 601)
    EEGTemp1 = utl_create_eeglabdataset(dataTemp1, epochs, leadField, ...
        'marker', convertStringsToChars(emotionPrecCodes(v)));

    % Repeat this process for the next unique stimulus until trial-level
    % waveforms for all 10 unique stimuli have been simulated
    v = 2;
    componentTemp2 = struct('source', sourceLocs, ...
        'signal', {{erp(subjectEmotionModelInt(v),subjectPeakLatencyWithShift), ...
        noise()}});
    componentTemp2 = utl_check_component(componentTemp2, leadField);
    dataTemp2 = generate_scalpdata(componentTemp2, leadField, epochs, 'showprogress', 0);
    EEGTemp2 = utl_create_eeglabdataset(dataTemp2, epochs, leadField, ...
        'marker', convertStringsToChars(emotionPrecCodes(v)));
    EEG1 = pop_mergeset(EEGTemp1,EEGTemp2); % Merge the two EEG .set files together (note that pop_mergeset only accepts two input arguments at a time)

    v = 3;
    componentTemp3 = struct('source', sourceLocs, ...
        'signal', {{erp(subjectEmotionModelInt(v),subjectPeakLatencyWithShift), ...
        noise()}});
    componentTemp3 = utl_check_component(componentTemp3, leadField);
    dataTemp3 = generate_scalpdata(componentTemp3, leadField, epochs, 'showprogress', 0);
    EEGTemp3 = utl_create_eeglabdataset(dataTemp3, epochs, leadField, ...
        'marker', convertStringsToChars(emotionPrecCodes(v)));
    EEG2 = pop_mergeset(EEG1,EEGTemp3);

    v = 4;
    componentTemp4 = struct('source', sourceLocs, ...
        'signal', {{erp(subjectEmotionModelInt(v),subjectPeakLatencyWithShift), ...
        noise()}});
    componentTemp4 = utl_check_component(componentTemp4, leadField);
    dataTemp4 = generate_scalpdata(componentTemp4, leadField, epochs, 'showprogress', 0);
    EEGTemp4 = utl_create_eeglabdataset(dataTemp4, epochs, leadField, ...
        'marker', convertStringsToChars(emotionPrecCodes(v)));
    EEG3 = pop_mergeset(EEG2,EEGTemp4);

    v = 5;
    componentTemp5 = struct('source', sourceLocs, ...
        'signal', {{erp(subjectEmotionModelInt(v),subjectPeakLatencyWithShift), ...
        noise()}});
    componentTemp5 = utl_check_component(componentTemp5, leadField);
    dataTemp5 = generate_scalpdata(componentTemp5, leadField, epochs, 'showprogress', 0);
    EEGTemp5 = utl_create_eeglabdataset(dataTemp5, epochs, leadField, ...
        'marker', convertStringsToChars(emotionPrecCodes(v)));
    EEG4 = pop_mergeset(EEG3,EEGTemp5);

    v = 6;
    componentTemp6 = struct('source', sourceLocs, ...
        'signal', {{erp(subjectEmotionModelInt(v),subjectPeakLatencyWithShift), ...
        noise()}});
    componentTemp6 = utl_check_component(componentTemp6, leadField);
    dataTemp6 = generate_scalpdata(componentTemp6, leadField, epochs, 'showprogress', 0);
    EEGTemp6 = utl_create_eeglabdataset(dataTemp6, epochs, leadField, ...
        'marker', convertStringsToChars(emotionPrecCodes(v)));
    EEG5 = pop_mergeset(EEG4,EEGTemp6);

    v = 7;
    componentTemp7 = struct('source', sourceLocs, ...
        'signal', {{erp(subjectEmotionModelInt(v),subjectPeakLatencyWithShift), ...
        noise()}});
    componentTemp7 = utl_check_component(componentTemp7, leadField);
    dataTemp7 = generate_scalpdata(componentTemp7, leadField, epochs, 'showprogress', 0);
    EEGTemp7 = utl_create_eeglabdataset(dataTemp7, epochs, leadField, ...
        'marker', convertStringsToChars(emotionPrecCodes(v)));
    EEG6 = pop_mergeset(EEG5,EEGTemp7);

    v = 8;
    componentTemp8 = struct('source', sourceLocs, ...
        'signal', {{erp(subjectEmotionModelInt(v),subjectPeakLatencyWithShift), ...
        noise()}});
    componentTemp8 = utl_check_component(componentTemp8, leadField);
    dataTemp8 = generate_scalpdata(componentTemp8, leadField, epochs, 'showprogress', 0);
    EEGTemp8 = utl_create_eeglabdataset(dataTemp8, epochs, leadField, ...
        'marker', convertStringsToChars(emotionPrecCodes(v)));
    EEG7 = pop_mergeset(EEG6,EEGTemp8);

    v = 9;
    componentTemp9 = struct('source', sourceLocs, ...
        'signal', {{erp(subjectEmotionModelInt(v),subjectPeakLatencyWithShift), ...
        noise()}});
    componentTemp9 = utl_check_component(componentTemp9, leadField);
    dataTemp9 = generate_scalpdata(componentTemp9, leadField, epochs, 'showprogress', 0);
    EEGTemp9 = utl_create_eeglabdataset(dataTemp9, epochs, leadField, ...
        'marker', convertStringsToChars(emotionPrecCodes(v)));
    EEG8 = pop_mergeset(EEG7,EEGTemp9);

    v = 10;
    componentTemp10 = struct('source', sourceLocs, ...
        'signal', {{erp(subjectEmotionModelInt(v),subjectPeakLatencyWithShift), ...
        noise()}});
    componentTemp10 = utl_check_component(componentTemp10, leadField);
    dataTemp10 = generate_scalpdata(componentTemp10, leadField, epochs, 'showprogress', 0);
    EEGTemp10 = utl_create_eeglabdataset(dataTemp10, epochs, leadField, ...
        'marker', convertStringsToChars(emotionPrecCodes(v)));
    EEG = pop_mergeset(EEG8,EEGTemp10); % Finish merging all of the waveforms together

    EEG = epoch2continuous(EEG); % Concatenate all of the epochs into a continuous dataset

%% 4. UPDATE EVENT MARKER PRECEDING CODES WITH PRESENTATION NUMBER

    % This step's code is adapted from the LME_01_AddUniqueFlags.m script 
    % and streamlined because trials are always simulated in the order 
    % specified by the emotionPrecCodes array. 

    allEventTypes = {EEG.event.type}'; % Extract the subject's event markers (consisting of 3-digit preceding codes) 
    nonBoundaryEventIdx = ~strcmp(allEventTypes, "boundary"); % Locate non-boundary event markers (i.e., event markers from the emotionPrecCodes array)
    % Update the event marker name with the presentation number (e.g., convert
    % the first instance of 601 to 60101; convert the second instance of 601 to
    % 60102, etc.)
    allEventTypes(nonBoundaryEventIdx) = strcat(allEventTypes(nonBoundaryEventIdx), cellstr(presentNumberArray));
    [EEG.event.type] = deal(allEventTypes{:}); % Update the subject's event marker array with the final 5-digit event markers
    EEG = eeg_checkset(EEG, 'eventconsistency'); % Check EEG event array for inconsistencies (e.g., event markers out of order) 

%% 5. EXTRACT BIN-BASED EPOCHS

    % This step's code is adapted from the LME_03_BinBasedEpoch.m script. 
    % The main change is that the EventList is not saved during the 
    % pop_binlister function. 

    % Create EventList
    EEG  = pop_creabasiceventlist(EEG, 'AlphanumericCleaning', 'on', 'BoundaryNumeric', {-99}, 'BoundaryString', {'boundary'} );

    % Assign events to bins
    EEG  = pop_binlister(EEG, 'BDF', binDescriptorFilename, 'IndexEL',  1, 'SendEL2', 'EEG', 'UpdateEEG', 'off', 'Voutput', 'EEG','Report','off');

    % Extract bin-based epochs and baseline correct
    EEG = pop_epochbin(EEG, [-preStimPeriod  postStimPeriod],  'pre');

%% 6. CALCULATE TRIAL-LEVEL ERPS

    % This step's code is adapted from the LME_04_CalculateERPs.m script.
    % The main change is that the simulated subject's ERP data file is
    % not saved. Instead, the ERP variable is outputted into the simulateOneSample
    % function and the trial level data is exported at the sample level (i.e., one
    % text file containing mean amplitude values for all subjects). 

    ERP = pop_averager(EEG , 'Criterion', 'good', 'DQ_flag', 1, 'ExcludeBoundary', 'off', 'SEM', 'on');

end