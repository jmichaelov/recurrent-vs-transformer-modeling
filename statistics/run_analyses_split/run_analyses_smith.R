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


# Smith and Levy (2013)

all_data_cleaned = read_tsv("../../cleaned_datasets/smith_2013.tsv")%>%drop_na()

for (i in file_list){
  if (str_detect(i,"smith_2013")){
    
    current_dataset = all_data_cleaned%>%distinct()
    results = read_tsv(paste("../../results/",i,sep=""))%>%
      distinct()
    if ((!(Inf %in% results$Surprisal))&(!(NA %in% results$Surprisal))){
      
      current_dataset = current_dataset%>%
        inner_join(results)
      
      surprisal_AIC_model = lmer(scale(log(fdur)) ~ scale(Surprisal) + scale(wlen) + scale(unigramsurp) +scale(sentpos) + (1+ scale(Surprisal) + scale(wlen) + scale(sentpos) + scale(unigramsurp) ||subject) + (1|docid:sentid), data = current_dataset,  REML=F, control=lmerControl(optimizer="bobyqa"))
      summary(surprisal_AIC_model)
      
      surprisal_AIC_value = surprisal_AIC_model%>%AIC
      
      model_name_full =str_remove(str_split_1(i,"__")[2],".causal.output")
      model_architecture = model_names[model_name_full]
      model_size = model_sizes[model_name_full]
      
      all_AICs_scaling = all_AICs_scaling%>%
        add_row(tibble(Dataset="Smith and Levy (2013): SPR RT", ModelName = model_name_full, ModelArchitecture=model_architecture, ModelSize=model_size, Surprisal_AIC=surprisal_AIC_value))
    }}}

all_AICs_scaling = all_AICs_scaling%>%arrange(Dataset,ModelName)
all_AICs_scaling%>%write_tsv("all_AICs_smith.tsv")
