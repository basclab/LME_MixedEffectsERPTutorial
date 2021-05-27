# LME Tutorial Script: 7. Analyze LME Model 

# This script imports a simulated mean amplitude file, induces missing trials in
# the dataset, and fits an linear mixed effects (LME) model to the trial-level 
# dataset. Then casewise deletion is performed (subjects with less than 10 trials/
# emotion condition are removed) and the trial-averaged dataset is used to fit
# an ANOVA model. The estimated marginal means are extracted from each model. 
# This script illustrates the ANOVA's biased estimated marginal means when data 
# is missing at random (MAR) vs. LME's unbiased est. marginal means. 

# The code is adapted from the LMESimulation_03_ExtractModelOutput script saved
# in the LMESimulationScripts folder.

# ***See Appendix D from Heise, Mon, and Bowman (submitted) for additional details. ***

# Requirements: 
  # - filename: One simulated sample's .txt file containing the following columns, 
  #   which are labelled based on the convention that lowercase variables describe 
  #   fixed effects (e.g., emotion) and capital-letter variables describe random 
  #   effects (e.g., SUBJECTID):
    # - SUBJECTID: Simulated subject ID (e.g., 01, 02, ...)
    # - age: Simulated age group (e.g., youngerAgeGroup, olderAgeGroup)
    # - emotion: Simulated emotion condition (i.e., A, B)
    # - ACTOR: Simulated stimulus actor ID (i.e., 1, 2, 3, 4, 5)
    # - presentNumber: Presentation number of specific stimulus (emotion 
    #   condition/actor) ranging from 1 to 10
    # - meanAmpNC: Simulated mean amplitude value (in units of microvolts)
  # - See instructions in step 5 and 6 for specifying the missingness pattern (MAR 
  #   or MCAR) and low trial-count/casewise deleted subjects, respectively

# Script Functions:
  # 1. Define function for inducing missing trials
  # 2. Load simulated data file
  # 3. Fit LME model with trial-level population dataset
  # 4. Fit ANOVA model with averaged population dataset
  # 5. Specify missingness pattern (MCAR or MAR)
  # 6. Induce missing data based on specified missingness pattern and percentage
  #    of low trial-count/casewise deleted subjects
  # 7. Fit LME model with trial-level dataset after inducing trial missingness
  # 8. Casewise delete subjects with less than 10 trials/emotion condition
  # 9. Fit ANOVA model with averaged dataset after inducing trial missingness and 
  #    casewise deleting subjects
  # 10.Plot estimated marginal means for LME and ANOVA models 

# Outputs: 
  # - Estimated marginal means for each emotion condition and model (LME, ANOVA)
  #   for the following datasets:
      # - Population dataset (full dataset without missing trials)
      # - Dataset with the specified level of low trial-count subjects/casewise 
      #   deletion percentage
  # - Plot of the estimated marginal means for each emotion condition/model/dataset

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

library(plyr) # ddply function
library(lme4) # used for creating lme models
library(lmerTest) # used for returning p-value for lme models
library(gsubfn) # list function for assigning multiple outputs
library(data.table) # used for fread function
library(dplyr) # used for select function
library(performance) # check_convergence function
library(afex) # ANOVA analysis
library(emmeans) # extract estimated marginal means
library(car) # needed for contr.Sum
library(ggplot2) # used for plotting

#-----------------------------------------------------------------------
# 1. DEFINE FUNCTION FOR INDUCING MISSING TRIALS

# induceMissingTrials: Function to randomly select subjects with low trial-counts
# who will be casewise deleted prior to ANOVA analysis. In addition, missing
# trials are induced based on the specified probability weights in steps 5 and 6
# below. 
# - Format: 
#     list[dfMissing, subjectCaseDeletion, trialCount] <- induceMissingTrials(dfOriginal, caseDeletionPct) 
# - Inputs:
  # - dfOriginal: Dataframe with the simulated "population" dataset before any
  #   induced missing trial (see header code documentation for more information
  #   about its columns).
  # - caseDeletionPct: A percentage (e.g., 6) used to specify the proportion 
  #   of subjects that will be casewise deleted based on 10 trials/condition threshold
