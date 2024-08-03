#!/bin/bash

sbatch submitRjob.sh run_analyses_boyce.R
sbatch submitRjob.sh run_analyses_futrell.R
sbatch submitRjob.sh run_analyses_kennedy.R
sbatch submitRjob.sh run_analyses_luke.R
sbatch submitRjob.sh run_analyses_smaller_datasets.R
sbatch submitRjob.sh run_analyses_smith.R