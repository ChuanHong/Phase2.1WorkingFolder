rm(list=ls())
devtools::install_github("https://github.com/covidclinical/Phase2.1DataRPackage", subdir="FourCePhase2.1Data", upgrade=FALSE)
library(FourCePhase2.1Data)
library(dplyr)
library(purrr)
library(tidyr)
currSiteId = getSiteId() ### you can manually set the siteid instead: e.g., currSiteId = "MGB
obfuscation.level=site.country.obfuscation[site.country.obfuscation$SiteID==currSiteId, "Obfuscation"]

dir.output="/4ceData/Output"
LocalPatientObservations=getLocalPatientObservations(currSiteId)
LocalPatientClinicalCourse=getLocalPatientClinicalCourse(currSiteId)
LocalPatientSummary=getLocalPatientSummary(currSiteId)

pltt.cut=50 
ddmer.cut=250
loinc.platelet="26515-7"

search.seq.fun=function(dat){
  junk=split(dat$days_since_admission, cumsum(c(1,diff(dat$days_since_admission)!=1)))
  junk.length=do.call(rbind,lapply(1:length(junk), function(ll) c(junk[[ll]][1],length(junk[[ll]]))))
  junk.length=data.frame(junk.length)
  colnames(junk.length)=c("start_day", "length")
  junk.length
}

