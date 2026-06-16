# CB-Climate-Pathways

This repository provides the data, code, lexicon, scripts, and output files for the study:

**Do Climate Risks Precede Climate Communication? Evidence from Global Central Banks**

**Author:** Muhammad Bilal Zafar
**ORCID:** https://orcid.org/0000-0001-6329-303X

## Overview

Climate change increasingly intersects with central bank mandates through macroeconomic volatility, financial stability, and systemic risk. This project examines whether physical climate vulnerability, institutional readiness, and domestic climate-policy intensity precede climate-related communication by global central banks.

The repository supports a long-horizon country-year panel analysis of central bank climate discourse from 1996 to 2024. The empirical design combines natural language processing, a validated climate-finance lexicon, transformer-based sentence classification, and panel econometric methods.

The main outcome variable is a country-year measure of climate-related central bank communication derived from central bank speeches. The analysis evaluates whether climate vulnerability, institutional readiness, and domestic climate-policy intensity predict within-country variation in climate communication over time.

## Research Design

The workflow proceeds in four main stages:

1. **Lexicon development**
   Seed climate-finance terms are expanded using word-embedding methods and manually validated to construct a domain-specific climate lexicon.

2. **Speech curation and sentence extraction**
   Central bank speeches are cleaned, segmented into sentences, screened using the climate lexicon, and deduplicated.

3. **Transformer-based classification**
   Candidate sentences are classified using a ClimateBERT to identify climate-related communication with greater semantic precision than keyword screening alone.

4. **Panel econometric analysis**
   Country-year measures of climate communication are merged with climate vulnerability, institutional readiness, climate-policy intensity, and macro-financial controls. The study applies two-way fixed effects, lag specifications, quantile regressions, Granger-style predictive tests, and Paris Agreement difference-in-differences/event-study analysis.

## Repository Contents

| File / Folder                                        | Description                                                                                                                                                                                                                                                                                                                                                            |
| ---------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `1-climate_cb lexicon expansion.ipynb`               | Lexicon development notebook documenting seed-term selection, word2vec-based expansion, manual validation, and construction of the finalized domain-specific climate lexicon used for candidate sentence extraction.                                                                                                                                                   |
| `2-climate_cb datacuration and classification.ipynb` | End-to-end data curation and classification notebook covering central bank speech archive ingestion, metadata cleaning, sentence segmentation using spaCy, lexicon screening, duplicate removal, ClimateBERT classification, and aggregation of climate-related sentences to country-year units.                                                                       |
| `3-climate_cb supplementary.dta`                     | Final country-year panel dataset containing the dependent variable, key explanatory variables, macro-financial controls, institutional controls, and communication-volume variables used in the econometric analyses.                                                                                                                                                  |
| `3a-stata do-file.do`                                | Replication do-file implementing the econometric analyses reported in the manuscript and appendix, including data preparation, panel declaration, two-way fixed-effects regressions with lag structures, quantile regressions, Granger-style predictive tests, Paris Agreement DiD/event-study analysis, robustness checks, appendix tables, figures, and diagnostics. |
| `climate_lexicon.csv`                                | Final validated climate-finance lexicon containing 889 terms used in the first-stage keyword screening to identify candidate climate-related sentences from the central bank speech corpus.                                                                                                                                                                            |
| `seed_terms.csv`                                     | Original seed-term list used to generate the expanded climate lexicon.                                                                                                                                                                                                                                                                                                 |
| `results/`                                           | Folder containing the original output files generated by the replication do-file, organized into main-paper tables/figures, appendix tables/figures, and diagnostic outputs.                                                                                                                                                                                           |


## Requirements

The Python notebooks require a standard scientific Python environment. The main packages used include:

* `pandas`
* `numpy`
* `spaCy`
* `transformers`
* `torch`
* `scikit-learn`
* `gensim`
* `nltk`
* `tqdm`

The econometric analysis requires Stata. The replication do-file is designed to run on the final country-year panel dataset:

`3-climate_cb supplementary.dta`

## Replication Instructions

To reproduce the analysis, follow these steps:

1. Run the lexicon development notebook:

   `1-climate_cb lexicon expansion.ipynb`

2. Run the data curation and classification notebook:

   `2-climate_cb datacuration and classification.ipynb`

3. Open Stata and run the replication do-file:

   `3a-stata do-file.do`

4. Review the generated outputs in the `results/` folder.

The final econometric dataset is also provided directly as:

`3-climate_cb supplementary.dta`

Researchers who wish to replicate only the econometric results may begin from this file and run the Stata do-file.

## Main Empirical Components

The Stata replication file includes:

* Country-year panel preparation
* Two-way fixed-effects regressions
* Lagged climate-risk and policy specifications
* Communication persistence models
* Quantile regressions
* Panel Granger-style predictive tests
* Paris Agreement DiD analysis
* Event-study specifications
* Robustness checks
* Main-paper and appendix output tables
* Diagnostic outputs

## Citation

Please cite this repository and the associated manuscript as follows:

Zafar, M. B. (2026). *Do Climate Risks Precede Climate Communication? Evidence from Global Central Banks*. 
Zafar, M. B. (2026). *Do Climate Risks Precede Climate Communication? Evidence from Global Central Banks*. Manuscript and supplementary replication materials.
