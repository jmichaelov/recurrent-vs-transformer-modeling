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

file_list = list.files("../results/")
all_AICs_scaling = tibble(Dataset = factor(), ModelName = factor(), ModelArchitecture=factor(), ModelSize=factor(), Surprisal_AIC=numeric())




# Michaelov et al. (2024)

michaelov_data = read_tsv("../cleaned_datasets/michaelov_2024.tsv")

all_data_cleaned = michaelov_data


for (i in file_list){
  if (str_detect(i,"michaelov")){
    
    current_dataset = all_data_cleaned
    results = read_tsv(paste("../results/",i,sep=""))%>%select(FullSentence,Surprisal)
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
all_AICs_scaling%>%write_tsv("all_AICs.tsv")



# Szewczyk and Federmeier (2022)

szewczyk_data= read_tsv("../cleaned_datasets/szewczyk_2022.tsv")

all_data_cleaned = szewczyk_data


for (i in file_list){
  if (str_detect(i,"szewczyk")){
    
    current_dataset = all_data_cleaned
    results = read_tsv(paste("../results/",i,sep=""))%>%select(FullSentence,Surprisal)
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
all_AICs_scaling%>%write_tsv("all_AICs.tsv")



# Brothers and Kuperberg (2021)

brothers_data = read_tsv("../cleaned_datasets/brothers_2021.tsv")


all_data_cleaned = brothers_data%>%
  mutate(SUB=as_factor(SUB),
         ITEM = as_factor(ITEM))


for (i in file_list){
  if (str_detect(i,"brothers")){
    
    current_dataset = all_data_cleaned%>%distinct()
    results = read_tsv(paste("../results/",i,sep=""))%>%
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
all_AICs_scaling%>%write_tsv("all_AICs.tsv")



# Luke and Christianson (2018)

provo_et_data = read_tsv("../cleaned_datasets/luke_2018.tsv")%>%drop_na()

all_data_cleaned = provo_et_data


for (i in file_list){
  if (str_detect(i,"luke_2018_dl")){
    
    current_dataset = all_data_cleaned%>%distinct()
    results = read_tsv(paste("../results/",i,sep=""))%>%
      select(FullSentence,Surprisal,TargetWords)%>%
      distinct()%>%
      rename("FullSentence_DocLevel" = "FullSentence")
    if ((!(Inf %in% results$Surprisal))&(!(NA %in% results$Surprisal))){
      
      
      
      current_dataset = current_dataset%>%
        inner_join(results,by=c("FullSentence_DocLevel","TargetWords"))
      
      surprisal_AIC_model = lmer(scale(log(fdurGP)) ~ scale(Surprisal) + scale(wdelta) + scale(wlen) + scale(unigramsurp) + scale(sentpos) + prev_fix_in_sent + (1+scale(Surprisal) + scale(wdelta) + scale(wlen) + scale(unigramsurp) + scale(sentpos) + prev_fix_in_sent||subject) + (1|docid:sentid), data = current_dataset,  REML=F, control=lmerControl(optimizer="bobyqa"))
      surprisal_AIC_value = surprisal_AIC_model%>%AIC
      
      
      model_name_full =str_remove(str_split_1(i,"__")[2],".causal.output")
      model_architecture = model_names[model_name_full]
      model_size = model_sizes[model_name_full]
      
      all_AICs_scaling = all_AICs_scaling%>%
        add_row(tibble(Dataset="Luke & Christianson (2018): GPD", ModelName = model_name_full, ModelArchitecture=model_architecture, ModelSize=model_size,Surprisal_AIC=surprisal_AIC_value))
    }}}

all_AICs_scaling = all_AICs_scaling%>%arrange(Dataset,ModelName)
all_AICs_scaling%>%write_tsv("all_AICs.tsv")


# Boyce and Levy (2023)

futrell_dl = read_tsv("../cleaned_stimuli/futrell_2018_dl.tsv")

futrell_stims = futrell_dl%>%select(-FullSentenceMarked)

natstor_maze_data = read_tsv("../cleaned_datasets/boyce_2023.tsv")%>%drop_na()%>%
  inner_join(futrell_stims)

all_data_cleaned = natstor_maze_data

for (i in file_list){
  if (str_detect(i,"futrell_2018_dl")){
    
    current_dataset = all_data_cleaned%>%distinct()
    results = read_tsv(paste("../results/",i,sep=""))%>%
      select(FullSentence,Surprisal,TargetWords)%>%
      distinct()
    if ((!(Inf %in% results$Surprisal))&(!(NA %in% results$Surprisal))){
      
      
       # dropped (unigramsurp||subject) random slope due to singular fits
      current_dataset = current_dataset%>%
        inner_join(results,by=c("FullSentence"))%>%select(-FullSentence)
      surprisal_AIC_model = lmer(scale(log(rt)) ~ scale(Surprisal) + scale(wlen) + scale(unigramsurp) +scale(sentpos) + (1+scale(Surprisal) + scale(wlen) + scale(sentpos) ||subject) + (1|docid:sentid), data = current_dataset,  REML=F, control=lmerControl(optimizer="bobyqa"))
      
     
      surprisal_AIC_value = surprisal_AIC_model%>%AIC
      
      model_name_full =str_remove(str_split_1(i,"__")[2],".causal.output")
      model_architecture = model_names[model_name_full]
      model_size = model_sizes[model_name_full]
      
      all_AICs_scaling = all_AICs_scaling%>%
        add_row(tibble(Dataset="Boyce & Levy (2023): Maze RT", ModelName = model_name_full, ModelArchitecture=model_architecture, ModelSize=model_size, Surprisal_AIC=surprisal_AIC_value))
    }}}

all_AICs_scaling = all_AICs_scaling%>%arrange(Dataset,ModelName)
all_AICs_scaling%>%write_tsv("all_AICs.tsv")



#Futrell et al. (2021)

futrell_stims = read_tsv("../cleaned_stimuli/futrell_2018_dl.tsv")%>%select(-FullSentenceMarked)

natstor_spr_data = read_tsv("../cleaned_datasets/futrell_2021.tsv")%>%drop_na()%>%
  inner_join(futrell_stims)

all_data_cleaned = natstor_spr_data


for (i in file_list){
  if (str_detect(i,"futrell_2018_dl")){
    
    current_dataset = all_data_cleaned%>%distinct()
    results = read_tsv(paste("../results/",i,sep=""))%>%
      select(FullSentence,Surprisal,TargetWords)%>%
      distinct()
    if ((!(Inf %in% results$Surprisal))&(!(NA %in% results$Surprisal))){
      
      
      
      current_dataset = current_dataset%>%
        inner_join(results,by=c("FullSentence"))%>%select(-FullSentence)
      surprisal_AIC_model = lmer(scale(log(fdur)) ~ scale(Surprisal) + scale(wlen) + scale(unigramsurp) +scale(sentpos) + (1+scale(Surprisal) + scale(wlen) + scale(sentpos) + scale(unigramsurp) ||subject) + (1|docid:sentid), data = current_dataset,  REML=F, control=lmerControl(optimizer="bobyqa"))
      
      surprisal_AIC_value = surprisal_AIC_model%>%AIC
      
      model_name_full =str_remove(str_split_1(i,"__")[2],".causal.output")
      model_architecture = model_names[model_name_full]
      model_size = model_sizes[model_name_full]
      
      all_AICs_scaling = all_AICs_scaling%>%
        add_row(tibble(Dataset="Futrell et al. (2021): SPR RT", ModelName = model_name_full, ModelArchitecture=model_architecture, ModelSize=model_size, Surprisal_AIC=surprisal_AIC_value))
    }}}

all_AICs_scaling = all_AICs_scaling%>%arrange(Dataset,ModelName)
all_AICs_scaling%>%write_tsv("all_AICs.tsv")



# Kennedy et al. (2003)


dundee_data = read_tsv("../cleaned_datasets/kennedy_2003.tsv")%>%drop_na()%>%
  left_join(read_tsv("../cleaned_stimuli/kennedy_2003.tsv")%>%select(docid,sentid,sentpos,FullSentence))

all_data_cleaned = dundee_data


for (i in file_list){
  if (str_detect(i,"kennedy")){
    
    current_dataset = all_data_cleaned%>%distinct()
    results = read_tsv(paste("../results/",i,sep=""))%>%
      select(FullSentence,Surprisal,TargetWords)%>%
      distinct()
    if ((!(Inf %in% results$Surprisal))&(!(NA %in% results$Surprisal))){
      
      
      
      current_dataset = current_dataset%>%
        inner_join(results,by=c("FullSentence"))%>%select(-FullSentence)
      
      surprisal_AIC_model = lmer(scale(log(fdurGP)) ~ scale(Surprisal) + scale(wdelta) + scale(wlen) + scale(unigramsurp) + scale(sentpos) + prev_fix_in_sent + (1+scale(Surprisal) + scale(wdelta) + scale(wlen) + scale(unigramsurp) + scale(sentpos) + prev_fix_in_sent||subject) + (1|docid:sentid), data = current_dataset,  REML=F, control=lmerControl(optimizer="bobyqa"))
      surprisal_AIC_value = surprisal_AIC_model%>%AIC
      
      
      model_name_full =str_remove(str_split_1(i,"__")[2],".causal.output")
      model_architecture = model_names[model_name_full]
      model_size = model_sizes[model_name_full]
      
      all_AICs_scaling = all_AICs_scaling%>%
        add_row(tibble(Dataset="Kennedy et al. (2003): GPD", ModelName = model_name_full, ModelArchitecture=model_architecture, ModelSize=model_size,Surprisal_AIC=surprisal_AIC_value))
    }}}

all_AICs_scaling = all_AICs_scaling%>%arrange(Dataset,ModelName)
all_AICs_scaling%>%write_tsv("all_AICs.tsv")






# Smith and Levy (2013)

smith_stims = read_tsv("../cleaned_stimuli/smith_2013.tsv")%>%
  select(-FullSentence,-FullSentenceMarked,-FullDocumentMarked)%>%
  rename("FullSentence"="FullDocument")

brown_spr_data = read_tsv("../cleaned_datasets/smith_2013.tsv")%>%drop_na()%>%
  inner_join(smith_stims)

all_data_cleaned = brown_spr_data


for (i in file_list){
  if (str_detect(i,"smith_2013")){
    
    current_dataset = all_data_cleaned%>%distinct()
    results = read_tsv(paste("../results/",i,sep=""))%>%
      select(FullSentence,Surprisal,TargetWords)%>%
      distinct()
    if ((!(Inf %in% results$Surprisal))&(!(NA %in% results$Surprisal))){
      
      current_dataset = current_dataset%>%
        inner_join(results,by=c("FullSentence"))%>%select(-FullSentence)
      surprisal_AIC_model = lmer(scale(log(fdur)) ~ scale(Surprisal) + scale(wlen) + scale(unigramsurp) +scale(sentpos) + (1+scale(Surprisal) + scale(wlen) + scale(sentpos) + scale(unigramsurp) ||subject) + (1|docid:sentid), data = current_dataset,  REML=F, control=lmerControl(optimizer="bobyqa"))
    
      surprisal_AIC_value = surprisal_AIC_model%>%AIC
      
      model_name_full =str_remove(str_split_1(i,"__")[2],".causal.output")
      model_architecture = model_names[model_name_full]
      model_size = model_sizes[model_name_full]
      
      all_AICs_scaling = all_AICs_scaling%>%
        add_row(tibble(Dataset="Smith and Levy (2013): SPR RT", ModelName = model_name_full, ModelArchitecture=model_architecture, ModelSize=model_size, Surprisal_AIC=surprisal_AIC_value))
    }}}

all_AICs_scaling = all_AICs_scaling%>%arrange(Dataset,ModelName)
all_AICs_scaling%>%write_tsv("all_AICs.tsv")
