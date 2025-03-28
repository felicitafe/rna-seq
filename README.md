# KO vs NT RNA-seq Pipeline

This repository contains a simple pipeline for RNA-seq differential expression analysis between Knock Out and Non Target samples.

## Pipeline Steps:
1. Quality control with `fastp`
2. Alignment using `STAR`
3. Quantification with `RSEM`
4. Differential expression analysis using `DESeq2` (R)

## Requirements:
- Conda environment (see `rnaseq` env)
- fastp, STAR, RSEM, R
- R packages: DESeq2, tidyverse (adjust depending on your R script)

## How to run:
```bash
sbatch pipeline.sh
