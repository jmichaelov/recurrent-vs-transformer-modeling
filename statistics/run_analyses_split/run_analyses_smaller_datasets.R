library(tidyverse)
library(lme4)

model_names = c("pythia-1_4b"="pythia","pythia-160m"="pythia","pythia-2_8b"="pythia","pythia-410m"="pythia","pythia-70m"="pythia","pythia-1b"="pythia",
                "mamba-130m-hf"="mamba","mamba-1_4b-hf"="mamba","mamba-2_8b-hf"="mamba","mamba-370m-hf"="mamba","mamba-790m-hf"="mamba",
                "rwkv-4-169m-pile"="rwkv","rwkv-4-1b5-pile"="rwkv","rwkv-4-3b-pile"="rwkv","rwkv-4-430m-pile"="rwkv")
model_sizes = c("pythia-1_4b"="1414647808",
                "pythia-160m"="162322944",
                "pythia-2_8b"="2775208960",
                "pythia-410m"="405334016",
                "pythia-1b"="1011781632",
                "mamba-130m-hf"="129135360",
                "mamba-1_4b-hf"="1372178432",
                "mamba-2_8b-hf"="2768345600",
                "mamba-370m-hf"="371516416",
                "mamba-790m-hf"="793204224",
                "rwkv-4-169m-pile"="169342464",
                "rwkv-4-1b5-pile"="1515106304",
                "rwkv-4-3b-pile"="2984627200",
                "rwkv-4-430m-pile"="430397440") 

file_list = list.files("../../results/")
all_AICs_scaling = tibble(Dataset = factor(), ModelName = factor(), ModelArchitecture=factor(), ModelSize=factor(), Surprisal_AIC=numeric())




# Michaelov et al. (2024)

michaelov_data = read_tsv("../../cleaned_datasets/michaelov_2024.tsv")

all_data_cleaned = michaelov_data


for (i in file_list){
  if (str_detect(i,"michaelov")){
    
    current_dataset = all_data_cleaned
    results = read_tsv(paste("../../results/",i,sep=""))%>%select(FullSentence,Surprisal)
    if ((!(Inf %in% results$Surprisal))&(!(NA %in% results$Surprisal))){
      
      
      current_dataset = current_dataset%>%
        inner_join(results)
      
      # original random effects structure
      surprisal_AIC_model= lmer(scale(N400) ~ scale(Surprisal)  + scale(ZipfFrequency) + scale(ON) + (1 | Subject) +(1| ContextCode) + (1|TargetWords)+(1|Electrode),
                                data=current_dataset, REML=F, control=lmerControl(optimizer="bobyqa"))
      
      surprisal_AIC_value=surprisal_AIC_model%>%AIC
      
      model_name_full =str_remove(str_split_1(i,"__")[2],".causal.output")
      model_architecture = model_names[model_name_full]
      model_size = model_sizes[model_name_full]
      
      all_AICs_scaling = all_AICs_scaling%>%
        add_row(tibble(Dataset="Michaelov et al. (2024)", ModelName = model_name_full, ModelArchitecture=model_architecture, ModelSize=model_size,Surprisal_AIC=surprisal_AIC_value))
    }}}

all_AICs_scaling = all_AICs_scaling%>%arrange(Dataset,ModelName)
all_AICs_scaling%>%write_tsv("all_AICs_michaelov.tsv")



# Szewczyk and Federmeier (2022)

all_AICs_scaling = tibble(Dataset = factor(), ModelName = factor(), ModelArchitecture=factor(), ModelSize=factor(), Surprisal_AIC=numeric())


szewczyk_data= read_tsv("../../cleaned_datasets/szewczyk_2022.tsv")

all_data_cleaned = szewczyk_data


for (i in file_list){
  if (str_detect(i,"szewczyk")){
    
    current_dataset = all_data_cleaned
    results = read_tsv(paste("../../results/",i,sep=""))%>%select(FullSentence,Surprisal)
    for (current_dataset_name in all_data_cleaned$dataset%>%unique){
      if ((!(Inf %in% results$Surprisal))&(!(NA %in% results$Surprisal))){
        
        current_dataset = all_data_cleaned%>%filter(dataset==current_dataset_name)
        
        current_dataset = current_dataset%>%
          inner_join(results)
        
        # removed until non-singular fit
        
        surprisal_AIC_model= lmer(scale(n400) ~ scale(bline) + scale(Surprisal)  + scale(logfreq) + scale(pos_start) + scale(old20)  + scale(concr)+
                                    (1+ scale(bline) + scale(pos_start)||Subject) +
                                    (1+ scale(bline)||Item),
                                  data=current_dataset, REML=F, control=lmerControl(optimizer="bobyqa"))
        
        surprisal_AIC_value=surprisal_AIC_model%>%AIC
        
        model_name_full =str_remove(str_split_1(i,"__")[2],".causal.output")
        model_architecture = model_names[model_name_full]
        model_size = model_sizes[model_name_full]
        
        all_AICs_scaling = all_AICs_scaling%>%
          add_row(tibble(Dataset=current_dataset_name, ModelName = model_name_full, ModelArchitecture=model_architecture, ModelSize=model_size, Surprisal_AIC=surprisal_AIC_value))
      }}}}

all_AICs_scaling = all_AICs_scaling%>%arrange(Dataset,ModelName)
all_AICs_scaling%>%write_tsv("all_AICs_szewczyk.tsv")



# Brothers and Kuperberg (2021)

all_AICs_scaling = tibble(Dataset = factor(), ModelName = factor(), ModelArchitecture=factor(), ModelSize=factor(), Surprisal_AIC=numeric())


brothers_data = read_tsv("../../cleaned_datasets/brothers_2021.tsv")


all_data_cleaned = brothers_data%>%
  mutate(SUB=as_factor(SUB),
         ITEM = as_factor(ITEM))


for (i in file_list){
  if (str_detect(i,"brothers")){
    
    current_dataset = all_data_cleaned%>%distinct()
    results = read_tsv(paste("../../results/",i,sep=""))%>%
      select(FullSentence,Surprisal,TargetWords)%>%
      distinct()
    if ((!(Inf %in% results$Surprisal))&(!(NA %in% results$Surprisal))){
      
      
      
      current_dataset = current_dataset%>%
        inner_join(results,by=c("FullSentence"))
      
      surprisal_AIC_model = lmer(scale(SUM_3RT_trimmed) ~ scale(Surprisal) +  (scale(Surprisal)|SUB) + (scale(Surprisal)|ITEM), data = current_dataset,  REML=F, control=lmerControl(optimizer="bobyqa"))
      
      surprisal_AIC_value = surprisal_AIC_model%>%AIC
      
      model_name_full =str_remove(str_split_1(i,"__")[2],".causal.output")
      model_architecture = model_names[model_name_full]
      model_size = model_sizes[model_name_full]
      
      all_AICs_scaling = all_AICs_scaling%>%
        add_row(tibble(Dataset="Brothers & Kuperberg (2021): 3W-RT", ModelName = model_name_full, ModelArchitecture=model_architecture, ModelSize=model_size, Surprisal_AIC=surprisal_AIC_value))
    }}}


all_AICs_scaling = all_AICs_scaling%>%arrange(Dataset,ModelName)
all_AICs_scaling%>%write_tsv("all_AICs_brothers.tsv")