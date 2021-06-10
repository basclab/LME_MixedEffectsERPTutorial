# LME Simulation Script: 3. Organize Data Files

# This script is modified from the LME_06_OrganizeDataFiles.R tutorial script to 
# import the mean amplitude .txt file for one simulated sample (instead of one 
# subject). Then, subject ID and stimuli-related information for each trial are 
# extracted from the bin label and saved in the corresponding dataframe column.

# Compared to the tutorial example, the bin label column is formatted as 
# [SUBJECTID]_:_[trial-specific bin label] with the following components
# (e.g., 01_:_30101):
  # - The first two digits of the label is the subject ID (e.g., 01)
  # - The first digit after the _:_ is the emotion condition (e.g., 3)
  # - The next two digits are the actor ID (e.g., 01)
  # - The last two digits are the presentation number (e.g., 01, first presentation)

# Finally, the sample's subject data log is merged with the dataframe and the
# final dataframe is saved as a .csv file.

# ***See SimulationScripts README.md available on the LME_MixedEffectsERPTutorial 
# GitHub for additional details: https://github.com/basclab/LME_MixedEffectsERPTutorial/tree/main/SimulationScripts 

# Requirements: 
  # - importParentFolder: Folder containing two subfolders used for saving 
  #   simulated files: MeanAmpOutput_PreMerge (contains mean amplitude output
  #   files) and SubjectDataLog (contains logs of each subject's assigned age
  #   group).
  # - saveFolder: Folder for saving the merged dataframe containing each subject's
  #   mean amplitude output, assigned age group, and stimuli-related information for
  #   each trial. The dataframe is saved as a .csv file at the end of the script.

# Script Functions:
  # 1. Import each sample's mean amplitude .txt file 
  # 2. Extract subject ID and stimuli-related information for each row
  # 3. Import each sample's subject data log .txt file and merge with 
  #    the dataframe
  # 4. Save final long dataframe as a .csv file

# Outputs: 
  # - Each sample will have a .csv file formatted as a long dataframe with the 
  #   following columns. Column names are formatted based on the convention that
  #   lowercase variables describe fixed effects (e.g., emotion) and capital-letter variables
  #   describe random effects (e.g., SUBJECTID).
    # - SUBJECTID: Simulated subject ID (e.g., 01, 02, ...)
    # - age: Simulated age group (e.g., youngerAgeGroup, olderAgeGroup)
    # - emotion: Simulated emotion condition (i.e., A, B)
    # - ACTOR: Simulated stimulus actor ID (i.e., 1, 2, 3, 4, 5)
    # - presentNumber: Presentation number of specific stimulus (emotion 
    #   condition/actor) ranging from 1 to 10
    # - meanAmpNC: Simulated mean amplitude value (in units of microvolts)

# Copyright 2021 Megan J. Heise, Serena K. Mon, Lindsay C. Bowman
# Brain and Social Cognition Lab, University of California Davis, Davis, CA, USA.

# Permission is hereby granted, free of charge, to any person obtaining a 
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense, 
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included 
# in all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

library(data.table) # fread function
library(dplyr) # select function
library(stringr) # str_sub function
#------------------------------------------------------------------------
# DATA ENVIRONMENT

# Specify folder location of simulated output files
importParentFolder='C:/Users/basclab/Desktop/LMESimulation'
# Create variables corresponding to each subfolder
importMeanAmpFolder = paste0(importParentFolder, '/MeanAmpOutput_PreMerge')
importSubjectDataLogFolder = paste0(importParentFolder, '/SubjectDataLog')

# Make directory of all .txt files in importMeanAmpFolder
meanAmpDir = list.files(path = importMeanAmpFolder, pattern = ".txt", full.names = TRUE, recursive = FALSE)

# Specify folder location for saving each sample's long dataframe
saveFolder='C:/Users/basclab/Desktop/LMESimulation/MeanAmpOutput_Final'

#------------------------------------------------------------------------
# For each simulated sample: Format mean amplitude output file, merge with 
# subject data log file, and export final dataframe as .csv file

for (meanAmpFile in meanAmpDir) { # Loop through each sample
  # Extract sample ID number from filename (e.g., extract '0001' from
  # 'C:/Users/basclab/Desktop/LME_Simulation/MeanAmpOutput_PreMerge/Sample0001-MeanAmpOutput_PreMerge.txt')
  sampleNum <- str_sub(meanAmpFile,-31,-28)
  # Create filename for final dataframe
  saveFilename = paste0(saveFolder, '/Sample', sampleNum, '-MeanAmpOutput.csv')
  
# 1. IMPORT EACH SAMPLE'S MEAN AMPLITUDE .TXT FILE 
  
  importCol <- c("value", "binlabel") # Specify columns for import
  dfOriginalRaw <- fread(meanAmpFile, select=importCol)
  
# 2. EXTRACT SUBJECT ID AND STIMULI-RELATED INFORMATION FOR EACH ROW
  
  dfOriginalRaw$SUBJECTID <- substr(dfOriginalRaw$binlabel,1,2) # Extract subject ID (e.g., 01)
  dfOriginalRaw$eventBin <- substr(dfOriginalRaw$binlabel,6,10) # Extract bin label (e.g., 30101)
  dfOriginalRaw$emotion <- substr(dfOriginalRaw$eventBin,1,1) # Extract emotion condition ID (e.g., 3)
  dfOriginalRaw$ACTOR <- as.factor(substr(dfOriginalRaw$eventBin,3,3)) # Extract actor ID (e.g., 01)
  dfOriginalRaw$presentNumber <- as.numeric(substr(dfOriginalRaw$eventBin,4,5)) # Extract presentation number (e.g, 01)
  
  dfOriginalRaw$emotion <- as.factor(ifelse(dfOriginalRaw$emotion == '3', 'B', 'A')) # Convert emotion condition ID (e.g., 3) to a label (e.g., "B")
  dfOriginalRaw$meanAmpNC <- dfOriginalRaw$value # Create a column named meanAmpNC for export
  
# 3. IMPORT EACH SAMPLE'S SUBJECT DATA LOG .TXT FILE AND MERGE WITH THE DATAFRAME
  
  subjectDataLog <- fread(paste0(importSubjectDataLogFolder,'/Sample',sampleNum,'-SubjectDataLog.txt'), colClasses=c(SUBJECTID="character"))
  dfOriginalRaw <- merge(dfOriginalRaw, subjectDataLog, by = "SUBJECTID")
  
  dfOriginal <-  select(dfOriginalRaw, -(c(value, eventBin, binlabel))) # Remove columns not needed for export

# 4. SAVE FINAL LONG DATAFRAME AS A .CSV FILE
  
  dfOriginal <- dfOriginal[, c(1, 6, 2, 3, 4, 5)] # Reorder columns
  fwrite(dfOriginal, file = saveFilename, row.names = FALSE) # Save long dataframe in desired folder
  
}