for(setting in c("High D-dimer Low Platelet", "High D-dimer", "Low Platelet")){
for(sex.group in c("female+male", "female","male")){
dat.lab0=LocalPatientObservations[LocalPatientObservations$concept_type=="LAB-LOINC",]
loinc.ddmer=as.character(code.dict[code.dict$labname%in%c("D-dimer (DDU)","D-dimer (FEU)"),"loinc"])

dat.lab=dat.lab0[dat.lab0$concept_code%in%c(loinc.ddmer, loinc.platelet),c("patient_num", "days_since_admission", "concept_code", "value")]
dat.lab.wide <- dat.lab %>%
  pivot_wider(values_from = value, names_from = concept_code, values_fn = mean)
nm.col=colnames(dat.lab.wide)
dat.lab.wide=data.frame(dat.lab.wide)
colnames(dat.lab.wide)=nm.col
if("48066-5"%in%colnames(dat.lab.wide) & "48065-7"%in%colnames(dat.lab.wide)){
dat.lab.wide$ddmer=rowMeans(cbind(dat.lab.wide[,"48065-7"]*0.5, dat.lab.wide[,"48066-5"]), na.rm=T)
}else{
  if("48066-5"%in%colnames(dat.lab.wide)){
    dat.lab.wide$ddmer=dat.lab.wide[,"48066-5"]}
  if("48065-7"%in%colnames(dat.lab.wide)){
    dat.lab.wide$ddmer=dat.lab.wide[,"48065-7"]}
}

dat.lab.wide$pltt=dat.lab.wide[,loinc.platelet]
dat.lab.wide=dat.lab.wide[,c("patient_num", "days_since_admission", "ddmer", "pltt")]

if(setting=="High D-dimer Low Platelet"){
dat.complete=dat.lab.wide[complete.cases(dat.lab.wide),]}
if(setting=="High D-dimer"){
  dat.complete=dat.lab.wide[which(is.na(dat.lab.wide$ddmer)!=1),]}
if(setting=="Low Platelet"){
  dat.complete=dat.lab.wide[which(is.na(dat.lab.wide$pltt)!=1),]}

patient_num.list=unique(dat.complete$patient_num)
res.seq=do.call(rbind,lapply(patient_num.list, function(patient_num){
  dat.tmp=dat.complete[dat.complete$patient_num==patient_num,]
  res=search.seq.fun(dat.tmp)
  res=data.frame(patient_num, res)
}))
patient_num.seq1=unique(res.seq[res.seq$length>=1,"patient_num"])
patient_num.seq2=unique(res.seq[res.seq$length>=2,"patient_num"])
patient_num.seq3=unique(res.seq[res.seq$length>=3,"patient_num"])
patient_num.seq4=unique(res.seq[res.seq$length>=4,"patient_num"])

if(setting=="High D-dimer Low Platelet"){
dat.sel=dat.complete[dat.complete$ddmer>ddmer.cut & dat.complete$pltt<pltt.cut, ]}
if(setting=="High D-dimer"){
dat.sel=dat.complete[dat.complete$ddmer>ddmer.cut, ]}
if(setting=="Low Platelet"){
dat.sel=dat.complete[dat.complete$pltt<pltt.cut, ]}

patient_num.sel.list=unique(dat.sel$patient_num)
if(sex.group!="female+male"){
patient_num.sel.list=intersect(patient_num.sel.list, LocalPatientSummary$patient_num[LocalPatientSummary$sex==sex.group])}

res.sel.seq=do.call(rbind,lapply(patient_num.sel.list, function(patient_num){
  dat.tmp=dat.sel[dat.sel$patient_num==patient_num,]
  res=search.seq.fun(dat.tmp)
  res=data.frame(patient_num, res)
}))
patient_num.sel.seq1=unique(res.sel.seq[res.sel.seq$length>=1,"patient_num"])
patient_num.sel.seq2=unique(res.sel.seq[res.sel.seq$length>=2,"patient_num"])
patient_num.sel.seq3=unique(res.sel.seq[res.sel.seq$length>=3,"patient_num"])
patient_num.sel.seq4=unique(res.sel.seq[res.sel.seq$length>=4,"patient_num"])

dat.summary=LocalPatientSummary
dat.summary$race[dat.summary$race%in%c("white", "black")!=1]="other"
if(sex.group!="female+male"){
dat.summary=dat.summary[dat.summary$sex%in%sex.group,]}

if(length(unique(dat.summary$sex))>1){
df=dat.summary[,c("sex", "age_group", "race")]
}else{
df=dat.summary[,c("age_group", "race")]
}
df=mutate_if(df, is.character, as.factor)
if(length(unique(dat.summary$sex))>1){
dat.dem=model.matrix(~sex+age_group+race,data=df,contrasts.arg=lapply(df, contrasts,contrasts=F))[,-1]
}else{
dat.dem=model.matrix(~age_group+race,data=df,contrasts.arg=lapply(df, contrasts,contrasts=F))[,-1]
}
dat.summary=data.frame(dat.summary, dat.dem)
dat.summary$severedeceased=ifelse((dat.summary$deceased+dat.summary$severe)>0,1,0)
col.check=c("deceased", "severe", "severedeceased",colnames(dat.dem))
mytable=NULL
for(myseq in c(0:4)){
if(myseq==0){patient_num.check=unique(dat.summary$patient_num)}else{
patient_num.check=get(paste0("patient_num.sel.seq",myseq))
}
dat.check=dat.summary[dat.summary$patient_num%in%patient_num.check,]
tmp=colMeans(dat.check[,col.check])
mytable=rbind(mytable, c(n=length(patient_num.check),tmp))
}
mytable= data.frame(consecutive_day=c(0,1,2,3,4), mytable)
mytable$n[mytable$n<obfuscation.level]=-99

rownames(mytable)=NULL
mytable[,c("n",col.check)]=apply(mytable[,c("n",col.check)], 2,as.numeric)
if(setting=="High D-dimer Low Platelet"){file.nm=file.path(dir.output, paste0("High_ddmer_Low_pltt_", sex.group,"_cut",pltt.cut, ".pdf"))}
if(setting=="High D-dimer"){file.nm=file.path(dir.output, paste0("High_ddmer_", sex.group, "_cut",pltt.cut,".pdf"))}
if(setting=="Low Platelet"){file.nm=file.path(dir.output, paste0("Low_pltt_", sex.group, "_cut",pltt.cut,".pdf"))}

pdf(file=file.nm, height=22, width=12)
par(mfrow=c(6,1))
mytable=mytable[,c("n",col.check)]
myN=mytable$n
myN[myN<0]="<11"
mytable$n=mytable$n/mytable$n[1]
mytable=data.matrix(mytable)
colnames(mytable)=gsub("_group", "", colnames(mytable))
barplot(mytable, beside=T,las=2, ylim=c(0,1.05),col=c("blue", "yellow", "orange", "red", "darkred"), ylab="prevalence", main=paste0(currSiteId, ": ", sex.group, ";", setting))
if(setting=="High D-dimer Low Platelet"){
legend("topleft", c(paste0("all patients: ",myN[1]), 
                    paste0("high D-dimer and low Platelet for >=1 consecutive day: ",myN[2]),
                    paste0("high D-dimer and low Platelet for >=2 consecutive days: ",myN[3]),
                    paste0("high D-dimer and low Platelet for >=3 consecutive days: ",myN[4]),
                    paste0("high D-dimer and low Platelet for >=4 consecutive days: ",myN[5])
                    ), col=c("blue", "yellow", "orange", "red", "darkred"), pch=15)
}
if(setting=="High D-dimer"){
legend("topleft", c(paste0("all patients: ",myN[1]), 
                    paste0("high D-dimer for >=1 consecutive day: ",myN[2]),
                    paste0("high D-dimer for >=2 consecutive days: ",myN[3]),
                    paste0("high D-dimer for >=3 consecutive days: ",myN[4]),
                    paste0("high D-dimer for >=4 consecutive days: ",myN[5])
), col=c("blue", "yellow", "orange", "red", "darkred"), pch=15)
}
if(setting=="Low Platelet"){
legend("topleft", c(paste0("all patients: ",myN[1]), 
                    paste0("low Platelet for >=1 consecutive day: ",myN[2]),
                    paste0("low Platelet for >=2 consecutive days: ",myN[3]),
                    paste0("low Platelet for >=3 consecutive days: ",myN[4]),
                    paste0("low Platelet for >=4 consecutive days: ",myN[5])
), col=c("blue", "yellow", "orange", "red", "darkred"), pch=15)
}
dev.off()
}
}

