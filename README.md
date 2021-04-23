# Phase2.1WorkingFolder
Temporal folder R scripts before wrapping to R package.

# run_platelet_ddimer.R
This R script creates descriptive bar plot for patients with high d dimer and low platelet

# For Docker Users

## 1. Make sure you are using the latest version of Docker. 

## 2. Make sure the Phase1.1 data and Phase2.1 data are in the /4ceData/Input directory that is mounted to the container

## 3. Set the output directory in line 8 of run_platelet_ddimer.R:

``` R
dir.output="/4ceData/Output" ## you can change it to another path as your output directory
```

## 4. Run script run_platelet_ddimer.R

## 5. If there is no error, the output figures will be found in the output directory "/4ceData/Output", or the directory you specified.

