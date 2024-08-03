library(tidyverse)
library(scales)

all_AICs=read_tsv("all_AICs.tsv")%>%
  left_join(read_tsv("perplexities.tsv"))%>%
   filter(!str_detect(Dataset,"Sentence-"))%>%
   mutate(ModelArchitecture = fct_relevel(ModelArchitecture,
                                          "pythia","rwkv","mamba" ))

all_results_df = tibble(analysis=factor(),df=numeric(),dataset = factor(),term=factor(),estimate=numeric(), std.error=numeric(), statistic=numeric(),p.value=numeric())

for (dataset in unique(all_AICs$Dataset)){
   
   scale_regression = lm(data=all_AICs%>%filter(Dataset==dataset),formula = scale(Surprisal_AIC) ~ scale(log(ModelSize))+ModelArchitecture)
   
   all_results_df = all_results_df%>%
      add_row(scale_regression%>%
                 broom::tidy()%>%
                 mutate(dataset=dataset,
                        df = scale_regression$df.residual,
                        analysis="Model Scale"))
   
   perplexity_regression = lm(data=all_AICs%>%filter(Dataset==dataset),formula = scale(Surprisal_AIC) ~ scale(-log(Perplexity))+ModelArchitecture)
   all_results_df = all_results_df%>%
      add_row(perplexity_regression%>%
                 broom::tidy()%>%
                 mutate(dataset=dataset,
                        df = scale_regression$df.residual,
                        analysis="Quality"))
}

all_results_df=all_results_df%>%
   mutate(p.corrected = p.adjust(p.value,method="BY"))%>%
   mutate(term = fct_recode(term,
                            "Intercept"="(Intercept)",
                            "Scale"="scale(log(ModelSize))",
                            "Mamba"="ModelArchitecturemamba",
                            "RWKV"="ModelArchitecturerwkv",
                            "Perplexity"="scale(-log(Perplexity))"))%>%
   mutate(term = fct_relevel(term,
                            "Intercept",
                            "Mamba",
                            "RWKV",
                            "Scale",
                            "Perplexity"))%>%
   arrange(analysis,dataset,term)%>%
   rename("Dataset"="dataset",
          "Analysis"="analysis",
          "Predictor"="term",
          "Estimate"="estimate",
          "SE" = "std.error",
          "t"="statistic",
          "p.corrected"="p.corrected",
          "p.value"="p.value")

all_results_df%>%
   mutate(Estimate=round(Estimate,4),
          SE = round(SE,4),
          t = round(t,4),
          p = case_when(p.corrected < 0.0001 ~ "< 0.0001",
                        TRUE ~ as.character(round(p.corrected,4))),
          p_uncorrected = case_when(p.value < 0.0001 ~ "< 0.0001",
                        TRUE ~ as.character(round(p.value,4)))
          )%>%
   select(-p.corrected,-p.value)%>%
   write_tsv("all_AIC_analyses_incl_correction.tsv")

