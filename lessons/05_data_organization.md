---
title: "Data Management and Project Organization"
author: "Mary Piper, Meeta Mistry, Radhika Khetani"
date: "Wednesday October 26, 2016"
---

Approximate time: 45 minutes

## Learning Objectives:

* Recognizing the need for Data Management
* Planning a good genomics experiment and getting started with project organization
* Have a general idea of the experiment and its objectives
* Understand how and why we chose this dataset

## Data Management

"The goal of a data management plan is to consider the many aspects of data management, metadata generation, data preservation, and analysis before the project begins; this ensures that data are well-managed in the present, and prepared for preservation in the future." -[Wikipedia](https://en.wikipedia.org/wiki/Data_management_plan)

Before we start talking about how to organize an RNA-Seq project, we will talk a little bit about how to manage your data and some considerations for working with datasets of large sizes.

**[Click here](https://dl.dropboxusercontent.com/u/74036176/data_management_HSCI_Mar2017.pdf) for the Data Management slide deck.**

### Planning for and organizing large datasets/analyses

Sequencing projects can quickly accumulate hundreds of files across tens of folders and occupy gigabytes/petabytes of space with pertinent, as well as redundant information. Therefore, before you start any type of data analysis, it is best to make sure you have the necessary storage space available, a data archiving plan in place, and most importantly, that you stay as organized as possible during the analysis. As you can imagine, performing an analysis with a large number of datasets that get processed using multi-step workflows requires a focus on data provenance. This is important for many reasons, including publishing, data sharing, reusing methods/workflows etc. 

We won't be talking much about planning for storage and archiving, but will focus on how to organize an RNA-Seq experiment and thereby making data provenance easier.

Let's get started! 

Make sure that you are in your home directory,

```bash
$ pwd
```
this should give the result: `/home/user_name`

Now, make a directory for the RNA-Seq analysis within the `ngs_course` folder using the `mkdir` command

```bash
$ mkdir ngs_course/rnaseq
```

Next you want to set up the following structure within your project directory to keep files organized:

```bash
rnaseq/
  ├── data/
  ├── meta/
  ├── results/
  ├── scripts/
  └── logs/

```

*This is a generic structure and can be tweaked based on personal preferences.* A brief description of what might be contained within the different sub-directories is provided below:

* **`data/`**: This folder is usually reserved for any raw data files that you start with. 

* **`meta/`**: This folder contains any information that describes the samples you are using, which we often refer to as metadata. 

* **`results/`**: This folder will contain the output from the different tools you implement in your workflow. To stay organized, you should create sub-folders specific to each tool/step of the workflow. 

* **`scripts/`**: This folder will contain the scripts that you use to run analyses at different points in the workflow.

* **`logs/`**: It is important to keep track of the commands you run and the specific parameters you used, but also to have a record of any standard output that is generated while running the command. 


Let's create a directory for our project by changing into `rnaseq` and then using `mkdir` to create the five directories.

```bash
$ cd ngs_course/rnaseq
$ mkdir data meta results scripts logs
``` 

Verify that you have created the directories:

```bash
$ ls -l
```
 
If you have created these directories, you should get the following output from that command:

```bash
drwxrwsr-x 2 rsk27 rsk27   0 Jun 17 11:21 data
drwxrwsr-x 2 rsk27 rsk27   0 Jun 17 11:21 logs
drwxrwsr-x 2 rsk27 rsk27   0 Jun 17 11:21 meta
drwxrwsr-x 2 rsk27 rsk27   0 Jun 17 11:21 results
drwxrwsr-x 2 rsk27 rsk27   0 Jun 17 11:21 scripts
```
Now we will create the subdirectories to setup for our RNA-Seq analysis, and populate them with data where we can. We need to create two directories within the `data` directory, one folder for untrimmed/raw reads and another for trimmed/cleaned up reads: 

```bash
$ cd ~/ngs_course/rnaseq/data

$ mkdir untrimmed_fastq

$ mkdir trimmed_fastq
```
    
The raw fastq data we will be working with is currently in the `unix_lesson/raw_fastq` directory. We need to copy the raw fastq files to our `untrimmed_fastq` directory:

```bash
$ cp ~/ngs_course/unix_lesson/raw_fastq/*fq untrimmed_fastq
```

Later in the workflow when we map these reads to the genome, we will require reference/genome data to map against. These files are also in the `unix_lesson` directory, you can copy the entire folder over into `data`:

```bash
$ cp -r ~/ngs_course/unix_lesson/reference_data .    ## note the destination "."
```

### Documenting

For all of the steps up to the point you submitted the samples for sequencing, like collecting specimens, extracting DNA, prepping your libraries, you have a lab notebook which details how and why you did each step, but **documentation doesn't stop at the sequencer**! 

#### Log files

In your lab notebook, you likely keep track of the different reagents and kits used for a specific protocol. Similarly, recording information about the tools and parameters is important for documenting your computational experiments. 

* Keep track of software versions used
* Record information on parameters used and summary statistics at every step (e.g., how many adapters were removed, how many reads did not align)
* Some tools will generate a log file with additional details by default, for others you will have to make sure you collect/record this information manually.
 
#### README

Keeping notes on what happened in what order, and what was done, is essential for reproducible research. If you don’t keep good notes, then you will forget what you did pretty quickly, and if you don’t know what you did, no one else has a chance. 

After setting up the project directories and running a workflow it is useful to have a **README file within your project** directory. An example README is shown below: 

```bash
## README ##
## This directory contains data generated from the NGS Data Analysis Course
## Date: November 1st, 2016

There are five directories in this directory:

data: contains raw data
meta:  contains...
results:
logs:
```

> Optionally, within each sub-directory you can include README files with additional details. 
 

## The RNA-Seq analysis workflow

For any bioinformatics experiment you will have to go through a series of steps (workflow) in order to obtain your final desired output. Below is an almost complete (but simplified) workflow of an RNA-Seq experiment.

> **Note**: in this workshop we will not be going in-depth into any of these steps.

<img src=../img/rnaseq_workflow.png width=500>

1. Library preparation of biological samples (pre-sequencing) [Lab]
2. Quality control - Assessing quality of sequence reads using FastQC [Linux]
3. Quality control - Trimming and/or filtering sequencing reads (if necessary) [Linux]
4. Align reads to reference genome using STAR (splice-aware aligner) [Linux]
5. Quantifying expression/Counting the number of reads mapping to each gene [Linux]
6. Statistical analysis to identify differentially expressed genes (count normalization, linear modeling using R-based tools) [R]


## The dataset
The dataset we will be using tomorrow is part of a larger study described in [Kenny PJ et al, Cell Rep 2014](http://www.ncbi.nlm.nih.gov/pubmed/25464849). 

The authors investigate interactions between various genes involved in Fragile X syndrome, a disease of aberrant protein production, which results in cognitive impairment and autistic-like features. **The authors sought to show that RNA helicase MOV10 regulates the translation of RNAs involved in Fragile X syndrome.** From this study we are using the [RNA-Seq](http://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE50499) data which are publicly available at [SRA](http://www.ncbi.nlm.nih.gov/sra). 

In addition to the raw sequence data, we also need the **metadata** for this experiment from GEO/SRA; some relevant metadata for this dataset is listed below:

* The RNA was extracted from **HEK293F cells** that were transfected with a MOV10 transgene or an irrelevant siRNA.  
* The cDNA libraries for this dataset are **stranded**. 
* Sequencing was carried out on the **Illumina HiSeq-2500 for 100bp single end** reads. 
* The full dataset was sequenced to **~40 million reads** per sample.
* For each group there are three replicates as described in the figure below.

![Experimental Design](../img/exp_design.png)

***

**Exercise (Homework)**

Take a moment to create a README for the `rnaseq` folder using `nano`. Give a short description of the project and brief descriptions of the types of files that are or will be within each of the sub-directories (to the best of your knowledge). 

***

----

*This lesson has been developed by members of the teaching team at the [Harvard Chan Bioinformatics Core (HBC)](http://bioinformatics.sph.harvard.edu/). These are open access materials distributed under the terms of the [Creative Commons Attribution license](https://creativecommons.org/licenses/by/4.0/) (CC BY 4.0), which permits unrestricted use, distribution, and reproduction in any medium, provided the original author and source are credited.*
