% LME Tutorial Helper Function: Set Empty Bin Output to NaN

% Purpose: This function imports a raw .txt file outputted by the
% pop_geterpvalues function (see the LME_05_MeasureERPs.m script).
% Then, empty bins (i.e., bins that do not contain any data) are
% identified and their output value set to NaN. Finally, the function
% saves the final .txt file in the desired folder. 

% NOTE: This function has been tested with exported peak amplitude and mean
% amplitude output files. Exporting other types of output values (e.g.,
% peak latency) may require adapting the column information specified in
% lines 77-83.

% ***See Appendix D from Heise, Mon, and Bowman (2022) for additional details. ***

% Format:
    % setNaNForEmptyBins(filename, rawFolderName, finalFolderName, acceptedTrialArray, outputMeasurement)

% Inputs:
    % - filename: Name of the raw text file created by the pop_geterpvalues
    %   function. The output for empty bins have NOT been set to NaN yet. 
    % - rawFolderName: Folder location of the raw .txt files. 
    % - finalFolderName: Folder location for saving the final output .txt
    %   files after converting the output value of empty bins to NaN.
    % - acceptedTrialArray: Array listing the number of trials assigned to each
    %   bin. This array does not include any trials that were rejected due to
    %   artifacts or boundary events (i.e., event markers signifying discontinuities
    %   in the data file).
    % - outputMeasurement: String specifying whether the output .txt file
    %   contains exported peak amplitude ("peak") or mean amplitude ("mean") 
    %   values. See above note in lines 9-12 about modifying the function for  
    %   other output values (e.g., peak latency). 
    
% Other Requirements:
    % - Needs MATLAB R2019a
    
% Output: This function does not output any variables. However, the final
% .txt file (with empty bins' output updated to NaN) is saved at the end 
% of the function. 

% Usage example:
    % >> filename = 'Sub-001-1_EEBP_example.txt';
    % >> saveOutputFolder_RAW = 'C:\Users\basclab\Desktop\LMETutorial\16_ERPsNC\RawFiles_NotForAnalysis';
    % >> saveOutputFolder_FINAL = 'C:\Users\basclab\Desktop\LMETutorial\16_ERPsNC\FinalFiles';
    % >> acceptedTrialArray = ERP.ntrials.accepted';
    % >> setNaNForEmptyBins(filename, saveOutputFolder_RAW, saveOutputFolder_FINAL, ...
    % >>    acceptedTrialArray, 'mean');

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

function setNaNForEmptyBins(filename, rawFolderName, finalFolderName, acceptedTrialArray, outputMeasurement)
    % Import specified raw output file
    filepath = fullfile(rawFolderName, filename);
    outputFile = readtable(filepath);
    
    % Specify column names for the output file. This information will vary
    % depending if peak amplitude or mean amplitude was extracted.
    if strcmp(outputMeasurement,'peak') 
        outputFile.Properties.VariableNames = {'peakTimepoint','value','channelNumber',...
            'channelLabel','binNumber','binLabel','ERPset'};
    elseif strcmp(outputMeasurement,'mean')
        outputFile.Properties.VariableNames = {'startWindow','endWindow','value','channelNumber',...
            'channelLabel','binNumber','binLabel','ERPset'};
    end

    % Identify bins that have 0 accepted trials (i.e., empty bins)
    emptyBinName = find(acceptedTrialArray == 0); 
    
    % Find the indices for these empty bins in the output data file
    emptyBinIdx = ismember(outputFile.binNumber, emptyBinName);
    
    % Set the output of these empty bins to NaN 
    outputFile.value(emptyBinIdx) = NaN;

    % For peak amplitude output files only, the peak latency is also set to NaN
    if strcmp(outputMeasurement,'peak') 
        outputFile.peakTimepoint(emptyBinIdx) = {'NaN'};
    end
   
    % Update filename to indicate that this is the final output file
    filename = erase(filename,".txt");
    updatedFilename = strcat(filename,'_final.txt');
    
    % Save the final output file in the desired output folder 
    writetable(outputFile,fullfile(finalFolderName, updatedFilename));
end