# - Outputs: List containing three elements:
  # - dfMissing: A copy of the dfOriginal after missing trials have been induced. 
  #   Rows with missing trials have a meanAmpNC value of NA.
  # - subjectCaseDeletion: Array of subject IDs that have been randomly selected
  #   for low trial counts/casewise deletion.
  # - trialCount: Long dataframe listing the remaining number of trials per
  #   subject/emotion condition after inducing missing trials. It contains the 
  #   following columns: SUBJECTID, emotion, trialN (see header code documentation
  #   for more information). 
induceMissingTrials <- function(dfOriginal, caseDeletionPct) {
  # Create copy of the dfOriginal dataframe for inducing missing trials
  dfMissing <- data.frame(dfOriginal)
  
  # Extract age probability weights (one weight per subject)
  dfAgeWeight <- aggregate(ageWeight ~ SUBJECTID, dfOriginal, mean, 
                           na.action = na.omit)
  
  # Calculate the number of casewise deleted subjects by multiplying caseDeletionPct
  # by the total number of subjects. If this value is not an integer, the output
  # is rounded up. 
  caseDeletionN <- ceiling((caseDeletionPct/100)*subjectN)
  
  # Randomly sample the subject IDs that will be casewise deleted based on the 
  # specified age weights and the number of casewise deleted subjects
  subjectCaseDeletion <- sample(dfAgeWeight$SUBJECTID, caseDeletionN, 
                                replace = FALSE, prob=dfAgeWeight$ageWeight)
  
  # Calculate the maximum number of trials that can be removed from each condition
  # before the subject is casewise deleted (e.g., if there are 50 trials, a 
  # maximum of 40 trials can be removed for an included (not casewise deleted) subject)
  trialMissingThreshold <- emotionTrialN - 10
  
  # Loop through each subject and randomly select a subset of trials from each
  # condition to remove
  for (subject in dfAgeWeight$SUBJECTID) {
    
    # Generate the number of missing trials to induce for each emotion condition
    if (subject %in% subjectCaseDeletion) { 
      
      # If subject will be casewise deleted, at least one emotion condition will 
      # have less 10 trials remaining.
      trialMissing <- c(sample(x=(trialMissingThreshold+1):emotionTrialN, size = 1),
                        sample(x=0:emotionTrialN, size = emotionN-1, replace = TRUE))                       
    } else { 
      # If subject will not be casewise deleted, all emotion conditions will 
      # have at least 10 trials
      trialMissing <- sample(x=0:trialMissingThreshold, size = emotionN, 
                             replace = TRUE)
    }
    
    # Shuffle order of emotion conditions and then loop through each condition
    # (This line is added so that one condition does not consistently have more
    # missing trials.)
    emotionLabelRand <- sample(emotionLabel)
    for (j in 1:length(emotionLabelRand)) {
      
      emotionTrialMissing <- trialMissing[j] # Extract the number of missing trials for this condition
      
      if (emotionTrialMissing != 0) { # If this emotion condition was not selected to have 0 missing trials
        
        # Find this subject/condition's rows in the dataframe
        subjectIndex <- which(dfMissing$SUBJECTID==subject & dfMissing$emotion==emotionLabelRand[j])
        
        # Extract the presentation number probability weights for this subject/condition
        subjectProbWeight <- dfMissing$presentNumberWeight[subjectIndex]
        
        # Randomly select the missing trials based on the specified probability 
        # weights and the number of missing trials
        subjectIndexMissing <- sample(subjectIndex, emotionTrialMissing, 
                                      replace = FALSE, prob=subjectProbWeight)
        
        # For these missing trials only, replace the meanAmpNC value with NA
        dfMissing[subjectIndexMissing,]$meanAmpNC <- NA
      }
    }
  }
  
  # Save the number of trials remaining for each subject/condition in a dataframe
  trialCount <- ddply(dfMissing, .(SUBJECTID, emotion), summarize, 
                      trialN = sum(!is.na(meanAmpNC)))
  names(trialCount)[3] <- 'trialN' # Update column name to trialN
  
  return(list(dfMissing, subjectCaseDeletion, trialCount)) # Return output variables
}


