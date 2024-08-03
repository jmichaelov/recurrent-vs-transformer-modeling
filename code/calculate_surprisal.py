import os
import argparse
from transformers import AutoTokenizer,AutoModelForCausalLM,AutoModelForMaskedLM, AutoConfig
from torch.nn import functional as F
import torch
import numpy as np
import copy
import re
from huggingface_hub import list_models
from collections import defaultdict


def parse_args():
    parser = argparse.ArgumentParser(description='Calculates surprisal and other \
                                    metrics (in development) of transformers language models')

    parser.add_argument('--stimuli', '-i', type=str,
                        help='stimuli to test')
    parser.add_argument('--stimuli_list', '-ii', type=str,
                        help='path to file containing list of stimulus files to test')
    parser.add_argument('--output_directory','-o', type=str, required = True,
                        help='output directory')
    parser.add_argument('--primary_decoder','-d', type=str, default='masked',
                        help='for models with both masked and causal versions, determine which to use (default is masked)')
    parser.add_argument('--model','-m', type=str,
                        help='select a model to use')
    parser.add_argument('--model_list','-mm', type=str,
                        help='path to file with a list of models to run')
    parser.add_argument('--model_revision','-r', type=str, default='[!latest!]',
                        help='which revision of the model to use (applies to all models; default is latest)')
    parser.add_argument('--model_revision_list','-rr', type=str,
                        help='path to file with a list which revision of the model to use')                        
    parser.add_argument('--task', '-t', type=str,
                        help='metric to caclulate')
    parser.add_argument('--task_list', '-tt', type=str,
                        help='path to file with list of metrics to caclulate')
    parser.add_argument('--following_context', '-f', action="store_true", default=False,
                        help='whether or not consider the following context with masked language models (default is False)')
    parser.add_argument('--use_cpu', '-cpu', action="store_true", default=False,
                        help='use CPU for models even if CUDA is available')

    args = parser.parse_args()
    return args

def process_args(args):
    arg_dict = defaultdict(lambda:None)  

    try:
        output_directory = args.output_directory
        if os.path.exists(output_directory):
            pass
        else:
            os.makedirs(output_directory)
        arg_dict["output_directory"] = output_directory
    except:
        print("Error: Please specify a valid output directory. Directory cannot be found or created.")
        return None
        
    try:
        primary_decoder = args.primary_decoder
        assert primary_decoder=="causal" or primary_decoder=="masked"
        arg_dict["primary_decoder"] = primary_decoder
    except:
        print("Error: Please select either 'causal' or 'masked' for primary decoder argument.")
        return None

    try:
        include_following_context = args.following_context
        assert type(include_following_context)==bool
        arg_dict["include_following_context"] = include_following_context
    except:
        print("Error: 'following_context' argument must be Boolean.")
        return None
    
    try:
        use_cpu = args.use_cpu
        assert type(include_following_context)==bool
        arg_dict["use_cpu"] = use_cpu
    except:
        print("Error: 'use_cpu' argument must be Boolean.")
        return None
    
    
    if args.model_list:
        try:
            assert os.path.exists(args.model_list)
            with open(args.model_list, "r") as f:
                model_list = f.read().splitlines()
        except:
            print("Error: 'model_list' argument does not have a valid path. Trying to use individual specified model.")
            try:
                assert args.model
                model_list = [args.model]
            except:
                print("Error: No model specified")
                return None
    else:
        try:
            assert args.model
            model_list = [args.model]
        except:
            print("Error: No model specified")
            return None        

    for i in range(len(model_list)):
        model_name = model_list[i]
        if not "model_list" in arg_dict:
            arg_dict["model_list"] = []
        arg_dict["model_list"].append(model_name)

    
    if not "model_list" in arg_dict:
        print("No valid models specified")
        return None

    if args.task_list:
        try:
            assert os.path.exists(args.task_list)
            with open(args.task_list, "r") as f:
                task_list = f.read().splitlines()
        except:
            print("Error: 'task_list' argument does not have a valid path. Trying to use individual specified metric.")
            try:
                assert args.task
                task_list = [args.task]
            except:
                print("Error: No metric specified")
                return None
    else:
        try:
            assert args.task
            task_list = [args.task]
        except:
            print("Error: No metric specified")   
            return None 

    if args.model_revision_list:
        try:
            assert os.path.exists(args.model_revision_list)
            with open(args.model_revision_list, "r") as f:
                model_revision_list = f.read().splitlines()
        except:
            print("Error: 'model_revision_list' argument does not have a valid path. Trying to use individual specified metric.")
            try:
                assert args.model_revision
                model_revision_list = [args.model_revision]
            except:
                print("Error: No metric specified")
                return None
    else:
        try:
            assert args.model_revision
            model_revision_list = [args.model_revision]
        except:
            print("Error: No metric specified")   
            return None 
    
    arg_dict["model_revision_list"] = model_revision_list

    for i in range(len(task_list)):
        if task_list[i] in ["surprisal"]:
            if not "standard_metric_list" in arg_dict:
                arg_dict["standard_metric_list"] = []
            arg_dict["standard_metric_list"].append(task_list[i])
    if not arg_dict["standard_metric_list"]:
        print("No valid metrics specified")
        return None
            
            
    if args.stimuli_list:
        try:
            assert os.path.exists(args.stimuli_list)
            with open(args.stimuli_list, "r") as f:
                stimulus_file_list = f.read().splitlines()
        except:
            print("Error: 'stimuli_list' argument does not have a valid path. Trying to use individual stimulus set.")
            try:
                assert args.stimuli
                stimulus_file_list = [args.stimuli]
            except:
                print("Error: No stimuli specified")
                return None
    else:
        try:
            assert args.stimuli
            stimulus_file_list = [args.stimuli]
        except:
            print("Error: No stimuli specified") 
            return None

    for i in range(len(stimulus_file_list)):
        if os.path.exists(stimulus_file_list[i]):
            if not "stimulus_file_list" in arg_dict:
                arg_dict["stimulus_file_list"]=[]
            arg_dict["stimulus_file_list"].append(stimulus_file_list[i])
    
    
    if not "stimulus_file_list" in arg_dict:
        print("No valid stimulus files specified")
        return None
                
    return(arg_dict)  

