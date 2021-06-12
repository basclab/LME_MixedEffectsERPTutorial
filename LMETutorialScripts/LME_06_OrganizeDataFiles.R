# LME Tutorial Script: 6. Organize Data Files

# This script imports each subject's mean amplitude .txt file and creates 
# one dataframe in long format (each row corresponds to one subject/channel/bin).
# Then, stimuli-related information for each trial is extracted from the bin label
# and saved in the corresponding dataframe column (e.g., if the bin label begins
# with "6", then "Happy" is assigned to the "Emotion" column for that row). 

# In this example, the bin label is equal to the unique 5-digit event markers 
# generated during the LME_01_AddUniqueFlags.m script (see file for more
# information). The 5-digit code is constructed of the following components
# (e.g., 30101):
  # - The first digit is the emotion condition (e.g., 3)
  # - The next two digits are the actor ID (e.g., 01)
  # - The last two digits are the presentation number (e.g., 01, first presentation)

# ***See Appendix D from Heise, Mon, and Bowman (submitted) for additional details. ***

# Requirements: 
  # - importFolder: Folder containing mean amplitude output .txt files created 
  #   during the LME_05_MeasureERPs.m script. There is one file per subject.
  # - saveLongDFFolder: Folder for saving the long dataframe (containing all 
  #   subjects' data) as a .csv file at the end of the script.

# Script Functions:
  # 1. Import each subject's mean amplitude .txt file and merge into a long
  #    dataframe
  # 2. Format dataframe and extract stimuli-related information for each row
  # 3. Save the long dataframe as a .csv file

# Outputs: 
  # - One .csv file formatted as a long dataframe with the following columns. 
  #   Column names are formatted based on the convention that lowercase
  #   variables describe fixed effects (e.g., emotion) and capital-letter variables
  #   describe random effects (e.g., SUBJECTID).
    # - SUBJECTID: Subject ID (e.g., 01, 02, ...)
    # - CHANNEL: Electrode channel (e.g., Cz)
    # - emotion: Emotion condition (i.e., Angry, Fear, Happy, Neutral)
    # - ACTOR: Stimulus actor (e.g., 01, 02, ...)
    # - presentNumber: Presentation number of a specific stimulus (emotion condition/
    #   actor). In this tutorial, this variable ranged from 1 to 10. 
    # - meanAmpNC: Mean amplitude value (in units of microvolts). 

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

library(data.table) # fwrite function
library(plyr) # revalue function
#-----------------------------------------------------------------------
# DATA ENVIRONMENT

# Specify folder location of mean amplitude .txt files
importFolder <- 'C:/Users/basclab/Desktop/LMETutorial/16_ERPsNC/FinalFiles/'

# Make directory of all .txt files in importFolder
fileDir <- list.files(path = importFolder, pattern = ".txt", full.names = TRUE, 
                     recursive = FALSE)

# Specify folder location and filename for saving long dataframe
saveFolderPath <- 'C:/Users/basclab/Desktop/LMETutorial'
saveFilename <- paste0(saveFolderPath,'/MeanAmpNC_LongDF.csv')

#------------------------------------------------------------------------
# 1. IMPORT EACH SUBJECT'S MEAN AMPLITUDE .TXT FILE AND MERGE INTO A LONG
#    DATAFRAME

# Create empty data frame for storing all subjects' data. 
allSubjectsDF <- data.frame(character(0))

for (filename in fileDir) { # Loop through each subject's file 
  print(filename)
  
  # Import subject's file as a long dataframe (the read.csv function is used
  # because the .txt file is formatted as comma delimited file)
  oneSubjectDF <- read.csv(filename)
  
  # Extract subject ID from the ERPset column (e.g., if the value was 
  # "Sub-001-1_EEBP_example.erp", the subject ID extracted was "01")
  oneSubjectDF$SUBJECTID <- substr(oneSubjectDF$ERPset,6,7)
  
  # Concatenate this subject's dataframe with the final long dataframe for all 
  # subjects
  allSubjectsDF <- rbind(allSubjectsDF, oneSubjectDF)
}

#------------------------------------------------------------------------
# 2. FORMAT DATAFRAME AND EXTRACT STIMULI-RELATED INFORMATION FOR EACH ROW

# Remove bins 1-5 (these bins are aggregated over individual trials and are 
# not needed for LME analysis)
allSubjectsDF_subset <- allSubjectsDF[which(allSubjectsDF$binNumber > 5),]

# Remove rows with an NaN value (corresponding to empty bins, see the
# LME_05_MeasureERPs.m script and the setNaNForEmptyBins function for
# more information)
allSubjectsDF_subset <- allSubjectsDF_subset[which(allSubjectsDF_subset$value !='NaN'), ]

# Extract stimuli-related information from the 5-digit event markers:
# - Extract emotion condition from the marker's first digit
allSubjectsDF_subset$emotion <- substr(allSubjectsDF_subset$binLabel,1,1)

# - Extract actor ID from the marker's next two digits 
allSubjectsDF_subset$ACTOR <- substr(allSubjectsDF_subset$binLabel,2,3)

# - Extract presentation number from the marker's last two digits 
allSubjectsDF_subset$presentNumber <- substr(allSubjectsDF_subset$binLabel,4,5)

# Create a meanAmpNC column for exporting mean amplitude values
allSubjectsDF_subset$meanAmpNC <- allSubjectsDF_subset$value 

# Create a column named "CHANNEL" based on lab naming conventions 
# (random effects are capital-letter variables)
allSubjectsDF_subset$CHANNEL <- allSubjectsDF_subset$channelLabel

# Convert emotion condition ID (e.g., 3) to a descriptive label (e.g., "Angry")
allSubjectsDF_subset$emotion <- revalue(allSubjectsDF_subset$emotion, 
                                        c("3"="Angry", "5"="Fear", 
                                          "6"="Happy", "8"="Neutral"))

#------------------------------------------------------------------------
# 3. SAVE THE LONG DATAFRAME AS A .CSV FILE

# Specify the columns that we want to save in the exported file
column <- c("SUBJECTID","CHANNEL", "emotion","ACTOR",
               "presentNumber","meanAmpNC")
allSubjectsDF_final <- allSubjectsDF_subset[, column]

# Save long dataframe in desired folder
fwrite(allSubjectsDF_final, file = saveFilename, row.names = FALSE)