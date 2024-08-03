#!/bin/bash

./run_experiments.sh
./get_perplexities.sh
python shrink_results_files.py