def get_metric_name(metric_name):
    if metric_name=="surprisal":
        return "Surprisal"

        

def create_and_run_models(arg_dict):

# convert to "try causal mask" approach

    slow_tokenizer_list = ["facebook/opt","open_llama"]

    for revision in arg_dict["model_revision_list"]:

        if arg_dict["primary_decoder"] == "masked":
            for model_name in arg_dict["model_list"]:
                
                if 'tokenizer' in locals():
                    del(tokenizer)
                
                if 'model' in locals():
                    del(model)
                    
                fast_tok = True

                for slow_tok_model in slow_tokenizer_list:
                    if slow_tok_model in model_name:
                        fast_tok = False

                model_name_cleaned = model_name.replace("/","__").replace(".","_")

                if revision!='[!latest!]':
                    model_name_cleaned = "{0}___{1}".format(model_name_cleaned,str(revision))

                try:
                    tokenizer = AutoTokenizer.from_pretrained(model_name,use_fast=fast_tok)
                    
                    if (not tokenizer.bos_token) and (tokenizer.cls_token):
                        tokenizer.bos_token = tokenizer.cls_token
                    if (not tokenizer.eos_token) and (tokenizer.sep_token):
                        tokenizer.eos_token = tokenizer.sep_token

                    tokenizer.add_special_tokens({"additional_special_tokens":["[!StimulusMarker!]"]})

                except:
                    print("Cannot create a tokenizer for model {0}".format(model_name))
                    
                try:
                    if revision!='[!latest!]':
                        config = AutoConfig.from_pretrained(model_name,revision=str(revision))
                        # see https://github.com/EleutherAI/lm-evaluation-harness/issues/1269
                        model = AutoModelForMaskedLM.from_pretrained(model_name,revision=str(revision), torch_dtype=torch.float32)
                        model_type = "masked"
                    else:
                        config = AutoConfig.from_pretrained(model_name)
                        model = AutoModelForMaskedLM.from_pretrained(model_name, torch_dtype=torch.float32)
                        model_type = "masked"
                except:
                    try:
                        if revision!='[!latest!]':
                            config = AutoConfig.from_pretrained(model_name,is_decoder=True,revision=str(revision))
                            model = AutoModelForCausalLM.from_pretrained(model_name,is_decoder=True,revision=str(revision), torch_dtype=torch.float32)
                            model_type = "causal"
                        else:
                            config = AutoConfig.from_pretrained(model_name,is_decoder=True)
                            model = AutoModelForCausalLM.from_pretrained(model_name,is_decoder=True, torch_dtype=torch.float32)
                            model_type = "causal"
                    except:
                        print("Model {0} is not a masked or causal language model. This is not supported".format(model_name))
                try:

                    assert model and tokenizer
                    if model and tokenizer:
                        try:
                            process_stims(model.to("cuda" if (torch.cuda.is_available() and not arg_dict["use_cpu"]) else "cpu"),tokenizer,model_type,model_name_cleaned,arg_dict)
                        except:
                            print("Cannot run either a masked or causal form of {0}".format(model_name))
                except:
                    print("Cannot run experiment without both a tokenizer for and a causal or masked form of {0}".format(model_name))
        
        elif arg_dict["primary_decoder"] == "causal":
            for model_name in arg_dict["model_list"]:

                if 'tokenizer' in locals():
                    del(tokenizer)
                
                if 'model' in locals():
                    del(model)

                fast_tok = True
                for slow_tok_model in slow_tokenizer_list:
                    if slow_tok_model in model_name:
                        fast_tok = False
                
                model_name_cleaned = model_name.replace("/","__").replace(".","_")

                if revision!='[!latest!]':
                    model_name_cleaned = "{0}___{1}".format(model_name_cleaned,str(revision))

                try:
                    tokenizer = AutoTokenizer.from_pretrained(model_name,use_fast=fast_tok)
                    
                    if (not tokenizer.bos_token) and (tokenizer.cls_token):
                        tokenizer.bos_token = tokenizer.cls_token
                    if (not tokenizer.eos_token) and (tokenizer.sep_token):
                        tokenizer.eos_token = tokenizer.sep_token

                    tokenizer.add_special_tokens({"additional_special_tokens":["[!StimulusMarker!]"]})

                except:
                    print("Cannot create a tokenizer for model {0}".format(model_name))
                    
                try:
                    if revision!='[!latest!]':
                        model = AutoModelForCausalLM.from_pretrained(model_name,is_decoder=True,revision=str(revision))
                        model_type = "causal"
                        if "Masked" in model.config.architectures[0]:
                            model_type = "causal_mask"         
                    else:            
                        model = AutoModelForCausalLM.from_pretrained(model_name,is_decoder=True)
                        model_type = "causal"
                        if "Masked" in model.config.architectures[0]:
                            model_type = "causal_mask"                    
                except:
                    try:
                        if revision!='[!latest!]':
                            model = AutoModelForMaskedLM.from_pretrained(model_name,revision=str(revision))
                            model_type = "masked"
                        else:
                            model = AutoModelForMaskedLM.from_pretrained(model_name)
                            model_type = "masked"
                    except:
                        print("Model {0} is not a causal or masked language model. This is not supported".format(model_name))
                try:
                    assert model and tokenizer
                    if model and tokenizer:
                        try:
                            process_stims(model.to("cuda" if (torch.cuda.is_available() and not arg_dict["use_cpu"]) else "cpu"),tokenizer,model_type,model_name_cleaned,arg_dict)
                        except:
                            print("Cannot run either a causal or masked form of {0}".format(model_name))
                except:
                    print("Cannot run experiment without both a tokenizer for and a causal or masked form of {0}".format(model_name))  

                  
