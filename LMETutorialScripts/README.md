This tutorial pipeline uses MATLAB to process continuous EEG data files and calculate trial-level ERP waveforms. Mean amplitude values are then exported into R and analyzed with LME models. See Appendix D from Heise, Mon, and Bowman (2022) for additional details.

## Table of Contents  
* [Processing pipeline overview](#processing-pipeline-overview)
* [Script requirements](#script-requirements)
* [Modifications for your own experiment and processing pipeline](#modifications-for-your-own-experiment-and-processing-pipeline)

## Processing pipeline overview
<img width="400" alt="ERPProcessingTutorial_ForGitHub" src="https://user-images.githubusercontent.com/49215489/148004509-6a02682d-62da-42e5-8828-5feb35ea8ff6.png">

## Script requirements
* MATLAB R2019a: [https://www.mathworks.com/](https://www.mathworks.com/)
* EEGLAB v. 2019_0: [https://sccn.ucsd.edu/eeglab/index.php](https://sccn.ucsd.edu/eeglab/index.php)
* ERPLAB v. 8.01: [https://erpinfo.org/erplab/](https://erpinfo.org/erplab/)
* R v. 3.6.1: [https://www.r-project.org/](https://www.r-project.org/)
* lme4 v. 1.1-25: [https://cran.r-project.org/web/packages/lme4/index.html](https://cran.r-project.org/web/packages/lme4/index.html)
* lmerTest v. 3.1-3: [https://cran.r-project.org/web/packages/lmerTest/index.html](https://cran.r-project.org/web/packages/lmerTest/index.html)
* afex v. 0.28-1: [https://cran.r-project.org/web/packages/afex/index.html](https://cran.r-project.org/web/packages/afex/index.html)
* emmeans v. 1.5.3: [https://cran.r-project.org/web/packages/emmeans/index.html](https://cran.r-project.org/web/packages/emmeans/index.html)
* For other required R packages, see the LMESimulation_04_ExtractModelOutput.R script

## Modifications for your own experiment and processing pipeline
The above scripts can be modified based on your experiment design (e.g., to include three conditions) and processing pipeline (e.g., epoch time window). See script comments for more information.
