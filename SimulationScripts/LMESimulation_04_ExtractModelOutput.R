# LME Simulation Script: 4. Extract Model Output

# This script imports each simulated data sample's mean amplitude file and 
# induces missing trials based on the specified missingness pattern 
# (e.g., more missing data in later trials and in younger subjects) and 
# percentage of subjects with low trial-count (e.g., 6% of subjects are induced
# to have less than 10 trials/condition remaining). Then, an linear mixed 
# effects (LME) model is fitted to the trial-level dataset. Next, casewise 
# deletion is performed (subjects with less than 10 trials/emotion condition
# are removed) and the trial-averaged dataset is used to fit an ANOVA model. 
# Estimated marginal means are extracted for each emotion condition and model. 

# In addition, step 5 provides an example of a power calculation based
# on the percentage of linear effects models that detected the effect of interest 
# (e.g., condition difference).

# To adapt the script for your experiment design and simulation parameters, 
# code from step 1 ("Define Simulation-Level Variables") and the LME and ANOVA 
# model formulas can be modified (e.g., to include three emotion conditions, 
# simulate age as a covariate, etc.). 

# ***See SimulationScripts README.md available on the LME_MixedEffectsERPTutorial 
# GitHub for additional details: https://github.com/basclab/LME_MixedEffectsERPTutorial/tree/main/SimulationScripts 

# Requirements: 
  # - importFolder: Folder containing formatted .csv files created during 
  #   LMESimulation_03_OrganizeDataFiles.R. Each .csv file is imported as the 
  #   dfOriginal variable and contains the following columns, which are labeled  
  #   based on the convention that lowercase variables describe fixed effects
  #   (e.g., emotion) and capital-letter variables describe random effects 
  #   (e.g., SUBJECTID).
      # - SUBJECTID: Simulated subject ID (e.g., 01, 02, ...)
      # - age: Simulated age group (i.e., youngerAgeGroup, olderAgeGroup)
      # - emotion: Simulated emotion condition (i.e., A, B)
      # - ACTOR: Simulated stimulus actor ID (i.e., 01, 02, 03, 04, 05)
      # - presentNumber: Presentation number of specific stimulus (emotion 
      #   condition/actor) ranging from 1 to 10
      # - meanAmpNC: Simulated mean amplitude value (in units of microvolts)
  # - saveFolder: Folder for saving the output files (see below) from the script. 
  # - See instructions in step 1 for specifying the original simulation 
  #   parameters from the MATLAB scripts (e.g., number of subjects per sample)
  #   The following parameters are also specified in step 1: missingness
  #   pattern (more missing data in later trials and/or in younger subjects or 
  #   data missing completely at random (MCAR)) and percentage of subjects with
  #   low trial-count.

# Script Functions:
  # 1. Define simulation-level variables
  # 2. Define functions for inducing missing trials and extracting model output
  # 3. Import simulated data files and run functions to induce missing trials and 
  #    fit LME and ANOVA models
  # 4. Save output files
  # 5. (Optional) Calculate power of LME model

# Outputs: 
  # - modelOutput: One .csv file formatted as a long dataframe with the following
  #   columns. Output values are extracted from LME and ANOVA models for the 
  #   population dataset (i.e., no missing trials) and for each of the specified 
  #   percentages of subjects with low trial-count (see caseDeletionPct column below).
    # - emotion: Emotion condition label (i.e., A, B) or the condition 
    #   difference pairwise comparison (A - B) 
    # - estimate: Estimated marginal mean 
    # - SE: Standard error
    # - df: The degrees of freedom calculated using the Satterthwaite method
    # - lower.CL: Lower limit of the 95% confidence interval
    # - upper.CL: Upper limit of the 95% confidence interval
    # - t.ratio: Test statistic
    # - p.value: P-value calculated using the Satterthwaite method
    # - inCL: Binary value indicating whether the 95% confidence interval of
    #   the estimated marginal mean contains the true population value
    # - modelProblem: For ANOVA models, this value is always "none". For LME 
    #   models, this value is "none" if the model converged/did not have 
    #   singular fit, "notConverge" if the model did not converge, or 
    #   "singularFit" if the model had singular fit.
    # - modelType: String indicating whether modelInput is an "LME" model or an
    #   "ANOVA" model
    # - caseDeletionPct: Percent of subjects with less than 10 trials/condition that
    #   were casewise deleted prior to ANOVA analysis. 0% indicates that missing 
    #   trials were induced but no subjects were casewise deleted (all subjects 
    #   met the 10 trials/condition threshold). Pop. indicates no missing trial 
    #   and no casewise deletion.
    # - sample: The simulated data sample ID (e.g., 1)
  # - trialCountOutput: One .csv file formatted as a long dataframe with the
  #   following columns. This file documents the number of remaining trials per
  #   subject and emotion condition. These values are reported for each sample and 
  #   specified percentage of subjects with low trial-count.
    # - SUBJECTID: Subject ID (e.g., 01, 02, ...)
    # - emotion: Emotion condition label (i.e., A, B)
    # - trialN: Number of remaining trials for this subject and emotion condition
    # - caseDeletionPct: Percent of subjects with less than 10 trials/condition that
    #   were casewise deleted prior to ANOVA analysis. 0% indicates that missing 
    #   trials were induced but no subjects were casewise deleted (all subjects 
    #   met the 10 trials/condition threshold). Pop. indicates no missing trials
    #   and no casewise deletion.
    # - sample: The simulated data sample ID (e.g., 1)