def process_stims(model,tokenizer,model_type,model_name_cleaned,arg_dict):
    reversed_tokenizer = inv_map = {v: k for k, v in tokenizer.get_vocab().items()}
    for i in range(len(arg_dict["stimulus_file_list"])):
        stimuli_name = arg_dict["stimulus_file_list"][i].split('/')[-1].split('.')[0] 
        filenames = dict()
        metric_dict = dict()

        if arg_dict["standard_metric_list"]:
            for metric in arg_dict["standard_metric_list"]:
                filenames[metric] = arg_dict["output_directory"] + "/" + stimuli_name + "." + metric + "." + model_name_cleaned + "." + model_type +".output"
                with open(filenames[metric],"w") as f:
                    f.write("FullSentence\tSentence\tTargetWords\t{}\tNumTokens\n".format(get_metric_name(metric)))
                metric_dict[metric]= []

        with open(arg_dict["stimulus_file_list"][i],'r') as f:
            stimulus_list = f.read().splitlines() 
        for j in range(len(stimulus_list)):
            
            for metric in metric_dict:
                metric_dict[metric]=[]

            try:
                stimulus = stimulus_list[j]
                stimulus = stimulus.replace("\\n","\n").replace("\\r","\r").replace("\\t","\t").replace('\"','"').replace("\'","'")
                stimulus_spaces = stimulus.replace(" *", "* ")
                stimulus_spaces = stimulus_spaces.replace("*", "[!StimulusMarker!]")
                encoded_stimulus = tokenizer.encode(stimulus_spaces)
                

                #stimulus_marker_idx = tokenizer.encode("[!StimulusMarker!]")
                #if tokenizer.bos_token_id  in stimulus_marker_idx:
                    #stimulus_marker_idx.remove(tokenizer.bos_token_id)
                #if tokenizer.eos_token_id  in stimulus_marker_idx:
                    #stimulus_marker_idx.remove(tokenizer.eos_token_id)
                stimulus_marker_idx = tokenizer.additional_special_tokens_ids[tokenizer.additional_special_tokens.index("[!StimulusMarker!]")]

                
                dummy_var_idxs = np.where(np.array(encoded_stimulus)==stimulus_marker_idx)[0]
                preceding_context = encoded_stimulus[:dummy_var_idxs[0]]
                if len(preceding_context)==0 or not ((preceding_context[0]==tokenizer.bos_token_id) or (preceding_context[0]==tokenizer.eos_token_id)):
                    preceding_context = [tokenizer.bos_token_id] + preceding_context
                target_words = encoded_stimulus[dummy_var_idxs[0]+1:dummy_var_idxs[1]]
                following_words = encoded_stimulus[dummy_var_idxs[1]+1:]

                if "[!StimulusMarker!] " in stimulus_spaces and tokenizer.decode(target_words)[0]!=" ":
                    target_words_decoded = " " + tokenizer.decode(target_words)
                    target_words = tokenizer.encode(target_words_decoded)
                    if tokenizer.bos_token_id  in target_words:
                        target_words.remove(tokenizer.bos_token_id)
                    if tokenizer.eos_token_id  in target_words:
                        target_words.remove(tokenizer.eos_token_id)
                
                if "[!StimulusMarker!] " in stimulus_spaces and tokenizer.decode(target_words)[0]==" ": 
                    if len(target_words)>1:
                        if reversed_tokenizer[target_words[0]]=="▁" and reversed_tokenizer[target_words[1]][0]=="▁":
                            target_words=target_words[1:]
                        elif reversed_tokenizer[target_words[0]]==" " and reversed_tokenizer[target_words[1]][0]==" ":
                            target_words=target_words[1:]
                                            
                current_context = copy.deepcopy(preceding_context)
              

                if ("standard_metric_list" in arg_dict) or ("lp_norms" in arg_dict) or ("renyi" in arg_dict):
                    for k in range(len(target_words)):
                        current_target = target_words[k]
                        if model_type=="causal":
                            input = torch.LongTensor([current_context[-tokenizer.model_max_length:]]).to(model.device)
                            with torch.no_grad():
                                next_token_logits = model(input, return_dict=True).logits[:, -1, :]
                        elif model_type=="masked" or model_type=="causal_mask":
                            context_plus_mask = current_context + [tokenizer.mask_token_id]
                            if arg_dict["include_following_context"]==True:
                                context_plus_mask = context_plus_mask + following_words
                            model_input_list = context_plus_mask+[tokenizer.eos_token_id]
                            mask_idx = model_input_list.index(tokenizer.mask_token_id)
                            input = torch.LongTensor([model_input_list]).to(model.device)
                            with torch.no_grad():
                                next_token_logits = model(input, return_dict=True).logits[:, mask_idx, :]
                        probability_distribution = F.softmax(next_token_logits,dim=-1)
                        true_dist = torch.zeros(probability_distribution.shape).to(model.device)
                        true_dist[0,current_target]=1                       
                        
                        if "surprisal" in metric_dict:
                            surprisal = -torch.log(probability_distribution[0,current_target]).item()
                            metric_dict["surprisal"].append(surprisal)

                        current_context.append(current_target)

                num_tokens = len(target_words)

                sum_metric_dict = dict()
                for metric in metric_dict:
                    sum_metric_dict[metric] = np.sum(metric_dict[metric])
                sentence_idxs = preceding_context[1:]+target_words
                if arg_dict["include_following_context"]==True:
                    sentence_idxs = sentence_idxs+following_words
                if sentence_idxs[-1]==tokenizer.eos_token_id:
                    sentence_idxs = sentence_idxs[:-1]
                sentence = tokenizer.decode(sentence_idxs)                        
                target_string = tokenizer.decode(target_words)
                for metric in metric_dict:
                    with open(filenames[metric],"a") as f:
                        f.write("{0}\t{1}\t{2}\t{3}\t{4}\n".format(
                            stimulus.replace("*","").replace("\n","\\n").replace("\r","\\r").replace("\t","\\t").replace('"','\"').replace("'","\'"),
                            sentence.replace("\n","\\n").replace("\r","\\r").replace("\t","\\t").replace('"','\"').replace("'","\'"),
                            target_string,
                            sum_metric_dict[metric],
                            num_tokens
                        ))
            except:
                print("Problem with stimulus on line {0}: {1}\n".format(str(j+1),stimulus_list[j]))
                

def main():
    args = parse_args()
    arg_dict = process_args(args)
    if arg_dict:
        create_and_run_models(arg_dict)

if __name__ == "__main__":
    main()
