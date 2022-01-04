This tutorial uses the following processing pipeline and associated scripts.


See Appendix D from Heise, Mon, and Bowman (submitted) for additional details about this pipeline. 

## Table of Contents  
* [Script requirements](#script-requirements)
* [Modifications for your own experiment and processing pipeline](#modifications-for-your-own-experiment-and-processing-pipeline)

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
The above scripts can be modified based on your experiment design (e.g., to include three conditions) and processing pipeline (e.g., epoch time window). See script comments for suggestions 
