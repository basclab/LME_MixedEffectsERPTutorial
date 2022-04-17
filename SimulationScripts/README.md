Simulated ERP data reported in Section 3 and Appendix B of Heise, Mon, and Bowman (2022) were generated with the following MATLAB and R scripts. This README describes how to run the simulation scripts and conduct a power analysis. 

For additional information, see Appendix B for an overview of the simulation methods and comparison of linear mixed effects (LME) and analysis of variance (ANOVA) models. See Appendix D for a tutorial of the R code used to fit the LME and ANOVA models. 

## Table of Contents  
* [Script overview](#script-overview)
* [Script requirements](#script-requirements)
* [Suggested folder structure](#suggested-folder-structure)
* [Details for replicating results from manuscript](#details-for-replicating-results-from-manuscript)
* [Modifications for your own simulations and power analyses](#modifications-for-your-own-simulations-and-power-analyses)

## Script overview
A brief description of each script is listed below. Each script also has comments with information about input arguments, output files, and similarities/differences with the [LME tutorial scripts](https://github.com/basclab/LME_MixedEffectsERPTutorial/tree/main/LMETutorialScripts).

*MATLAB scripts for simulating trial-level ERP data*
* **LMESimulation_01_CreateBinDescriptorFile.m**: Creates a .txt file listing the event markers that belong to each ERP ‘bin’.
  * In this simulation, each simulated subject saw 100 trials (2 emotion conditions and 5 different ‘actors’ with 10 presentations each). As a result, there are 100 trial-specific bins.
* **LMESimulation_02_SimulateERPData.m**: Simulates trial-level ERP data using three helper functions (simulateAllSamples, simulateOneSample, and simulateOneSubject).
  * This script specifies the number of simulated samples, subjects per sample, and random seed. See section below for more information about replicating the results presented in Heise et al. (2022).
* **simulateAllSamples.m**: Specifies a neural source and generates data for each sample using the simulateOneSample function.
  * This function specifies the lead field, channel montage, channels of interest, and dipole location and orientation used for all simulated samples.
* **simulateOneSample.m**: Generates data for each subject of a simulated sample using the simulateOneSubject function.
  * This function specifies the actor and age intercepts for a sample. In addition, this function creates the output files (mean amplitude file and subject data log) used in subsequent R scripts.
* **simulateOneSubject.m**: Generates data for one subject.
  * This function specifies the epoch window, sampling rate, presentation number of each stimulus, emotion peak amplitude and latency, peak amplitude decay (habituation) for successive stimulus presentations, subject peak amplitude intercept and latency shift, trial-level noise amplitude, and event marker preceding codes.

*R scripts for organizing data files and fitting LME and ANOVA models*
* **LMESimulation_03_OrganizeDataFiles.R**: Merges the mean amplitude output files and subject data log into one file. In addition, extracts subject ID and stimuli-related information for each trial and organizes them into variables for LME and ANOVA analysis.
* **LMESimulation_04_ExtractModelOutput.R**: Imports each simulated sample’s data file, induces missing trials based on the specified missingness pattern (e.g., more missing data in later trials and in younger subjects) and percentage of subjects with low trial-count, and fits LME and ANOVA models to the dataset. Estimated marginal means are extracted for each emotion condition and model.
  * This script also includes code to assess the divergence of each model's marginal means from the true population mean (with root mean squared error and relative bias) and run a power analysis.

## Script requirements
* MATLAB R2019a: [https://www.mathworks.com/](https://www.mathworks.com/)
* EEGLAB v. 2019_0: [https://sccn.ucsd.edu/eeglab/index.php](https://sccn.ucsd.edu/eeglab/index.php)
* ERPLAB v. 8.01: [https://erpinfo.org/erplab/](https://erpinfo.org/erplab/)
* SEREEGA v. 1.1.0: [https://github.com/lrkrol/SEREEGA](https://github.com/lrkrol/SEREEGA)
* Pediatric Head Atlas release v. 1.1, Atlas 1 (0-2 years old): [https://www.pedeheadmod.net/pediatric-head-atlases/](https://www.pedeheadmod.net/pediatric-head-atlases/)
  * After requesting and downloading the atlas, the atlas folder should be added to the MATLAB path (via "Home" > "Set Path" > "Add with Subfolders").
* R v. 3.6.1: [https://www.r-project.org/](https://www.r-project.org/)
* lme4 v. 1.1-25: [https://cran.r-project.org/web/packages/lme4/index.html](https://cran.r-project.org/web/packages/lme4/index.html)
* lmerTest v. 3.1-3: [https://cran.r-project.org/web/packages/lmerTest/index.html](https://cran.r-project.org/web/packages/lmerTest/index.html)
* afex v. 0.28-1: [https://cran.r-project.org/web/packages/afex/index.html](https://cran.r-project.org/web/packages/afex/index.html)
* emmeans v. 1.5.3: [https://cran.r-project.org/web/packages/emmeans/index.html](https://cran.r-project.org/web/packages/emmeans/index.html)
* For other required R packages, see the LMESimulation_04_ExtractModelOutput.R script

## Suggested folder structure
We recommend creating a parent folder for storing the following files:
* The 7 MATLAB and R simulation scripts
* **LMESimulation_EventMarkerMappingKey.xlsx**: Lists the event marker preceding codes corresponding to each stimulus. This file is used for creating the bin descriptor file in the LMESimulation_01_CreateBinDescriptorFile.m script.
* **LMESimulation_BinDescriptorFile.txt**: Lists each ERP bin’s number, label, and event markers. This file is created during the LMESimulation_01_CreateBinDescriptorFile.m script and is required for the simulateOneSubject function.
* **LMESimulation_BinDescriptorFileKey.xlsx**: Documents the information in the bin descriptor file. This file is created during the LMESimulation_01_CreateBinDescriptorFile.m script.

We also recommend adding the following subfolders for storing output files:

* **01_MeanAmpOutput_PreMerge**: Contains each sample’s mean amplitude values per bin, channel, and subject. There is one file for each simulated sample and files are created by the simulateOneSample function. 
* **01_SubjectDataLog**: Contains each sample’s subject data log, which lists each subject’s assigned age group. There is one file for each simulated sample and files are created by the simulateOneSample function. 
* **02_MeanAmpOutput_Final**: Contains the formatted mean amplitude output files combining information from the 01_MeanAmpOutput_PreMerge and 01_SubjectDataLog folders. There is one file for each simulated sample and files are created during the LMESimulation_03_OrganizeDataFiles.R script.
* **03_ModelOutput**: Contains the two output files created during the LMESimulation_04_ExtractModelOutput.R script for a specified missingness pattern (e.g., more missing data in later trials and in younger subjects). 
  * The model output file contains the LME and ANOVA models’ estimated marginal means for each emotion condition and percentage of subjects with low trial-count. Results from all simulated samples are stored in one file.
  * The trial count file lists the number of remaining trials per subject and emotion condition after inducing missing trials. Trial counts for all simulated samples are stored in one file.

Examples of each output file are available here: [https://github.com/basclab/LME_MixedEffectsERPTutorial/tree/main/SimulationScripts/ExampleOutputFiles](https://github.com/basclab/LME_MixedEffectsERPTutorial/tree/main/SimulationScripts/ExampleOutputFiles)

## Details for replicating results from manuscript
Due to the computation time required (~6-8 minutes/sample), simulated samples reported in Heise et al. (2022) were generated across three computers. These computers used identical scripts except for the following variables and lines of code in LMESimulation_02_SimulateERPData.m. These variables correspond to the number of simulated samples (sampleN), first sample ID (sampleStart), and random seed. 

For example, computer 2 used the Mersenne Twister generator with a seed of 3 and simulated 250 samples with IDs from #501 to 750. 
Computer Name | sampleN (line 129) | sampleStart (line 134) | Random seed (line 141)
------------ | ------------- | ------------- | -------------
1 | 500 | 1 | rng(1,'twister')
2 | 250 | 501 | rng(2,'twister')
3 | 250 | 751 | rng(3,'twister')

## Modifications for your own simulations and power analyses
The above scripts can be modified based on your experiment design (e.g., number of trials/experiment, expected mean amplitude difference between conditions). In particular, information about modifying each parameter is saved in the “Define Simulation Parameters” sections of the LMESimulation_02_SimulateERPData.m script and the simulateAllSamples, simulateOneSample, and simulateOneSubject functions. Peak amplitude values for each condition and intercepts for subject/actor/other effects of interest should be selected based on the desired outcome variable (e.g., mean amplitude extracted over a 300-500 ms time window). We recommend testing your code by first simulating waveforms without trial-level noise before simulating the final dataset. 

In addition, the Pediatric Head Atlas is most appropriate for developmental data, but the New York Head (ICBM-NY) and lead fields generated with the FieldTrip toolbox can also be used for simulations. Further documentation is provided in Krol et al. (2018).

After simulating a large number of datasets (we selected 1,000 samples to balance computation time with a sufficiently large number of simulations) and organizing the data files, use the LMESimulation_04_ExtractModelOutput.R script to simulate expected missing data patterns and fit each dataset to your linear mixed effects model. Power is calculated as the percentage of models where the effect of interest was observed (see comments in LMESimulation_04_ExtractModelOutput.R for more information). 

Krol, L. R., Pawlitzki, J., Lotte, F., Gramann, K., & Zander, T. O. (2018). SEREEGA: Simulating event-related EEG activity. *Journal of Neuroscience Methods*, *309*, 13–24. [https://doi.org/10.1016/j.jneumeth.2018.08.001](https://doi.org/10.1016/j.jneumeth.2018.08.001)
