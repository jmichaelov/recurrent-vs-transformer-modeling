# Revenge of the Fallen? Recurrent Models Match Transformers at Predicting Human Language Comprehension Metrics

Repository for the paper '[Revenge of the Fallen? Recurrent Models Match Transformers at Predicting Human Language Comprehension Metrics](https://arxiv.org/abs/2404.19178)', accepted at [COLM 2024](https://colmweb.org/).

This repository contains all the code and data needed to replicate the results reported in the paper.



### Paper Abstract
> Transformers have supplanted Recurrent Neural Networks as the dominant architecture for both natural language processing tasks and, despite criticisms of cognitive implausibility, for modelling the effect of predictability on online human language comprehension. However, two recently developed recurrent neural network architectures, RWKV and Mamba, appear to perform natural language tasks comparably to or better than transformers of equivalent scale. In this paper, we show that contemporary recurrent models are now also able to match&mdash;and in some cases, exceed&mdash;performance of comparably sized transformers at modeling online human language comprehension. This suggests that transformer language models are not uniquely suited to this task, and opens up new directions for debates about the extent to which architectural features of language models make them better or worse models of human language comprehension.


### Folder contents
* `cleaned_datasets` contains all the N400/reading time datasets.
* `cleaned_stimuli` contains the stimuli from the datasets prepared in a form to be input into the language models.
* `code` contains the code to calculate surprisals for all language models on all stimuli (see `get_surprisals.sh`) as well as the code to calculate all language models' WikiText perplexity (see `get_perplexities.sh`). Both of these (as well as the code for shrinking the size of the surprisal output files) can be run using `run_experiments.sh`.
* `perplexities` contains all the perplexities calculated using the [Language Model Evaluation Harness](https://github.com/EleutherAI/lm-evaluation-harness) with the code in `get_perplexities.sh`.
* `results` contains the surprisals calculated using the language models.
* `statistics` contains the statistical analysis code as well as the code used to generate the plots in the paper. `run_analyses.R` runs the regressions and calculates their AICs, `lms.R` runs the ordinary least-squares linear models used to analyze these AICs, and `make_plots.R` generates the plots included in the paper. We also include the `run_analyses_split` folder, which contains the code to run the regressions for each dataset separately using Slurm (using `run_all.sh`), which can reduce runtime if it is possible to run multiple jobs simultaneously. These results can then be combined into a single `tsv` file with `combine_AICs.R`.


To cite the code in this repository, please cite the original paper:

```
@article{michaelov2024revenge,
  title={Revenge of the Fallen? Recurrent Models Match Transformers at Predicting Human Language Comprehension Metrics},
  author={Michaelov, James A. and Arnett, Catherine and Bergen, Benjamin K.},
  journal={arXiv preprint arXiv:2404.19178},
  year={2024},
  url={https://arxiv.org/abs/2404.19178}
}
```