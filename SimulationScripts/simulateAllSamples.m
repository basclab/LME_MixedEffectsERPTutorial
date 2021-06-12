% LME Simulation Helper Function: Simulate the Specified Number of Data Samples

% Purpose: This function specifies a neural source chosen from previous
% literature and generates trial-level ERP data for each sample using the
% simulateOneSample function. 

% The lead field, channel montage, channels of interest, and dipole
% location and orientation are specified in this current function. 

% ***See SimulationScripts README.md available on the LME_MixedEffectsERPTutorial 
% GitHub for additional details: https://github.com/basclab/LME_MixedEffectsERPTutorial/tree/main/SimulationScripts 

% Format:
    % simulateAllSamples(sampleN, sampleStart, subjectN, saveFolder)

% Inputs:
    % - sampleN: Number of simulated samples.
    % - sampleStart: Sample ID for first simulated sample (e.g., the first
    %   simulated sample will have an ID of #1).
    % - subjectN: Number of simulated subjects per sample.
    % - saveFolder: Folder for saving simulated data output files.
    %   This parent folder has two subfolders: MeanAmpOutput_PreMerge
    %   and SubjectDataLog, which are used for saving the corresponding
    %   mean amplitude output files and subject data logs (see
    %   simulateOneSample function for more information).  
    
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
    % 1. Define simulation parameters
    % 2. Simulate data for each sample
    
% Output: This function does not output any variables. Instead, the
% simulated mean amplitude and subject data log .txt files are 
% generated and saved in the simulateOneSample function (see function for
% more information).  

% Usage Example:
    % >> sampleN = 50;
    % >> sampleStart = 1;
    % >> subjectN = 50;
    % >> saveFolder = 'C:\Users\basclab\Desktop\LMESimulation';
    % >> simulateAllSamples(sampleN, sampleStart, subjectN, saveFolder) 

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

function simulateAllSamples(sampleN, sampleStart, subjectN, saveFolder)
%% 1. DEFINE SIMULATION PARAMETERS

    % Define the following simulation parameters with the lf_generate_frompha
    % function: 
    % - Lead field: Pediatric Head Atlas release v 1.1, Atlas 1 (0-2 years old)
    % - Channel montage: EGI HydroCel GSN 128-channel montage
    % - Channels of interest: C4 (corresponding to E104 of the HydroCel GSN
    %   montage). An additional channel (C3, corresponding to E36) was also
    %   simulated because the SEREEGA toolbox required simulating 2+ channels.
    leadField   = lf_generate_frompha('0to2','128','labels',{'E36','E104'});

    % Identify the nearest source location to the prefrontal ICA component
    % cluster reported in Reynolds and Richards (2005)
    sourceLocs  = lf_get_source_nearest(leadField, [10 46 18]);

    % Specify a dipole orientation approximated from the projection
    % pattern of the Reynolds and Richards (2005) prefrontal source
    leadField.orientation(sourceLocs,:) = [0.57 -0.70 -0.01];

%% 2. SIMULATE DATA FOR EACH SAMPLE

    % Loop through each of the specified data samples (defined with the
    % sampleStart and sampleN variables)
    for sample = sampleStart:(sampleStart-1+sampleN)

        % Call helper function with specified input arguments (see comments in
        % simulateOneSample function for more information)
        simulateOneSample(sample, subjectN, saveFolder, leadField, sourceLocs);
    end

end