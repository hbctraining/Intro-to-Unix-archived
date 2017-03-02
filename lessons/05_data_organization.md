---
title: "Getting your project started"
author: "Jason Williams, Bob Freeman, Meeta Mistry"
date: "Thursday, May 5, 2016"
---

Approximate time: 30 minutes

# Getting your project started

## Learning Objectives

* Have a general idea of the experiment and its objectives
* Understand how and why we choose this dataset
* Planning a good genomics experiment
* Recognizing the need for data management


## Understanding the dataset

The dataset we are using is part of a larger study described in [Kenny PJ et al, Cell Rep 2014](http://www.ncbi.nlm.nih.gov/pubmed/25464849). The authors are investigating interactions between various genes involved in Fragile X syndrome, a disease in which there is aberrant production of the FMRP protein. FMRP has been linked to the microRNA pathway, as it has been shown to be involved in miRNA mediated translational suppresion. **The authors sought to show that FMRP associates with the RNA helicase MOV10, that is also associated with the microRNA pathway.**

### Metadata

From this study we are using the [RNA-Seq](http://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE50499) data which is publicly available in the [SRA](http://www.ncbi.nlm.nih.gov/sra). Using this data, we will evaluate transcriptional patterns associated with MOV10 overexpression. In addition to the raw sequence data we also need to collect **information about the data**, also known as metadata.

> 1. What is your definition of metadata?
> 2. What kinds of metadata might a sequencing project generate?
> 3. Why is this type of information important?
>

Here, we provide metadata for the data we are using today.

* The RNA was extracted from HEK293F cells that were transfected with a MOV10 transgene and normal control cells.  
* The libraries for this dataset are stranded and were generated using the dUTP method. 
* Sequencing was carried out on the Illumina HiSeq-2500 for 100bp single end reads. 
* The full dataset was sequenced to ~40 million reads per sample, but for this workshop we will be looking at a small subset on chr1 (~300,000 reads/sample).
* For each group we have three replicates as described in the figure below.


![Automation](../img/exp_design.png)

 

## Project organization

Project organization is one of the most important parts of a sequencing project, but is often overlooked in the excitement to get a first look at new data. While it's best to get yourself organized before you begin analysis, it's never too late to start.

In the most important ways, the methods and approaches we need in bioinformatics are the same ones we need at the bench or in the field - **planning, documenting, and organizing** will be the key to good reproducible science. 

### Planning 

You should approach your sequencing project in a very similar way to how you do a biological experiment, and ideally, begins with **experimental design**. We're going to assume that you've already designed a beautiful sequencing experiment to address your biological question, collected appropriate samples, and that you have enough statistical power. 

### Organizing

Every computational analysis you do is going to spawn many files, and inevitability, you'll want to run some of those analysis again. Genomics projects can quickly accumulate hundreds of files across tens of folders. Before you start any analysis it is best to first get organized and **create a planned storage space for your workflow**.

We will start by creating a directory that we can use for the rest of the workshop:

First, make sure that you are in your home directory,

```
$ pwd
```
this should give the result: `/home/user_name`

* **Tip** If you were not in your home directory, the easiest way to get there is to enter the command *cd* - which always returns you to home. 

Now, make a directory for your project within the `unix_workshop` folder using the `mkdir` command

```
$ mkdir unix_workshop/rnaseq_project
```

Next you want to set up the following **directory structure** within your project directory to keep files organized. 

```
rnaseq_project/
├── data
├── meta
├── results
└── logs

```
This is a generic structure and can be tweaked based on personal preferences. A brief description of what might be contained within the different sub-directories is provided below:

* **`data/`**: This folder is usually reserved for any raw data files that you start with. 

* **`meta/`**: This folder contains any information that describes the samples you are using, which we often refer to as metadata. 

* **`results/`**: This folder will contain the output from the different tools you implement in your workflow. To stay organized, you should create sub-folders specific to each tool/step of the workflow. 

* **`logs/`**: It is important to keep track of the commands you run and the specific pararmeters you used, but also to have a record of any standard output that is generated while running the command. 


Let's create a a directory for our project by changing into `rnaseq_project` and then using `mkdir` to create the four directories.

```
$ cd unix_workshop/rnaseq_project
$ mkdir data meta results logs

``` 
Verify that you have created the directories:

```
$ ls -F
```
if you have created these directories, you should get the following output from that command:

```
/data  /docs  /meta  /results

```

### Documenting

For all of those steps, collecting specimens, extracting DNA, prepping your samples, you've likely kept a lab notebook that details how and why you did each step, but **documentation doesn't stop at the sequencer**! 

 
#### README

You probably won't remember whether your best alignment results were in Analysis1, AnalysisRedone, or AnalysisRedone2. Keeping notes on what happened in what order, and what was done, is essential for reproducible research. It is essential for good science.  If you don’t keep good notes, then you will forget what you did pretty quickly, and if you don’t know what you did, noone else has a chance. After setting up the filesystem and running a workflow it is useful to have a **README file within your project** directory. This file will usually contain a quick one line summary about the project and any other lines that follow will describe the files/directories found within it. Within each sub-directory you can also include README files 
to describe the analysis and the files that were generated. 


#### Log files

In your lab notebook, you likely keep track of the different reagents and kits used for a specific protocol. Similarly, recording information about the tools and and parameters is imporatant for documenting your computational experiments. 

* Keep track of software versions used
* Record information on parameters used and summary statistics at every step (e.g., how many adapters were removed, how many reads did not align)

> Different tools have different ways of reporting log messages and you might have to experiment a bit to figure out what output to capture. You can redirect standard output with the `>` symbol which is equivalent to `1> (standard out)`; other tools might require you to use `2>` to re-direct the `standard error` instead. 


#### Sensible file names 
This will make your analysis traversable by you and your collaborators, and writing the methods section for your next paper will be a breeze. Below is a short list of things we suggest when it comes to file naming:

1. **Keep sample names short and meaningful.** If required, include some form of a long explanation for the sample names (i.e comment lines at the top of the metadata file, or add it in your README file).
2. Have **unique sample names** and try to avoid names that look like dates (Dec14), times (AM1245) and other things that Excel might auto-convert. 
3. **Remove spaces and punctuation.** When working on the command line, spaces in file names make everything exponentially more difficult. Replace all your spaces with under_scores and avoid the use of any special characters.



***

**Exercise**

1. Take a moment to create a README for `rnaseq_project` (hint: use nano to create the file). Give a short description of the project and brief descriptions of the types of file you would be storing within each of the sub-directories.

***



### Resources

* [Data Organization Best Practices](https://github.com/datacarpentry/organization-genomics/blob/gh-pages/GoodBetterBest.md)
* [A Quick Guide to Organizing Computational Biology Projects](http://journals.plos.org/ploscompbiol/article?id=10.1371/journal.pcbi.1000424)


---
*This lesson has been developed by members of the teaching team at the [Harvard Chan Bioinformatics Core (HBC)](http://bioinformatics.sph.harvard.edu/). These are open access materials distributed under the terms of the [Creative Commons Attribution license](https://creativecommons.org/licenses/by/4.0/) (CC BY 4.0), which permits unrestricted use, distribution, and reproduction in any medium, provided the original author and source are credited.*

* *The materials used in this lesson were derived from work that is Copyright © Data Carpentry (http://datacarpentry.org/). 
All Data Carpentry instructional material is made available under the [Creative Commons Attribution license](https://creativecommons.org/licenses/by/4.0/) (CC BY 4.0).*
* *Adapted from the lesson by Tracy Teal. Original contributors: Paul Wilson, Milad Fatenejad, Sasha Wood and Radhika Khetani for Software Carpentry (http://software-carpentry.org/)*


