# LME Tutorial Script: 7. Analyze LME Model 

# This script imports a simulated mean amplitude file and induces missing trials
# based on the specified missingness pattern (e.g., more missing data in later 
# trials and in younger subjects) and percentage of subjects with low trial-count 
# (e.g., 6% of subjects are induced to have less than 10 trials/condition 
# remaining). Then, a linear mixed effects (LME) model is fitted to the 
# trial-level dataset. Next, casewise deletion is performed (subjects with less
# than 10 trials/emotion condition are removed) and the trial-averaged dataset 
# is used to fit an ANOVA model. Estimated marginal means are extracted for each
# emotion condition and model. This script illustrates the ANOVA's biased 
# estimated marginal means when data is not missing completely at random vs. LME's 
# unbiased estimated marginal means. 

# The code is modified from the LMESimulation_04_ExtractModelOutput script saved
# in the SimulationScripts folder. To adapt the script for your experiment design,
# the LME and ANOVA model formulas can be modified (e.g., to include three emotion
# conditions, model age as a covariate, etc.). 

# ***See Appendix D from Heise, Mon, and Bowman (submitted) for additional details. ***

# Requirements: 
  # - Needs R Version 3.6.1 and packages listed in lines 83-93
  # - filename: One simulated sample's .csv file containing the following columns, 
  #   which are labelled based on the convention that lowercase variables describe 
  #   fixed effects (e.g., emotion) and capital-letter variables describe random 
  #   effects (e.g., SUBJECTID):
    # - SUBJECTID: Simulated subject ID (e.g., 01, 02, ...)
    # - age: Simulated age group (i.e., youngerAgeGroup, olderAgeGroup)
    # - emotion: Simulated emotion condition (i.e., A, B)
    # - ACTOR: Simulated stimulus actor ID (i.e., 01, 02, 03, 04, 05)
    # - presentNumber: Presentation number of specific stimulus (emotion 
    #   condition/actor) ranging from 1 to 10
    # - meanAmpNC: Simulated NC mean amplitude value (in units of microvolts)
  # - See instructions in steps 5 and 6 for specifying the missingness pattern 
  #   (more missing data in later trials and/or in younger subjects or data
  #   missing completely at random (MCAR)) and percentage of subjects with low
  #   trial-count, respectively.

# Script Functions:
  # 1. Define function for inducing missing trials
  # 2. Load simulated data file
  # 3. Fit LME model with trial-level population dataset
  # 4. Fit ANOVA model with averaged population dataset
  # 5. Specify missingness pattern 
  # 6. Induce missing data based on specified missingness pattern and percentage
  #    of subjects with low trial-count
  # 7. Fit LME model with trial-level dataset after inducing trial missingness
  # 8. Casewise delete subjects with less than 10 trials/emotion condition
  # 9. Fit ANOVA model with averaged dataset after inducing trial missingness and 
  #    casewise deleting subjects
  # 10.Plot estimated marginal means for LME and ANOVA models 

# Outputs: 
  # - Estimated marginal means for each emotion condition and model (LME, ANOVA)
  #   fitted to the following datasets:
      # - Population dataset (full dataset without missing trials)
      # - Dataset with the specified percentage of subjects with low trial-count
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

# Load required packages
library(plyr) # V.1.8.6; ddply function
library(lme4) # V.1.1-25; used for creating lme models
library(lmerTest) # V.3.1-3; used for returning p-value for lme models
library(gsubfn) # V.0.7; list function for assigning multiple outputs
library(data.table) # V.1.13.2; fread function
library(dplyr) # V.1.0.2; select function
library(performance) # V.0.6.1; check_convergence function
library(afex) # V.0.28-1; ANOVA analysis
library(emmeans) # V.1.5.3; extract estimated marginal means
library(car) # V.3.0-10; contr.sum function
library(ggplot2) # V.3.3.2; used for plotting
#-----------------------------------------------------------------------
# 1. DEFINE FUNCTION FOR INDUCING MISSING TRIALS

# induceMissingTrials: Function to randomly select subjects for inducing
# low trial counts and subsequent casewise deletion prior to ANOVA analysis. 
# In addition, missing trials are induced based on the specified probability
# weights from step 5 below. 
# - Format: 
#     list[dfMissing, subjectCaseDeletion, trialCount] <- induceMissingTrials(dfOriginal, caseDeletionPct) 
# - Inputs:
  # - dfOriginal: Dataframe with the simulated "population" dataset before any
  #   induced missing trials (see Outputs section at the top of the script for
  #   more information). 
  # - caseDeletionPct: Percent of subjects with low trial-count (i.e., less than
  #   10 trials/condition).
