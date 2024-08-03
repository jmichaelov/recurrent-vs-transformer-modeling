library(tidyverse)
library(scales)
library(grid)

all_AICs=read_tsv("all_AICs.tsv")%>%
  left_join(read_tsv("perplexities.tsv"))%>%
  mutate(ModelArchitecture = fct_recode(ModelArchitecture,
                                        "Mamba"="mamba",
                                        "RWKV"="rwkv",
                                        "Pythia"="pythia"))%>%
  mutate(ModelArchitecture = fct_relevel(ModelArchitecture,
                                        "Pythia","Mamba","RWKV"))
  


reading_time_datasets = c("Boyce & Levy (2023): Maze RT",
                               "Brothers & Kuperberg (2021): 3W-RT",
                               "Futrell et al. (2021): SPR RT",
                               "Kennedy et al. (2003): GPD",
                               "Luke & Christianson (2018): GPD",
                               "Smith and Levy (2013): SPR RT")

n400_datasets = c("Michaelov et al. (2024)",
                  "Federmeier et al. (2007)",
                  "Wlotko & Federmeier (2012)",
                  "Szewczyk et al. (2022)",
                  "Hubbard et al. (2019)",
                  "Szewczyk & Federmeier (2022)" )


n400_fig = all_AICs%>%drop_na()%>%
  filter(Dataset %in% n400_datasets)%>%
  mutate(ModelSize=as.numeric(ModelSize))%>%
  ggplot(aes(x=ModelSize,y=Surprisal_AIC,color=ModelArchitecture)) + geom_point() + geom_line() + 
  ylab("Fit to N400 data (AIC)") + facet_wrap(.~Dataset,scales="free_y") +
  coord_cartesian(xlim = c(100000000, 4000000000))+  
  scale_x_log10(name="Number of Model Parameters",
                breaks = trans_breaks('log10', function(x) 10^x),
                labels = trans_format('log10', math_format(10^.x))) +
  scale_colour_manual(name="Model",values=c("#D55E00","#009E73","#0072B2"))

n400_fig


n400_fig_perplexity = all_AICs%>%drop_na()%>%
  filter(Dataset %in% n400_datasets)%>%
  mutate(ModelSize=as.numeric(ModelSize))%>%
  ggplot(aes(x=Perplexity,y=Surprisal_AIC,color=ModelArchitecture)) + geom_point() + geom_line() + 
  ylab("Fit to N400 data (AIC)") + facet_wrap(.~Dataset,scales="free_y") +
  scale_x_continuous(name="Perplexity",trans = c("log10", "reverse")) +
  scale_colour_manual(name="Model",values=c("#D55E00","#009E73","#0072B2"))
n400_fig_perplexity


n400_combined = grid.arrange(textGrob("(A) Model performance on N400 data by model size"),
                             n400_fig,
                             textGrob(""),
                             textGrob("(B) Model performance on N400 data by perplexity"),
                             n400_fig_perplexity,
                             ncol=1,heights=c(0.06,1,0.05,0.1,1))
ggsave("n400_combined.pdf",n400_combined,width=9.5,height=6.5)







rt_dlsl_fig = all_AICs%>%drop_na()%>%
  filter(Dataset %in% reading_time_datasets)%>%
  mutate(ModelSize=as.numeric(ModelSize))%>%
  ggplot(aes(x=ModelSize,y=Surprisal_AIC,color=ModelArchitecture)) + geom_point() + geom_line() + 
  ylab("Fit to Reading Time (AIC)") + facet_wrap(.~Dataset,scales="free_y") +
  coord_cartesian(xlim = c(100000000, 4000000000))+
  scale_x_log10(name="Number of Parameters",
                breaks = trans_breaks('log10', function(x) 10^x),
                labels = trans_format('log10', math_format(10^.x)))  +
  scale_colour_manual(name="Model",values=c("#D55E00","#009E73","#0072B2"))
rt_dlsl_fig

rt_dlsl_fig_perplexity = all_AICs%>%drop_na()%>%
  filter(Dataset %in% reading_time_datasets)%>%
  mutate(ModelSize=as.numeric(ModelSize))%>%
  ggplot(aes(x=Perplexity,y=Surprisal_AIC,color=ModelArchitecture)) + geom_point() + geom_line() + 
  ylab("Fit to Reading Time (AIC)") + facet_wrap(.~Dataset,scales="free_y") +
  scale_x_continuous(name="Perplexity",trans = c("log10", "reverse"))+
  scale_colour_manual(name="Model",values=c("#D55E00","#009E73","#0072B2"))
rt_dlsl_fig_perplexity



rt_combined = grid.arrange(textGrob("(A) Model performance on reading time data by model size"),
                           rt_dlsl_fig,
                           textGrob(""),
                           textGrob("(B) Model performance on reading time data by perplexity"),
                           rt_dlsl_fig_perplexity,
                           ncol=1,heights=c(0.1,1,0.1,0.1,1))
ggsave("rt_combined.pdf",rt_combined,width=9.5,height=6.5)






all_AICs%>%
  distinct(ModelArchitecture,ModelSize,Perplexity)%>%mutate(ModelSize=as.numeric(ModelSize))%>%
  group_by(ModelArchitecture)%>%
  summarize(r = cor(ModelSize,Perplexity,method="pearson"),rho= cor(ModelSize,Perplexity,method="spearman"))

scale_perplexity = all_AICs%>%
  distinct(ModelArchitecture,ModelSize,Perplexity)%>%mutate(ModelSize=as.numeric(ModelSize))%>%
  group_by(ModelArchitecture)%>%
  ggplot(aes(x=ModelSize,y=Perplexity,color=ModelArchitecture)) + geom_point() + geom_line() +
  coord_cartesian(xlim = c(100000000, 4000000000))+
  scale_x_log10(name="Number of Model Parameters",
                breaks = trans_breaks('log10', function(x) 10^x),
                labels = trans_format('log10', math_format(10^.x))) +
  scale_y_log10(name="Perplexity") +
  scale_colour_manual(name="Model",values=c("#D55E00","#009E73","#0072B2"))

ggsave("scale_perplexity.pdf",scale_perplexity,width=4.5,height=2.5)