library(plyr) # ddply function
library(lme4) # used for creating lme models
library(lmerTest) # used for returning p-value for lme models
library(gsubfn) # list function for assigning multiple outputs
library(data.table) # used for fread function
library(dplyr) # select function
library(performance) # check_convergence function
library(afex) # ANOVA analysis
library(emmeans) # extract estimated marginal means
library(car) # contr.sum function
library(stringr) # str_sub function
#------------------------------------------------------------------------
# DATA ENVIRONMENT

# Specify folder location of formatted data files
importFolder <- 'C:/Users/basclab/Desktop/LMESimulation/MeanAmpOutput_Final/'

# Make directory of all .csv files in importFolder
fileDir <- list.files(path = importFolder, pattern = ".csv", full.names = TRUE, recursive = FALSE)
sampleN <- length(fileDir) # Number of simulated samples 

# Specify folder location for saving model's estimated marginal means and number
# of remaining trials per subject
saveFolder <- 'C:/Users/basclab/Desktop/LMESimulation/ModelOutput/'

set.seed(20210329) # Specify seed for reproducible results

#------------------------------------------------------------------------
# 1. DEFINE SIMULATION-LEVEL VARIABLES

# The following parameters were set at the simulation level in the 
# LMESimulation_02_SimulateERPData.m script and are the same across all
# simulated data samples: 

subjectN <- 50 # Number of unique subjects per sample
actorN <- 5 # Number of unique actors per sample
presentN <- 10 # Number of presentations of each stimulus (emotion condition/actor)
presentAvgValue <- mean(1:10) # Average presentation number value
emotionTrialN <- actorN*presentN # Total number of trials per emotion condition

emotionLabel <- c("A", "B") # Name of each emotion condition
emotionN <- length(emotionLabel) # Number of emotion conditions
emotionA <- -9.995 # Emotion condition A's population mean
emotionB <- -11.997 # Emotion condition B's population mean
emotionDiff <- c(emotionA-emotionB) # Difference between emotion condition's population means
emotionSlope <- 1.499 # Change in amplitude with each successive presentation
# Population mean amplitude for each emotion condition specified at the average 
# presentation number simulated in the dataset
emotionAvgValue <- c(mean(seq(emotionA, emotionA+(emotionSlope*(presentN-1)), by = emotionSlope)), 
                     mean(seq(emotionB, emotionB+(emotionSlope*(presentN-1)), by = emotionSlope)))

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
# numbers (i.e., 6-10 and 1-5). This value is used to scale each individual trial's 
# presentation number weight so that the weights will sum to 1 (see lines 486-488). 
presentNumberTrials6to10 <- emotionTrialN/2 
presentNumberTrials1to5 <- emotionTrialN/2 

# Specify probability weight distribution for younger vs. older age group. These 
# weights are used to specify missingness pattern for the between-subjects
# effect (e.g., if ageWeightYounger = 0.7, then 70% of subjects selected for more
# missing trials and subsequent casewise deletion were from the younger age group). 
ageWeightYounger <- 0.5
ageWeightOlder <- 1-ageWeightYounger
# Calculate the total number of subjects in the younger and older age groups. This
# value is used to scale each subject's age weight so that the weights will sum to 
# 1 (see lines 489-490).
ageTrialsYounger <- subjectN/2
ageTrialsOlder <- subjectN/2

