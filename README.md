# Phase2.1WorkingFolder
Temporal folder for raw R scripts before wrapping to R package.

# run_platelet_ddimer.R
This R script creates descriptive bar plot for patients with high d dimer and low platelet

# For Docker Users

1. Make sure you are using the latest version of Docker. 

2. Make sure the Phase1.1 data and Phase2.1 data are in the /4ceData/Input directory that is mounted to the container

3. The loinc code for platelet is not included in the 4CE Phase2.1 data. To run the code, you need to add loinc code "26515-7" for platelet in LocalPatientObservation.csv file. 

4. Do not skip the lines 2-3 that re-install the latest FourCePhase2.1Data package. Several functions used by this script and also the obfuscation table are from the FourCePhase2.1Data package:
``` R
devtools::install_github("https://github.com/covidclinical/Phase2.1DataRPackage", subdir="FourCePhase2.1Data", upgrade=FALSE)
library(FourCePhase2.1Data)
```

5. Set the output directory in line 8 of run_platelet_ddimer.R:

``` R
dir.output="/4ceData/Output" ## you can change it to another path as your output directory
```

6. Run script run_platelet_ddimer.R

7. If there is no error, the output figures will be found in the output directory "/4ceData/Output", or the directory you specified.

