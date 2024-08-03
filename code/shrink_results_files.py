import pandas as pd
import os
import csv

stim_dir = "../cleaned_stimuli/"
results_dir = "../results/"



futrell_stims = pd.read_csv("../cleaned_stimuli/futrell_2018_dl.tsv",sep="\t")

luke_stims = pd.read_csv("../cleaned_stimuli/luke_2018.tsv",sep="\t",doublequote=False,escapechar=None,quoting=csv.QUOTE_NONE)
luke_stims = luke_stims[["Word_Unique_ID","FullSentence_DocLevel"]].rename({"FullSentence_DocLevel":"FullSentence"},axis=1)

kennedy_stims = pd.read_csv("../cleaned_stimuli/kennedy_2003.tsv",sep="\t")

smith_stims = pd.read_csv("../cleaned_stimuli/smith_2013.tsv",sep="\t")
smith_stims = smith_stims[["docid","sentid","sentpos","FullDocument"]].rename({"FullDocument":"FullSentence"},axis=1)





for results_file_name in os.listdir(results_dir):
    content = pd.read_csv(results_dir+results_file_name,sep="\t")
    if "futrell_2018" in results_file_name:
        content = content.merge(futrell_stims,how="inner",on="FullSentence")
        content = content[["docid","sentid","sentpos","Surprisal","NumTokens"]].dropna()
    elif "smith_2013" in results_file_name:
        content = content.merge(smith_stims,how="inner",on="FullSentence")
        content = content[["docid","sentid","sentpos","Surprisal","NumTokens"]].dropna()
    elif "luke_2018" in results_file_name:
        content = content.merge(luke_stims,how="inner",on="FullSentence")
        content = content[["Word_Unique_ID","Surprisal","NumTokens"]].dropna()
    elif "kennedy_2003" in results_file_name:
        content = content.merge(kennedy_stims,how="inner",on="FullSentence")
        content = content[["docid","sentid","sentpos","Surprisal","NumTokens"]].dropna()
    content.to_csv(results_dir+results_file_name,sep="\t",doublequote=False,escapechar=None,quoting=csv.QUOTE_NONE,index=False)