#-----------------------------------------------------------------------
# 2. LOAD SIMULATED DATA FILE

# Specify filepath of simulated data file
filename <- 'C:/Users/basclab/Desktop/LMETutorial/Sample0443-MeanAmpOutput.txt'

# Import data sample ("population" dataset)
dfOriginal <- fread(filename) 

# Specify desired columns as factors for subsequent analysis 
dfOriginal$ACTOR <- as.factor(dfOriginal$ACTOR)
dfOriginal$SUBJECTID <- as.factor(dfOriginal$SUBJECTID)
dfOriginal$emotion <- as.factor(dfOriginal$emotion)
dfOriginal$age <- as.factor(dfOriginal$age)
# Specify sum coding for the age variable for subsequent ANOVA analysis
contrasts(dfOriginal$age) <- contr.Sum(levels(dfOriginal$age)) 

#-----------------------------------------------------------------------
# 3. FIT LME MODEL WITH TRIAL-LEVEL POPULATION DATASET
# Restricted maximum likelihood (REML) is used to fit all LME models

fit.LMEPop <- lmer(meanAmpNC ~   emotion + presentNumber + age + (1|SUBJECTID) + 
                     (1|ACTOR), data=dfOriginal, REML = TRUE)

# Calculate estimated marginal means for each emotion condition and pairwise 
# comparison. Estimated marginal means are specified at presentation number 5.5 
# and p-values are calculated using the Satterthwaite method. 
mLMEPop <- emmeans::emmeans(fit.LMEPop, pairwise~emotion, mode = "satterthwaite",
                         lmerTest.limit = 240000, at = list(presentNumber = c(5.5)))

# Estimated marginal means for each emotion condition
summary(mLMEPop, infer = c(TRUE, TRUE))$emmeans 

# Estimated marginal means for condition difference pairwise comparison
summary(mLMEPop, infer = c(TRUE, TRUE))$contrasts


#-----------------------------------------------------------------------
# 4. FIT ANOVA MODEL WITH AVERAGED POPULATION DATASET

# Calculate dataset after averaging over trials
dfOriginalAvg <- aggregate(meanAmpNC ~ SUBJECTID + emotion + age, dfOriginal, 
                           mean, na.action = na.omit)

# Fit repeated measures ANOVA model with between-subject factor of age and 
# within-subject factor of emotion 
fit.ANOVAPop <- aov_ez(id = "SUBJECTID", dv = "meanAmpNC", data = dfOriginalAvg, 
                       between = c("age"), within = c("emotion"))

# Calculate estimated marginal means for each emotion condition and pairwise 
# comparison
mANOVAPop <- emmeans::emmeans(fit.ANOVAPop, ~ emotion)

# Estimated marginal means for each emotion condition
summary(mANOVAPop, infer = c(TRUE, TRUE)) 

# Estimated marginal means for condition difference pairwise comparison
summary(pairs(mANOVAPop, infer = c(TRUE, TRUE))) 

#-----------------------------------------------------------------------
# 5. SPECIFY MISSINGNESS PATTERN (MCAR OR MAR)