# Specify percent of subjects with low trial-count (i.e., subjects with less
# than 10 trials/condition who will be removed during casewise deletion). The
# script will loop through each value in this array and generate a corresponding
# dataset with missing trials.
caseDeletionPctArray <- c(0, 6, 11, 32)

#------------------------------------------------------------------------
# 2. DEFINE FUNCTIONS FOR INDUCING MISSING TRIALS AND EXTRACTING MODEL OUTPUT

# induceMissingTrials: Function to randomly select subjects for inducing
# low trial counts and subsequent casewise deletion prior to ANOVA analysis. 
# In addition, missing trials are induced based on the specified probability
# weights from lines 147-174 and 486-490. 
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
  
  # Randomly sample the subject IDs that will have low trial counts based on the 
  # specified age weights and the caseDeletionN variable
  subjectCaseDeletion <- sample(dfAgeWeight$SUBJECTID, caseDeletionN, 
                                replace = FALSE, prob=dfAgeWeight$ageWeight)
  
  # Calculate the maximum number of trials that can be removed from each condition
  # before the subject is considered to have a low trial count and would be
  # casewise deleted (e.g., if there are 50 trials, a maximum of 40 trials can
  # be removed for an included (not casewise deleted) subject)
  trialMissingThreshold <- emotionTrialN - 10
  
  # Loop through each subject and randomly select a subset of trials from each
  # condition to remove
  for (subject in dfAgeWeight$SUBJECTID) {
    
    # Generate the number of missing trials to induce for each emotion condition
    if (subject %in% subjectCaseDeletion) { 
      
      # For subjects with a low trial count, at least one emotion condition will 
      # have less than 10 trials remaining
      trialMissing <- c(sample(x=(trialMissingThreshold+1):emotionTrialN, size = 1),
                        sample(x=0:emotionTrialN, size = emotionN-1, replace = TRUE))                       
    } else { 
      # For subjects who do NOT have a low trial count, all emotion conditions
      # will have at least 10 trials
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

# extractModelOutput: Function to calculate the estimated marginal means for 
# each emotion condition and the difference between conditions. Other output
# values include standard error, confidence intervals, and test statistics. 
# For the LME model only, models that do not converge or have a singular fit 
# are flagged and their marginal means and output values are set to NA. 
# - Format: 
#     modelOutput <- extractModelOutput(modelInput, modelType)
# - Inputs:
  # - modelInput: Model output created by lm or lmer function
  # - modelType: String indicating whether modelInput is an "LME" model or an
  #   "ANOVA" model. 
# - Outputs: 
  # - modelOutput: Dataframe storing the model's output values for each emotion
  #   condition and condition difference. It contains the following columns:
  #   emotion, estimate, SE, df, lower.CL, upper.CL, t.ratio, p.value, inCL,
  #   modelProblem, modelType (see Outputs section at the top of the script for
  #   more information). 
extractModelOutput <- function(modelInput, modelType) {
  #------------------------------------------------------------------------
  # Extract output for an LME model. Estimated marginal mean for each emotion
  # condition and pairwise comparison are specified at the average presentation 
  # number and p-values are calculated using the Satterthwaite method. 
  if (modelType == 'LME') {
    # Calculate estimated marginal means
    mLME <- emmeans::emmeans(modelInput, pairwise~emotion, mode = "satterthwaite", 
                             lmerTest.limit = 240000, at = list(presentNumber = c(presentAvgValue)))
    
    # Extract output values for each emotion condition 
    modelOutput_estimates <- data.frame(summary(mLME, infer = c(TRUE, TRUE))$emmeans)
    # Check if each true population emotion condition value is located within the
    # model's 95% confidence interval for the emotion condition
    for (emotionNum in 1:emotionN) {
      modelOutput_estimates$inCL[emotionNum] <- between(emotionAvgValue[emotionNum], 
                                                        modelOutput_estimates$lower.CL[emotionNum], 
                                                        modelOutput_estimates$upper.CL[emotionNum])
    }
    names(modelOutput_estimates)[1] <- c('emotion') # Update column names
    names(modelOutput_estimates)[2] <- c('estimate')
    
    # Extract output values for the condition difference pairwise comparison 
    modelOutput_condDiff <- data.frame(summary(mLME, infer = c(TRUE, TRUE))$contrasts)
    # Check if each true population condition difference is located within the
    # model's 95% confidence interval for the condition difference
    for (emotionDiffNum in 1:length(emotionDiff)) {
      modelOutput_condDiff$inCL[emotionDiffNum] <- between(emotionDiff[emotionDiffNum],
                                                           modelOutput_condDiff$lower.CL[emotionDiffNum],
                                                           modelOutput_condDiff$upper.CL[emotionDiffNum])
    }
    names(modelOutput_condDiff)[1] <- c('emotion') # Update column names
    names(modelOutput_condDiff)[2] <- c('estimate')
    
    # Save all output values into one dataframe
    modelOutput <- rbind(modelOutput_estimates, modelOutput_condDiff)
    
    # Save the default modelProblem value as "none" and update if needed below
    modelOutput$modelProblem <- 'none' 
    # If model did not converge or is singular, the output values are replaced 
    # with NA and the modelProblem value is updated accordingly
    if (!check_convergence(modelInput)) {
      modelOutput <- modelOutput %>% mutate(estimate = NA, SE = NA, df = NA,
                                            lower.CL = NA, upper.CL = NA, 
                                            t.ratio = NA, p.value = NA, inCL = NA, 
                                            modelProblem = 'notConverge')
      
    } else if (check_singularity(modelInput)) { 
      modelOutput <- modelOutput %>% mutate(estimate = NA, SE = NA, df = NA,
                                            lower.CL = NA, upper.CL = NA, 
                                            t.ratio = NA, p.value = NA, inCL = NA, 
                                            modelProblem = 'singularFit')
    }
    
  #------------------------------------------------------------------------
  # Extract output for an ANOVA model. Estimated marginal mean for each emotion
  # condition and pairwise comparison are specified at the average presentation
  # number of the dataset. Compared to the LME model, we cannot specify the
  # presentation number explicitly because data has been trial-averaged. 
  } else if (modelType == 'ANOVA'){
    # Calculate estimated marginal means
    mANOVA <- emmeans::emmeans(modelInput, ~ emotion)
    
    # Extract output values for each emotion condition 
    modelOutput_estimates <- data.frame(summary(mANOVA, infer = c(TRUE, TRUE)))
    # Check if each true population emotion condition value is located within the
    # model's 95% confidence interval for the emotion condition
    for (emotionNum in 1:emotionN) {
      modelOutput_estimates$inCL[emotionNum] <- between(emotionAvgValue[emotionNum], 
                                                        modelOutput_estimates$lower.CL[emotionNum], 
                                                        modelOutput_estimates$upper.CL[emotionNum])
    }
    names(modelOutput_estimates)[1] <- c('emotion') # Update column names
    names(modelOutput_estimates)[2] <- c('estimate')
    
    # Extract output values for the condition difference pairwise comparison
    modelOutput_condDiff <- data.frame(summary(pairs(mANOVA, infer = c(TRUE, TRUE))))
    # Check if each true population condition difference is located within the
    # model's 95% confidence interval for the condition difference
    for (emotionDiffNum in 1:length(emotionDiff)) {
      modelOutput_condDiff$inCL[emotionDiffNum] <- between(emotionDiff[emotionDiffNum],
                                                           modelOutput_condDiff$lower.CL[emotionDiffNum],
                                                           modelOutput_condDiff$upper.CL[emotionDiffNum])
    }
    names(modelOutput_condDiff)[1] <- c('emotion') # Update column names
    names(modelOutput_condDiff)[2] <- c('estimate')
    
    # Save all output values into one dataframe
    modelOutput <- rbind(modelOutput_estimates, modelOutput_condDiff)
    modelOutput$modelProblem <- 'none' # This value is always "none" for ANOVA models
  }
  
  # Record the model type (e.g., "LME) in the dataframe
  modelOutput$modelType <- modelType 
  
  return(modelOutput) # Return output variables
}

# fitMissData: Function to induce missing trials and extract model output
# from the specified dataset and percentage of subjects with low trial-count. 
# This function relies on the induceMissingTrials and extractModelOutput 
# functions listed above. 
# - Format: 
#     list[modelOutput_misData, trialCount] <- fitMissData(dfOriginal, caseDeletionPct)
# - Inputs:
  # - dfOriginal: Dataframe containing one simulated sample's data before any 
  #   induced missing trials (see Outputs section at the top of the script for
  #   more information). 
  # - caseDeletionPct: Percent of subjects with low trial-count (i.e., less than
  #   10 trials/condition).
# - Outputs:
  # - modelOutput_misData: Dataframe combining LME and ANOVA outputs from the
  #   extractModelOutput function. It contains the following columns:
  #   emotion, estimate, SE, df, lower.CL, upper.CL, t.ratio, p.value, inCL,
  #   modelProblem, modelType, caseDeletionPct (see Outputs section at the
  #   top of the script for more information). 
  # - trialCount: Dataframe output from the induceMissingTrials function. See 
  #   this function's documentation above for column information.  
fitMissData <- function(dfOriginal, caseDeletionPct){
  #------------------------------------------------------------------------
  # Induce missing trials based on specified percentage of subjects with low 
  # trial-count
  list[dfMissing, subjectCaseDeletion, trialCount] <- induceMissingTrials(dfOriginal,
                                                                          caseDeletionPct) 
  #------------------------------------------------------------------------
  # Fit LME model with dfMissing (trial-level dataset after inducing trial missingness).
  # Restricted maximum likelihood (REML) is used to fit all LME models
  fit.LMEMis <- lmer(meanAmpNC ~ emotion + presentNumber + age + (1|SUBJECTID) +
                       (1|ACTOR), data=dfMissing, REML = TRUE) 
  LMEMis_output <- extractModelOutput(fit.LMEMis, 'LME') # Extract estimated marginal means
  
  #------------------------------------------------------------------------
  # Casewise delete subjects with less than 10 trials/emotion condition
  dfCaseDeletion <- dfMissing[!(dfMissing$SUBJECTID %in% subjectCaseDeletion),]
  
  # Fit ANOVA model with dfCaseDeletionAvg (dataset after inducing trial 
  # missingness, casewise deleting, and averaging over trials)
  dfCaseDeletionAvg <- aggregate(meanAmpNC ~ SUBJECTID + emotion + age, 
                                 dfCaseDeletion, mean, na.action = na.omit)
  fit.ANOVAMis <- aov_ez("SUBJECTID", "meanAmpNC", dfCaseDeletionAvg, between = c("age"),
                         within = c("emotion")) 
  ANOVAMis_output <- extractModelOutput(fit.ANOVAMis, 'ANOVA') # Extract estimated marginal means
  
  #-----------------------------------------------------------------------
  # Format model output and trial count dataframes for output 

  # Save all output values for both LME and ANOVA models into one dataframe
  modelOutput_misData <- bind_rows(LMEMis_output, ANOVAMis_output)
  
  # Record percentage of subjects with low trial-count in both dataframes
  modelOutput_misData$caseDeletionPct <- paste0(caseDeletionPct,'%') 
  trialCount$caseDeletionPct <- paste0(caseDeletionPct, '%')
  
  return(list(modelOutput_misData, trialCount)) # Return output variables
}

#------------------------------------------------------------------------
# 3. IMPORT SIMULATED DATA FILES AND RUN FUNCTIONS TO INDUCE MISSING TRIALS AND
# FIT LME AND ANOVA MODELS

# Initialize variables for saving extracted model output and trial count per 
# subject and emotion condition
modelOutput = NULL
trialCountOutput = NULL

for (sampleNum in 1:sampleN) { # Loop through each simulated data sample
  
  # Initialize temporary variables for storing model output and trial count
  # (this variable will be reset for each data sample)
  modelOutput_oneSample <- NULL
  trialCountOutput_oneSample <- NULL
  
  #------------------------------------------------------------------------
  # Import data sample ("population" dataset)
  dfOriginal <- fread(fileDir[sampleNum]) 
  
  # Extract sample ID number from filename (e.g., extract '0001' from
  # 'C:/Users/basclab/Desktop/LMESimulation/MeanAmpOutput_Final/Sample0001-MeanAmpOutput.csv')
  sampleID <- str_sub(fileDir[sampleNum],-22,-19)
  
  # Specify desired columns as factors for subsequent analysis 
  dfOriginal$ACTOR <- as.factor(dfOriginal$ACTOR)
  dfOriginal$SUBJECTID <- as.factor(dfOriginal$SUBJECTID)
  dfOriginal$emotion <- as.factor(dfOriginal$emotion)
  dfOriginal$age <- as.factor(dfOriginal$age)
  # Specify sum coding for the age variable for subsequent ANOVA analysis
  contrasts(dfOriginal$age) <- contr.Sum(levels(dfOriginal$age)) 
  
  # Create probability weight columns for presentation number and age group using 
  # values specified in step 1. 
  dfOriginal$presentNumberWeight <- ifelse(dfOriginal$presentNumber >5,
                                           (presentNumberWeight6to10/presentNumberTrials6to10), 
                                           (presentNumberWeight1to5/presentNumberTrials1to5))
  dfOriginal$ageWeight <- ifelse(dfOriginal$age == 'youngerAgeGroup', 
                                 ageWeightYounger/ageTrialsYounger, ageWeightOlder/ageTrialsOlder)

  #------------------------------------------------------------------------
  # Fit models to population dataset
  
  # Fit LME model with dfOriginal (trial-level population dataset)
  # Restricted maximum likelihood (REML) is used to fit all LME models
  fit.LMEPop <- lmer(meanAmpNC ~ emotion + presentNumber + age + (1|SUBJECTID) +
                       (1|ACTOR), data=dfOriginal, REML = TRUE)
  LMEPop_output <- extractModelOutput(fit.LMEPop, 'LME') # Extract estimated marginal means
  
  # Fit ANOVA model with dfOriginalAvg (dataset after averaging over trials)
  dfOriginalAvg <- aggregate(meanAmpNC ~ SUBJECTID + emotion + age, dfOriginal, 
                             mean, na.action = na.omit)
  fit.ANOVAPop <- aov_ez("SUBJECTID", "meanAmpNC", dfOriginalAvg, between = c("age"),
                         within = c("emotion"))
  ANOVAPop_output <- extractModelOutput(fit.ANOVAPop, 'ANOVA') # Extract estimated marginal means
  
  # Save all output values for both LME and ANOVA models into one dataframe
  modelOutput_oneSample <- bind_rows(LMEPop_output, ANOVAPop_output)
  modelOutput_oneSample$caseDeletionPct <- 'Pop.' # Specify that models were fitted to the population dataset
  
  #------------------------------------------------------------------------
  # Loop through each specified percentage of subjects with low trial-count
  for (i in 1:length(caseDeletionPctArray)) { 
    
    # Induce corresponding number of missing trials, fit LME and ANOVA models,
    # and extract model outputs
    list[modelOutput_misData, trialCount] <- fitMissData(dfOriginal, caseDeletionPctArray[i])
    
    # Save all output values for this sample and percentage of subjects with low
    # trial-count in the temporary variable created for this sample
    modelOutput_oneSample <- bind_rows(modelOutput_oneSample, modelOutput_misData)
    trialCountOutput_oneSample <- bind_rows(trialCountOutput_oneSample, trialCount)
    
  }
  
  # Record simulated data sample ID in the output dataframes
  modelOutput_oneSample$sample <- sampleID
  trialCountOutput_oneSample$sample <- sampleID
  
  # Save this sample's output dataframes in the final output dataframes (which
  # contain the values for all simulated samples)
  modelOutput <- bind_rows(modelOutput, modelOutput_oneSample)
  trialCountOutput <- bind_rows(trialCountOutput, trialCountOutput_oneSample)
}

#-----------------------------------------------------------------------
# 4. SAVE OUTPUT FILES

# Specify filename for saving model output and trial count files
modelOutputFilename = paste0(saveFolder, 'sampleN',sampleN,
                             '_subN',subjectN,'_modelOutput.csv')
trialCountFilename = paste0(saveFolder, 'sampleN',sampleN,
                            '_subN',subjectN,'_trialCount.csv')

print('Saving final output')
fwrite(modelOutput, file = modelOutputFilename, row.names = FALSE)
fwrite(trialCountOutput, file = trialCountFilename, row.names = FALSE)

#-----------------------------------------------------------------------
# 5. (OPTIONAL) CALCULATE POWER OF LME MODEL

# In this example, we are interested in the power for detecting a significant
# condition difference between emotion conditions A and B with an LME model.
# Our dataset consists of 1,000 simulated data samples with missing trials 
# induced so that 32% of subjects have less than 10 trials/condition

# Extract the LME models that have been fitted to a dataset with the above
# specifications
modelOutput %>% filter(emotion == "A - B" & modelType == "LME" & 
                         caseDeletionPct == "32%") -> modelOutput_LMECondDiff

# Extract number of LME models that found a significant condition difference (p<0.05)
modelOutput_LMECondDiffSig <- sum(modelOutput_LMECondDiff$p.value <0.05, na.rm = TRUE)

# Calculate percentage of samples (out of sampleN) where the LME model found a 
# significant difference (i.e., power)
100*(modelOutput_LMECondDiffSig/sampleN)
