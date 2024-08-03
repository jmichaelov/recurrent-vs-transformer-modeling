#!/bin/bash

for Model in RWKV/rwkv-4-169m-pile RWKV/rwkv-4-430m-pile RWKV/rwkv-4-1b5-pile RWKV/rwkv-4-3b-pile EleutherAI/pythia-160m EleutherAI/pythia-410m EleutherAI/pythia-1b EleutherAI/pythia-1.4b EleutherAI/pythia-2.8b state-spaces/mamba-130m-hf state-spaces/mamba-370m-hf state-spaces/mamba-790m-hf state-spaces/mamba-1.4b-hf state-spaces/mamba-2.8b-hf


    do
        echo "################################################"
        echo $Model
        echo "################################################"

        lm_eval \
            --model hf \
            --model_args pretrained=$Model,dtype=float32 \
            --tasks wikitext \
            --device cuda:0 \
            --batch_size 1 \
            --output_path ../perplexities/$Model
    done
    
python extract_perplexities.py