# Specify probability weight distribution for presentation numbers 6-10 vs.
# 1-5. These weights (e.g., presentNumberWeight6to10 and presentNumberWeight1to5)
# sum to 1 and are used to specify MAR or MCAR missingness.
# - For example, if presentNumberWeight6to10 = 0.7 and presentNumberWeight1to5 = 0.3,
#   then 70% of missing trials belong to presentation numbers 6-10 and 30% of 
#   trials are from presentation numbers 1-5 (MAR missingness).
# - If both weight variables are equal to 0.5, an equal number of missing trials 
#   are drawn from each presentation number (MCAR missingness).
presentNumberWeight6to10 <- 0.7
presentNumberWeight1to5 <- 1-presentNumberWeight6to10

# Calculate the total number of trials per condition for each group of presentation
# numbers (i.e., 6-10 and 1-5). This value is used to scale each individual trial's 
# presentation number weight so that the weights will sum to 1 (see lines 282-284). 
emotionTrialN <- length(unique(dfOriginal$ACTOR)) * length(unique(dfOriginal$presentNumber))  
presentNumberTrials6to10 <- emotionTrialN/2 
presentNumberTrials1to5 <- emotionTrialN/2 

# Specify probability weight distribution for younger vs. older age group. These 
# weights are also used to specify MAR or MCAR missingness (e.g., if 
# ageWeightYounger = 0.7, then 70% of younger subjects are selected for more
# missing trials and subsequent casewise deletion). 
ageWeightYounger <- 0.7
ageWeightOlder <- 1-ageWeightYounger

# Calculate the total number of subjects in the younger and older age groups. This
# value is used to scale each subject's age weight so that the weights will sum to 
# 1 (see lines 285-286).
subjectN <- length(unique(dfOriginal$SUBJECTID))
ageTrialsYounger <- subjectN/2
ageTrialsOlder <- subjectN/2

# Add probability weights based on values specified above. 
dfOriginal$presentNumberWeight <- ifelse(dfOriginal$presentNumber > 5,
                                         (presentNumberWeight6to10/presentNumberTrials6to10), 
                                         (presentNumberWeight1to5/presentNumberTrials1to5))
dfOriginal$ageWeight <- ifelse(dfOriginal$age == 'youngerAgeGroup', 
                               ageWeightYounger/ageTrialsYounger, ageWeightOlder/ageTrialsOlder)


#-----------------------------------------------------------------------
# 6. INDUCE MISSING DATA BASED ON SPECIFIED MISSINGNESS PATTERN AND 
#    PERCENTAGE OF LOW TRIAL-COUNT/CASEWISE DELETED SUBJECTS

# Define variables needed for induceMissingTrials function
emotionLabel <- c("A", "B") # Name of each emotion condition
emotionN <- length(emotionLabel) # Number of emotion conditions

# Specify percentage of subjects with low trial counts who will be casewise deleted
caseDeletionPct <-  6 

# Use induceMissingTrials function to remove trials based on specified missingness
# (step 5) and caseDeletionPct variable
list[dfMissing, subjectCaseDeletion, trialCount] <- induceMissingTrials(dfOriginal,
                                                                        caseDeletionPct) 

#------------------------------------------------------------------------
# 7. FIT LME MODEL WITH TRIAL-LEVEL DATASET AFTER INDUCING TRIAL MISSINGNESS

fit.LMEMis <- lmer(meanAmpNC ~ emotion + presentNumber + age + (1|SUBJECTID) + 
                     (1|ACTOR), data=dfMissing, REML = TRUE)

# As in step 3, calculate estimated marginal means for each emotion condition 
# and pairwise comparison. Estimated marginal means are specified at presentation
# number 5.5 and p-values are calculated using the Satterthwaite method. 
mLMEMis <- emmeans::emmeans(fit.LMEMis, pairwise~emotion, mode = "satterthwaite",
                            lmerTest.limit = 240000, at = list(presentNumber = c(5.5)))

# Estimated marginal means for each emotion condition
summary(mLMEMis, infer = c(TRUE, TRUE))$emmeans 

# Estimated marginal means for condition difference pairwise comparison
summary(mLMEMis, infer = c(TRUE, TRUE))$contrasts

