library(tidyverse)

all_aics = read_tsv("all_AICs_michaelov.tsv")%>%
  add_row(read_tsv("all_AICs_szewczyk.tsv"))%>%
  add_row(read_tsv("all_AICs_brothers.tsv"))%>%
  add_row(read_tsv("all_AICs_smith.tsv"))%>%
  add_row(read_tsv("all_AICs_kennedy.tsv"))%>%
  add_row(read_tsv("all_AICs_futrell.tsv"))%>%
  add_row(read_tsv("all_AICs_boyce.tsv"))%>%
  add_row(read_tsv("all_AICs_luke.tsv"))


all_aics%>%arrange(Dataset,ModelName)%>%
  write_tsv("../all_AICs.tsv")