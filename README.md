# setu
CoViD Genome Assembler
Setu (sanskrit सेतु) means bridge. It bridges all the reads to genome.

# Setting
```
 conda create -c conda-forge -c bioconda -n setu snakemake
 conda activate setu
 git clone https://github.com/jnarayan81/setu.git
 cd setu
 ./setu.sh
```

<h1>setu: a bioinformatics pipeline to assemble CoViD genome</h1>

**setu** is a bioinformatics pipeline to assemble CoViD genome. It has three mode of genome assembly: 1. Paired-End 2. Hybrid 3. Long reads. The promise of setu:

* Implement recent NGS techniques to achieve reliable genome.
* Maintain flexibility in reads type selection
* Build on standard Conda and Python packages

In a nutshell, this pipeline is designed to use all sort of NGS reads to produce a genome with better N50. Consult Jitendra at jnarayan81@gmail.com for any support.

# Introduction

Severe acute respiratory syndrome coronavirus 2 (SARS-CoV-2) is a novel human-infecting strain of Betacoronavirus. This pathogen responsible for the ongoing CoronaVirusDisease (CoViD2019) pandemic. Rapid advancement and declining costs of high throughput sequencing technologies have allowed the virus to be sequenced globally in many individuals affected. While next generation sequencing (NGS) technology offers a robust means of identifying possible pathogens from clinical specimens, easy and user-friendly bioinformatics pipelines are required to achieve a full viral genome sequence and with utmost accuracy.Towards this effort, we have written a detailed pipeline for analyzing and decoding SARS-CoV 2 sequencing data utilizing open source utilities. It involves comprehensive sequence subtraction of host- or bacteria-related NGS reads before de novo assembly, resulting in the rapid and correct assembly of metagenomic sequences of viral genomes

# News

**June 1, 2020:** Release v0.1.0, see release notes [here](http://bioinformaticsonline.com/setu)

# Getting Started

## Installation

Install the latest release from [setu](https://github.com/jnarayan81/setu). Now all the missing dependencies can be install using conda.
```
conda install -c bioconda samtools
conda install -c bioconda <name>
```
For any missing dependencies, search in Conda.

## Usage Examples
Clone setu from https://github.com/jnarayan81/setu.git and run setu.sh for more information

User need to provide the absolute path of the reads
### Hybrid
```
time ./setu.sh -k yes -m hybrid -t 1 -r /home/jit/Downloads/setu/sampleDATA/G1/SRR11140750_1.fastq,/home/jit/Downloads/setu/sampleDATA/G1/SRR11140750_2.fastq,/home/jit/Downloads/setu/sampleDATA/reads_100x.fastq,ont -f on -o see_hybrid
```

### PE
```
time ./setu.sh -k yes -m pe -t 1 -r /home/jit/Downloads/setu/sampleDATA/G1/SRR11140750_1.fastq,/home/jit/Downloads/setu/sampleDATA/G1/SRR11140750_2.fastq -f on -o see_pe
```
### Long
```
time ./setu.sh -k yes -m long -t 1 -r /home/jit/Downloads/setu/sampleDATA/reads_100x.fastq,ont -f on -o see_long
```

## Running the tests

This project uses [conda](https://docs.conda.io/en/latest/)  dependencies. Test run locally after installing all dependencies and fastq files using [grabseqs](https://github.com/louiejtaylor/grabseqs) of SRR11140750.

# Blogs and Publications

* June 2020: [CoViD Assembler](http://bioinformaticsonline.com/setu)

# Citation

If you use setu in your research, please cite us as follows:

   Jitendra. **setu: a bioinformatics pipeline to assemble CoViD genome** https://github.com/jnarayan81/setu, 2020. Version 0.x.

BibTex:

```
@misc{setu,
  author={Jitendra},
  title={{setu}: {A bioinformatics pipeline to assemble CoVid genome}},
  howpublished={https://github.com/jnarayan81/setu},
  note={Version 0.x},
  year={2020}
}
```

# Contributing and Feedback

This project welcomes contributions and suggestions.

For more information contact [jnarayan81@gmail.com](mailto:jnarayan81@gmail.com) with any additional questions or comments.

# References

