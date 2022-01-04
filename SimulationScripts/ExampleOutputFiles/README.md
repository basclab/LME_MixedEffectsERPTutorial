The following scripts were used to produce these example output files. See each corresponding script for more information about the output variables.

* **LMESimulation_01_CreateBinDescriptorFile.m**:
  * LMESimulation_BinDescriptorFile.txt 
  * LMESimulation_BinDescriptorFileKey.xlsx

* **simulateOneSample function** (used by LMESimulation_02_SimulateERPData.m): 
  * Sample0443-MeanAmpOutput_PreMerge.txt
  * Sample0443-SubjectDataLog.txt

* **LMESimulation_03_OrganizeDataFiles.R**:
  * Sample0443-MeanAmpOutput.csv: This file is identical to the one saved in the [LME tutorial section](https://github.com/basclab/LME_MixedEffectsERPTutorial/tree/main/LMETutorialScripts).

* **LMESimulation_04_ExtractModelOutput.R**: We imported the Sample0443-MeanAmpOutput.csv file and induced more missing data in later trials across both age groups. 
  * sampleN1_subN50_modelOutput.csv
  * sampleN1_subN50_trialCount.csv
