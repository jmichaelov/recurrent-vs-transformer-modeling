import json
import pandas as pd
import os

all_results = pd.DataFrame()
folder="../perplexities/"
subfolders = os.listdir(folder)
for subfolder in subfolders:
    subfolder_path = "/".join([folder,subfolder])
    subsubfolders = os.listdir(subfolder_path)
    for subsubfolder in subsubfolders:
        file_path =  "/".join([subfolder_path,subsubfolder,"results.json"])


        with open(file_path) as f:
            results_json = json.load(f)
            results_df = pd.DataFrame(results_json["results"])    
            results_df.index=results_df.index.str.split(",").str[0]
            results_df = results_df.transpose().reset_index()
            results_df=results_df[["word_perplexity"]].rename({"word_perplexity":"Perplexity"},axis=1)
            

            model_info = results_json['config']["model_args"].split(",")
            model_name = model_info[0].split("/")[-1].replace(".","_")
            results_df["ModelName"]=model_name

            all_results = pd.concat([all_results,results_df])
                
all_results = all_results.reset_index(drop=True)
all_results = all_results[["ModelName","Perplexity"]]

all_results.to_csv("../statistics/perplexities.tsv",sep="\t",index=False)