#------------------------------------------------------------------------
# 8. CASEWISE DELETE SUBJECTS WITH LESS THAN 10 TRIALS/EMOTION CONDITION

dfCaseDeletion <- dfMissing[!(dfMissing$SUBJECTID %in% subjectCaseDeletion),]

#------------------------------------------------------------------------
# 9. FIT ANOVA MODEL WITH AVERAGED DATASET AFTER INDUCING TRIAL MISSINGNESS AND
#    CASEWISE DELETING SUBJECTS

# Calculate dataset after averaging over trials
dfCaseDeletionAvg <- aggregate(meanAmpNC ~ SUBJECTID + emotion + age, 
                               dfCaseDeletion, mean, na.action = na.omit)

# Fit repeated measures ANOVA model with between-subject factor of age and 
# within-subject factor of emotion 
fit.ANOVAMis <- aov_ez("SUBJECTID", "meanAmpNC", dfCaseDeletionAvg, between = c("age"),
                       within = c("emotion")) 

# As in step 4, calculate estimated marginal means for each emotion condition 
# and pairwise comparison
mANOVAMis <- emmeans::emmeans(fit.ANOVAMis, ~ emotion)

# Estimated marginal means for each emotion condition
summary(mANOVAMis, infer = c(TRUE, TRUE)) 

# Estimated marginal means for condition difference pairwise comparison
summary(pairs(mANOVAMis, infer = c(TRUE, TRUE))) 

#------------------------------------------------------------------------
# 10. PLOT ESTIMATED MARGINAL MEANS FOR LME AND ANOVA MODELS

# Create separate dataframes with estimated marginal means for each model/
# population and percentage of low trial-count/casewise deleted subjects
margMeansLMEPop <- summary(mLMEPop)$emmeans
margMeansLMEPop$modelType <- 'LME'
margMeansLMEPop$caseDeletionPct <- 'Pop.'

margMeansANOVAPop <- summary(mANOVAPop)
margMeansANOVAPop$modelType <- 'ANOVA'
margMeansANOVAPop$caseDeletionPct <- 'Pop.'

margMeansLMEMis <- summary(mLMEMis)$emmeans
margMeansLMEMis$modelType <- 'LME'
margMeansLMEMis$caseDeletionPct <- paste0(caseDeletionPct, '%')

margMeansANOVAMis <- summary(mANOVAMis)
margMeansANOVAMis$modelType <- 'ANOVA'
margMeansANOVAMis$caseDeletionPct <- paste0(caseDeletionPct, '%')

# Combine above dataframes into one variable
dfMargMeansSummary <- rbind(margMeansLMEPop, margMeansANOVAPop,
                            margMeansLMEMis, margMeansANOVAMis)

# Specify order of factor variables for plotting
dfMargMeansSummary$modelType <- factor(dfMargMeansSummary$modelType, 
                                       levels = c('LME', 'ANOVA'))
dfMargMeansSummary$caseDeletionPct <- factor(dfMargMeansSummary$caseDeletionPct, 
                                             levels = c('Pop.', paste0(caseDeletionPct, '%'))) 

modelColors <- c('#e66101','#5e3c99') # Specify LME and ANOVA colors for graph
ggplot(dfMargMeansSummary, aes(x=caseDeletionPct, y=emmean, color=modelType)) +
  geom_errorbar(ymin = (dfMargMeansSummary$lower.CL), 
                ymax = (dfMargMeansSummary$upper.CL), 
                width = 0.2, size = .7, alpha = .8,
                position=position_dodge(width=0.09)) +
  facet_grid(cols = vars(emotion)) +
  geom_point(size = 1, position=position_dodge(width=0.09)) + 
  scale_x_discrete(name="Percentage of Low Trial-Count/Casewise Deleted Subjects") +
  scale_y_continuous(name="Model Means for Simulated NC Mean Amplitude (µV)", 
                     limits=c(-15, 7)) +
  scale_color_manual("Model", values = modelColors) + 
  theme_bw() 