# - Outputs: List containing three elements:
  # - dfMissing: A copy of the dfOriginal after missing trials have been induced. 
  #   Rows with missing trials have a meanAmpNC value of NA.
  # - subjectCaseDeletion: Array of subject IDs that have been randomly selected
  #   for low trial counts.
  # - trialCount: Long dataframe listing the remaining number of trials per
  #   subject and emotion condition after inducing missing trials. It contains the 
  #   following columns: SUBJECTID, emotion, trialN (see Outputs section at the
  #   top of the script for more information). 
induceMissingTrials <- function(dfOriginal, caseDeletionPct) {
  # Create copy of the dfOriginal dataframe for inducing missing trials
  dfMissing <- data.frame(dfOriginal)
  
  # Extract age probability weights (one weight per subject)
  dfAgeWeight <- aggregate(ageWeight ~ SUBJECTID, dfOriginal, mean, 
                           na.action = na.omit)
  
  # Calculate the number of low trial-count subjects by multiplying caseDeletionPct
  # by the total number of subjects. If this value is not an integer, the output
  # is rounded up. 
  caseDeletionN <- ceiling((caseDeletionPct/100)*subjectN)
  
  # Randomly sample the subject IDs that will have low trial-counts based on the 
  # specified age weights and the caseDeletionN variable
  subjectCaseDeletion <- sample(dfAgeWeight$SUBJECTID, caseDeletionN, 
                                replace = FALSE, prob=dfAgeWeight$ageWeight)
  
  # Calculate the maximum number of trials that can be removed from each condition
  # before the subject is considered to have a low trial-count and would be
  # casewise deleted (e.g., if there are 50 trials, a maximum of 40 trials can
  # be removed for an included (i.e., not casewise deleted) subject)
  trialMissingThreshold <- emotionTrialN - 10
  
  # Loop through each subject and randomly select a subset of trials from each
  # condition to remove
  for (subject in dfAgeWeight$SUBJECTID) {
    
    # Generate the number of missing trials to induce for each emotion condition.
    # NOTE: If the number of emotion conditions is not 2, the trialMissing variable
    # must be modified accordingly.  
    if (subject %in% subjectCaseDeletion) { 
      
      # For subjects with a low trial-count, at least one emotion condition will 
      # have less than 10 trials remaining
      trialMissing <- c(sample(x=(trialMissingThreshold+1):emotionTrialN, size = 1),
                        sample(x=0:emotionTrialN, size = emotionN-1, replace = TRUE))                       
    } else { 
      # For subjects who do NOT have a low trial-count, all emotion conditions
      # will have at least 10 trials
      trialMissing <- sample(x=0:trialMissingThreshold, size = emotionN, 
                             replace = TRUE)
    }
    
    # Shuffle order of emotion conditions and then loop through each condition
    # (This line is added so that one condition does not consistently have more
    # missing trials due to how the trialMissing variable is defined for subjects
    # with low trial-count.)
    emotionLabelRand <- sample(emotionLabel)
    for (j in 1:length(emotionLabelRand)) {
      
      emotionTrialMissing <- trialMissing[j] # Extract the number of missing trials for this condition
      
      if (emotionTrialMissing != 0) { # If this emotion condition was not selected to have 0 missing trials
        
        # Find this subject and condition's rows in the dataframe
        subjectIndex <- which(dfMissing$SUBJECTID==subject & dfMissing$emotion==emotionLabelRand[j])
        
        # Extract the presentation number probability weights for this subject and condition
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
  
  # Save the number of trials remaining for each subject and condition in a dataframe
  trialCount <- ddply(dfMissing, .(SUBJECTID, emotion), summarize, 
                      trialN = sum(!is.na(meanAmpNC)))
  names(trialCount)[3] <- 'trialN' # Update column name to trialN
  
  return(list(dfMissing, subjectCaseDeletion, trialCount)) # Return output variables
}

#-----------------------------------------------------------------------
# 2. LOAD SIMULATED DATA FILE

# Specify filepath of simulated data file
filename <- 'C:/Users/basclab/Desktop/LMETutorial/Sample0443-MeanAmpOutput.csv'

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

fit.LMEPop <- lmer(meanAmpNC ~ emotion + age + presentNumber + (1|SUBJECTID) + 
                     (1|ACTOR), data=dfOriginal, REML = TRUE)

# Calculate estimated marginal means for each emotion condition and pairwise 
# comparison. Estimated marginal means are specified at presentation number 5.5 
# (i.e., the average presentation number simulated in the dataset) and p-values
# are calculated using the Satterthwaite method. 
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

# Fit repeated measures ANOVA model with between-subjects factor of age and 
# within-subjects factor of emotion 
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
# 5. SPECIFY MISSINGNESS PATTERN 

set.seed(20210329) # Specify seed for reproducible results

# Specify probability weight distribution for presentation numbers 6-10 vs.
# 1-5. These weights (i.e., presentNumberWeight6to10 and presentNumberWeight1to5)
# sum to 1 and are used to specify missingness pattern for the within-subjects 
# effect. 
# - For example, if presentNumberWeight6to10 = 0.7 and presentNumberWeight1to5 = 0.3,
#   then 70% of missing trials are from presentation numbers 6-10 and 30% of 
#   trials are from presentation numbers 1-5.
# - If both weight variables are equal to 0.5, an equal number of missing trials 
#   are drawn from each presentation number (MCAR).
presentNumberWeight6to10 <- 0.7
presentNumberWeight1to5 <- 1-presentNumberWeight6to10

# Calculate the total number of trials per condition for each group of presentation
# numbers (i.e., presentation numbers 6-10 and 1-5). This value is used to scale each  
# individual trial's presentation number weight so that the weights will sum to 1
# (see lines 298-300). 
emotionTrialN <- length(unique(dfOriginal$ACTOR)) * length(unique(dfOriginal$presentNumber))  
presentNumberTrials6to10 <- emotionTrialN/2 
presentNumberTrials1to5 <- emotionTrialN/2 

# Specify probability weight distribution for younger vs. older age group. These 
# weights are used to specify missingness pattern for the between-subjects
# effect (e.g., if ageWeightYounger = 0.7, then 70% of subjects selected for more
# missing trials and subsequent casewise deletion were from the younger age group).
ageWeightYounger <- 0.7
ageWeightOlder <- 1-ageWeightYounger

# Calculate the total number of subjects in the younger and older age groups. This
# value is used to scale each subject's age weight so that the weights will sum to 
# 1 (see lines 301-302).
subjectN <- length(unique(dfOriginal$SUBJECTID))
ageTrialsYounger <- subjectN/2
ageTrialsOlder <- subjectN/2

# Create probability weight columns for presentation number and age group based
# on values specified above
dfOriginal$presentNumberWeight <- ifelse(dfOriginal$presentNumber > 5,
                                         (presentNumberWeight6to10/presentNumberTrials6to10), 
                                         (presentNumberWeight1to5/presentNumberTrials1to5))
dfOriginal$ageWeight <- ifelse(dfOriginal$age == 'youngerAgeGroup', 
                               ageWeightYounger/ageTrialsYounger, ageWeightOlder/ageTrialsOlder)

#-----------------------------------------------------------------------
# 6. INDUCE MISSING DATA BASED ON SPECIFIED MISSINGNESS PATTERN AND 
#    PERCENTAGE OF SUBJECTS WITH LOW TRIAL-COUNT

# Define variables needed for induceMissingTrials function
emotionLabel <- c("A", "B") # Name of each emotion condition
emotionN <- length(emotionLabel) # Number of emotion conditions

# Specify percent of subjects with low trial-count who will be casewise deleted
caseDeletionPct <-  6 

# Use induceMissingTrials function to remove trials based on specified missingness
# (step 5) and caseDeletionPct variable
list[dfMissing, subjectCaseDeletion, trialCount] <- induceMissingTrials(dfOriginal,
                                                                        caseDeletionPct) 

#------------------------------------------------------------------------
# 7. FIT LME MODEL WITH TRIAL-LEVEL DATASET AFTER INDUCING TRIAL MISSINGNESS

fit.LMEMis <- lmer(meanAmpNC ~ emotion + age + presentNumber + (1|SUBJECTID) + 
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

# Calculate trial-averaged dataset
dfCaseDeletionAvg <- aggregate(meanAmpNC ~ SUBJECTID + emotion + age, 
                               dfCaseDeletion, mean, na.action = na.omit)

# Fit repeated measures ANOVA model with between-subjects factor of age and 
# within-subjects factor of emotion 
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

# Create separate dataframes with estimated marginal means for each LME and 
# ANOVA model
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
  scale_x_discrete(name="Percent of Subjects with Low Trial-Count") +
  scale_y_continuous(name="Model Means for Simulated NC Mean Amplitude (µV)", 
                     limits=c(-15, 7)) +
  scale_color_manual("Model", values = modelColors) + 
  theme_bw() 