---
title: "RNA-Seq workflow - Part I: Quality Control"
author: "Bob Freeman, Mary Piper"
date: "Thursday, May 5, 2016"
---

Approximate time: 60 minutes

## Learning Objectives:

* Use a series of command line tools to execute an RNA-Seq workflow
* Learn the intricacies of various tools used in NGS analysis (parameters, usage, etc)
* Understand the contents of a FastQ file
* Be able to evaluate a FastQC report
* Use Trimmommatic to clean FastQ reads
* Use a For loop to automate operations on multiple files


## Bioinformatics workflows

When working with NGS data, the raw reads you get off of the sequencer will need to pass through a number of  different tools in order to generate your final desired output. The execution of this set of tools in a specified order is commonly referred to as a *workflow* or a *pipeline*. 

The workflow we will be using for our RNA-Seq analysis is provided below with a brief description of each step. 

![Workflow](../img/rnaseq_workflow.png)

1. Quality control - Assessing quality using FastQC
2. Quality control - Trimming and/or filtering reads (if necessary)
3. Index the reference genome for use by STAR
4. Align reads to reference genome using STAR (splice-aware aligner)
5. Count the number of reads mapping to each gene using htseq-count
6. Statistical analysis (count normalization, linear modeling using R-based tools)

These workflows in bioinformatics adopt a plug-and-play approach in that the output of one tool can be easily used as input to another tool without any extensive configuration. Having standards for data formats is what makes this feasible. Standards ensure that data is stored in a way that is generally accepted and agreed upon within the community. The tools that are used to analyze data at different stages of the workflow are therefore built under the assumption that the data will be provided in a specific format.  

##Quality Control - FASTQC
![Workflow](../img/rnaseq_workflow_FASTQC.png)

The first step in the RNA-Seq workflow is to take the FASTQ files received from the sequencing facility and assess the quality of the sequence reads. 

###Unmapped read data (FASTQ)

The [FASTQ](https://en.wikipedia.org/wiki/FASTQ_format) file format is the defacto file format for sequence reads generated from next-generation sequencing technologies. This file format evolved from FASTA in that it contains sequence data, but also contains quality information. Similar to FASTA, the FASTQ file begins with a header line. The difference is that the FASTQ header is denoted by a `@` character. For a single record (sequence read) there are four lines, each of which are described below:

|Line|Description|
|----|-----------|
|1|Always begins with '@' and then information about the read|
|2|The actual DNA sequence|
|3|Always begins with a '+' and sometimes the same info in line 1|
|4|Has a string of characters which represent the quality scores; must have same number of characters as line 2|

Let's use the following read as an example:

```
@HWI-ST330:304:H045HADXX:1:1101:1111:61397
CACTTGTAAGGGCAGGCCCCCTTCACCCTCCCGCTCCTGGGGGANNNNNNNNNNANNNCGAGGCCCTGGGGTAGAGGGNNNNNNNNNNNNNNGATCTTGG
+
@?@DDDDDDHHH?GH:?FCBGGB@C?DBEGIIIIAEF;FCGGI#########################################################
```

As mentioned previously, line 4 has characters encoding the quality of each nucleotide in the read. The legend below provides the mapping of quality scores (Phred-33) to the quality encoding characters. ** *Different quality encoding scales exist (differing by offset in the ASCII table), but note the most commonly used one is fastqsanger* **

 ```
 Quality encoding: !"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHI
                   |         |         |         |         |
    Quality score: 0........10........20........30........40                                
```
 
Using the quality encoding character legend, the first nucelotide in the read (C) is called with a quality score of 31 and our Ns are called with a score of 2. **As you can tell by now, this is a bad read.** 

Each quality score represents the probability that the corresponding nucleotide call is incorrect. This quality score is logarithmically based and is calculated as:

	Q = -10 x log10(P), where P is the probability that a base call is erroneous

These probabaility values are the results from the base calling algorithm and dependent on how much signal was captured for the base incorporation. The score values can be interpreted as follows:

|Phred Quality Score |Probability of incorrect base call |Base call accuracy|
|:-------------------|:---------------------------------:|-----------------:|
|10	|1 in 10 |	90%|
|20	|1 in 100|	99%|
|30	|1 in 1000|	99.9%|
|40	|1 in 10,000|	99.99%|
|50	|1 in 100,000|	99.999%|
|60	|1 in 1,000,000|	99.9999%|

Therefore, for the first nucleotide in the read (C), there is less than a 1 in 1000 chance that the base was called incorrectly. Whereas, for the the end of the read there is greater than 50% probabaility that the base is called incorrectly.

### Assessing quality with FastQC
The quality scores are useful in determining whether a sample is good or bad. Rather than looking at quality scores for each individual read, we use a tool called [FastQC](http://www.bioinformatics.babraham.ac.uk/projects/fastqc/) to looks at quality collectively across all reads within a sample. The image below is a plot that indicates a (very) good quality sample:

![good_quality](../img/good_quality.png)

On the x-axis you have the base position in the read, and on the y-axis you have quality scores. In this example, the sample contains reads that are 40 bp long. For each position, there is a box plotted to illustrate the distribution of values (with the whiskers indicating the 90th and 10th percentile scores). For every position here, the quality values do not drop much lower than 32 -- which if you refer to the table above is a pretty good quality score. The plot background is also color-coded to identify good (green), acceptable (yellow), and bad (red) quality scores.  

Now let's take a look at a quality plot on the other end of the spectrum. 

![bad_quality](../img/bad_quality.png)

Here, we see positions within the read in which the boxes span a much wider range. Also, quality scores drop quite low into the 'bad' range, particularly on the tail end of the reads. 

Poor quality sequence data can result from several different causes. **We don't have time to discuss the various error profiles and potential causes in this workshop, but if you would like to learn more, please see our [slides provided here](https://github.com/hbc/NGS_Data_Analysis_Course/blob/master/sessionI/slides/error_profiles_mm.pdf).**

When you encounter a quality plot such as this one, the first step is to troubleshoot. Why might we be seeing something like this? 

The *FASTQC* tool produces several other diagnostic plots to assess sample quality, in addition to the one plotted above. 



### Running FASTQC
####A. Stage your data

To perform our quality checks, we will be working within our recently created `rnaseq_project` directory. We need to create two directories within the `data` directory for this quality control step. 

```bash
$ cd unix_workshop/rnaseq_project/data

$ mkdir untrimmed_fastq trimmed_fastq
```
    
The raw_fastq data we will be working with is currently in the `unix_workshop/raw_fastq` directory. We need to copy the raw fastq files to our `untrimmed_fastq` directory:

```bash 
$ cp ~/unix_workshop/raw_fastq/*fq  ~/unix_workshop/rnaseq_project/data/untrimmed_fastq
```

####B. Run FastQC  

Before we run FastQC, let's start an interactive session on the cluster:

`$ bsub -Is -n 1 -q interactive bash`

***An interactive session is a very useful to test tools, workflows, run jobs that open new interactive windows (X11-forwarding) and so on.***

Once your interactive job starts, notice that the command prompt has changed; this is because we are working on a compute node now, not on a login node.

```bash
$ cd ~/unix_workshop/rnaseq_project/data/untrimmed_fastq/
```  

Before we start using software, we have to load the environments for each software package. On clusters, this is typically done using a **module** system. 

If we check which modules we currently have loaded, we should not see FastQC.

`$ module list`

If we try to run FastQC on one of our fastq files, Orchestra won't be able to find the program.

`$ fastqc Mov10_oe_1.subset.fq`

This is because the FastQC program is not in our $PATH (i.e. its not in a directory that unix will automatically check to run commands/programs).

```bash
$ $PATH
```

To run the FastQC program, we first need to load the appropriate module, so it puts the program into our path:

`$ module load seq/fastqc/0.11.3`

Once a module for a tool is loaded, you have essentially made it directly available to you like any other basic UNIX command.

`$ module list`

```bash
$ $PATH
```

FastQC will accept multiple file names as input, so we can use the *.fq wildcard.

`$ fastqc *.fq`

*Did you notice how each file was processed serially? How do we speed this up?*

Exit the interactive session and start a new one with 6 cores, and use the multi-threading funcionality of FastQC to run 6 jobs at once.

`$ exit`      #exit the current interactive session
	
`$ bsub -Is -n 6 -q interactive bash`      #start a new one with 6 cpus (-n 6)
	
`$ module load seq/fastqc/0.11.3`     #you'll have to reload the module for the new session

`$ cd unix_workshop/rnaseq_project/data/untrimmed_fastq/` #change to the untrimmed_fastq directory
	
`$ fastqc -t 6 *.fq`      #note the extra parameter we specified for 6 threads

How did I know about the -t argument for FastQC?

`$ fastqc --help`


Now, let's create a home for our results

```bash
$ mkdir ~/unix_workshop/rnaseq_project/results/fastqc_untrimmed_reads
```

...and move them there (recall, we are still in `~/unix_workshop/rnaseq_project/data/untrimmed_fastq/`)

```bash
$ mv *.zip ~/unix_workshop/rnaseq_project/results/fastqc_untrimmed_reads/

$ mv *.html ~/unix_workshop/rnaseq_project/results/fastqc_untrimmed_reads/
```

####C. Results
   
Let's take a closer look at the files generated by FastQC:
   
`$ ls -lh ~/unix_workshop/rnaseq_project/results/fastqc_untrimmed_reads/`

##### HTML reports
The .html files contain the final reports generated by fastqc, let's take a closer look at them. Transfer one of them over to your laptop via *FileZilla*.

######Filezilla - Step 1

Open *FileZilla*, and click on the File tab. Choose 'Site Manager'.
 
![FileZilla_step1](../img/Filezilla_step1.png)

######Filezilla - Step 2

Within the 'Site Manager' window, do the following: 

1. Click on 'New Site', and name it something intuitive (e.g. Orchestra)
2. Host: orchestra.med.harvard.edu 
3. Protocol: SFTP - SSH File Transfer Protocol
4. Logon Type: Normal
5. User: ECommons ID
6. Password: ECommons password
7. Click 'Connect'
	
![FileZilla_step2](../img/Filezilla_step2.png)

######Filezilla - Step 3

In FileZilla, on the left side of the screen navigate to the location you would like to save the file, and on the right side of the screen navigate through your remote directory to the file `/home/ecommons_id/unix_workshop/rnaseq_project/results/fastqc_untrimmed_reads/Mov10_oe1.html`. Double click on the .html file to transfer a copy, or click and drag over to the right hand panel.

Open the .html file to view the report.

######FastQC report
	
***FastQC is just an indicator of what's going on with your data, don't take the "PASS"es and "FAIL"s too seriously.***

FastQC has a really well documented [manual page](http://www.bioinformatics.babraham.ac.uk/projects/fastqc/) with [more details](http://www.bioinformatics.babraham.ac.uk/projects/fastqc/Help/) about all the plots in the report.

We recommend looking at [this post](http://bioinfo-core.org/index.php/9th_Discussion-28_October_2010) for more information on what bad plots look like and what they mean for your data.

We will focus on two of the most important analysis modules in FastQC, the "Per base sequence quality" plot and the "Overrepresented sequences" table. 

The "Per base sequence quality" plot provides the distribution of quality scores across all bases at each position in the reads.

![FastQC_seq_qual](../img/FastQC_seq_qual.png)

The "Overrepresented sequences" table displays the sequences (at least 20 bp) that occur in more than 0.1% of the total number of sequences. This table aids in identifying contamination, such as vector or adapter sequences. 

![FastQC_contam](../img/FastQC_contam.png)

##### .zip files   

Let's go back to the terminal now. The other output of FastQC is a .zip file. These .zip files need to be unpacked with the `unzip` program. If we try to `unzip` them all at once:

```bash
$ cd ~/unix_workshop/rnaseq_project/results/fastqc_untrimmed_reads/
    
$ unzip *.zip
```

Did it work? 

No, because `unzip` expects to get only one zip file. Welcome to the real world.
We *could* do each file, one by one, but what if we have 500 files? There is a smarter way.
We can save time by using a simple shell `for loop` to iterate through the list of files in *.zip.

After you type the first line, you will get a special '>' prompt to type next lines.  
You start with 'do', then enter your commands, then end with 'done' to execute the loop.

This loop is basically a simple program. When it runs

```bash
$ for zip in *.zip
do
unzip $zip
done
```
it will run unzip once for each file (whose name is stored in the $zip variable). The contents of each file will be unpacked into a separate directory by the unzip program.

The 'for loop' is interpreted as a multipart command.  If you press the up arrow on your keyboard to recall the command, it will be shown like so:

    for zip in *.zip; do echo File $zip; unzip $zip; done

When you check your history later, it will help you remember what you did!

##### Document your work

What information is contained in the unzipped folder?

```bash
$ ls -lh *fastqc

$ head *fastqc/summary.txt
```

To save a record, let's `cat` all `fastqc summary.txt` files into one `fastqc_summaries.txt` and move this to `~/unix_workshop/rnaseq_project/docs`. 
You can use wildcards in paths as well as file names.  Do you remember how we said `cat` is really meant for concatenating text files?
    
```bash
$ cat */summary.txt > ~/unix_workshop/rnaseq_project/logs/fastqc_summaries.txt
```


##Quality Control - Trimming
![Workflow](../img/rnaseq_workflow_trimming.png)

###How to clean reads using *Trimmomatic*

Once we have an idea of the quality of our raw data, it is time to trim away adapters and filter out poor quality score reads. To accomplish this task we will use [*Trimmomatic*](http://www.usadellab.org/cms/?page=trimmomatic).

*Trimmomatic* is a java based program that can remove sequencer specific reads and nucleotides that fall below a certain threshold. *Trimmomatic* can be multithreaded to run quickly. 

Let's load the *Trimmomatic* module:

`$ module load seq/Trimmomatic/0.33`

By loading the *Trimmomatic* module, the **trimmomatic-0.33.jar** file is now accessible to us in the **opt/** directory, allowing us to run the program. 

Because *Trimmomatic* is java based, it is run using the `java -jar /opt/Trimmomatic-0.33/trimmomatic-0.33.jar` command:

```bash
$ java -jar /opt/Trimmomatic-0.33/trimmomatic-0.33.jar SE \
-threads 4 \
inputfile \
outputfile \
OPTION:VALUE... # DO NOT RUN THIS
```

`java -jar` calls the Java program, which is needed to run *Trimmomatic*, which is a 'jar' file (`trimmomatic-0.33.jar`). A 'jar' file is a special kind of java archive that is often used for programs written in the Java programming language.  If you see a new program that ends in '.jar', you will know it is a java program that is executed `java -jar` <*location of program .jar file*>.

The `SE` argument is a keyword that specifies we are working with single-end reads. We have to specify the `-threads` parameter because *Trimmomatic* uses 16 threads by default.

The next two arguments are input file and output file names.  These are then followed by a series of options that tell the program exactly how you want it to operate. *Trimmomatic* has a variety of options and parameters:

* **_-threads_** How many processors do you want *Trimmomatic* to run with?
* **_SE_** or **_PE_** Single End or Paired End reads?
* **_-phred33_** or **_-phred64_** Which quality score do your reads have?
* **_SLIDINGWINDOW_** Perform sliding window trimming from the start of the read, cutting once the average quality within the window falls below a threshold.
* **_LEADING_** Cut bases off the start of a read, if below a threshold quality.
* **_TRAILING_** Cut bases off the end of a read, if below a threshold quality.
* **_CROP_** Cut the read to a specified length.
* **_HEADCROP_** Cut the specified number of bases from the start of the read.
* **_MINLEN_** Drop an entire read if it is below a specified length.
* **_TOPHRED33_** Convert quality scores to Phred-33.
* **_TOPHRED64_** Convert quality scores to Phred-64.


###Running Trimmomatic

Change directories to the untrimmed fastq data location:

```bash
$ cd ~/unix_workshop/rnaseq_project/data/untrimmed_fastq
```

Since the *Trimmomatic* command is complicated and we will be running it a number of times, let's draft the command in a **text editor**, such as Sublime, TextWrangler or Notepad++. When finished, we will copy and paste the command into the terminal.

For the single fastq input file `Mov10_oe_1.subset.fq`, we're going to run the following command:

```bash
$ java -jar /opt/Trimmomatic-0.33/trimmomatic-0.33.jar SE \
-threads 4 \
-phred33 \
Mov10_oe_1.subset.fq \
../trimmed_fastq/Mov10_oe_1.qualtrim25.minlen35.fq \
ILLUMINACLIP:/opt/Trimmomatic-0.33/adapters/TruSeq3-SE.fa:2:30:10 \
TRAILING:25 \
MINLEN:35
```
*The backslashes at the end of the lines allow us to continue our script on new lines, which helps with readability of some long commands.* ***Immediately `return` to the next line after adding the backslash. Spaces after the backslash will make the command fail to run.***

This command tells *Trimmomatic* to run on a fastq file containing Single-End reads (`Mov10_oe_1.subset.fq`, in this case) and to name the output file ``Mov10_oe_1.qualtrim25.minlen35.fq``. The program will remove Illumina adapter sequences given by the file, `TruSeq3-SE.fa` and will cut nucleotides from the 3' end of the sequence if their quality score is below 25. The entire read will be discarded if the length of the read after trimming drops below 35 nucleotides.

After the job finishes, you should see the *Trimmomatic* output in the terminal: 

```
TrimmomaticSE: Started with arguments: -threads 4 -phred33 Mov10_oe_1.subset.fq ../trimmed_fastq/Mov10_oe_1.qualtrim25.minlen35.fq ILLUMINACLIP:/opt/Trimmomatic-0.33/adapters/TruSeq3-SE.fa:2:30:10 TRAILING:25 MINLEN:35
Using Long Clipping Sequence: 'AGATCGGAAGAGCGTCGTGTAGGGAAAGAGTGTA'
Using Long Clipping Sequence: 'AGATCGGAAGAGCACACGTCTGAACTCCAGTCAC'
ILLUMINACLIP: Using 0 prefix pairs, 2 forward/reverse sequences, 0 forward only sequences, 0 reverse only sequences
Input Reads: 305900 Surviving: 300423 (98.21%) Dropped: 5477 (1.79%)
TrimmomaticSE: Completed successfully
```

The *Trimmomatic* command successfully ran and generated a new fastq file:

```bash
$ ls Mov10_oe_1*
Mov10_oe_1.subset.fq  Mov10_oe_1.qualtrim25.minlen35.fq
```

Now that we know how to run *Trimmomatic*, let's run it on all of our files. Unfortunately, there is some good news and bad news.  One should always ask for the bad news first.  *Trimmomatic* only operates on one input file at a time and we have more than one input file.  The good news? We already know how to use a `for` loop to deal with this situation.

Before we run our `for` loop, let's remove the file that we just created:

```bash
$ rm *qualtrim25.minlen35.fq
```
Now, run the `for` loop to run *Trimmomatic* on all files:

```bash
$ for infile in *fq
  do
    outfile=$infile.qualtrim25.minlen35.fq
	java -jar /opt/Trimmomatic-0.33/trimmomatic-0.33.jar SE \
	-threads 4 \
	-phred33 \
	$infile \
	$outfile \
	ILLUMINACLIP:/opt/Trimmomatic-0.33/adapters/TruSeq3-SE.fa:2:30:10 \
	TRAILING:25 \
	MINLEN:35
  done
```

In the 'for loop', do you remember how a variable is assigned the value of each item in the list in turn?  We can call it whatever we like.  This time it is called 'infile'.  Note that the third line of this for loop is creating a second variable called 'outfile'.  We assign it the value of $infile with '_trim.fastq' appended to it.  The variable is wrapped in curly brackets '{}' so the shell knows that whatever follows is not part of the variable name $infile.  There are no spaces before or after the '='.

Now let's keep our directory organized. Make a directory for the trimmed fastq files: 

```bash
$ mkdir ../trimmed_fastq
```

Move the trimmed fastq files to the new directory:

```bash
$ mv *qualtrim25.minlen35.fq ../trimmed_fastq/
```
After trimming, we would generally want to run FastQC on our trimmed fastq files, then transfer the files to our machine to make sure the trimming improved the quality of our reads without removing too many of them. 


#### Automating the QC workflow

Now that we know how to use the tools to perform the QC, let's automate the process of using *Trimmomatic* and running *FastQC* using a complete shell script (e.g. LSF submission script). We will use the same commands, with a few extra "echo" statements to give us feedback. 

A submission script is oftentimes preferable to executing commands on the terminal. We can use it to store the parameters we used for a command(s) inside a file. If we need to run the program on other files, we can easily change the script. Also, using scripts to store your commands helps with reproducibility. In the future, if we forget which parameters we used during our analysis, we can just check our script.

To run the *Trimmomatic* command on a worker node via the job scheduler, we need to create a submission script with two important components:

1. our **LSF directives** at the **beginning** of the script. This is so that the scheduler knows what resources we need in order to run our job on the compute node(s).

2. the commands to be run in order

Create the script called `trimmomatic_mov10.lsf`:

```bash
$ cd ~/unix_workshop/rnaseq_project/

$ nano trimmomatic_mov10.lsf
```

Within `nano` let's first add our commands, then we will come back to add our *LSF directives* (remember to comment liberally). Also, let's use the `basename` function to name our trimmed file more succinctly:

```bash
# Change directories into the folder with the untrimmed fastq files
cd ~/unix_workshop/rnaseq_project/data/untrimmed_fastq

# Loading modules for tools
module load seq/Trimmomatic/0.33
module load seq/fastqc/0.11.3

# Run Trimmomatic
echo "Running Trimmomatic..."
for infile in *.fq
do
  
  # Create names for the output trimmed files
  base=`basename .subset.fq $infile`
  outfile=$base.qualtrim25.minlen35.fq
 
  # Run Trimmomatic command
  java -jar /opt/Trimmomatic-0.33/trimmomatic-0.33.jar SE \
  -threads 4 \
  -phred33 \
  $infile \
  ../trimmed_fastq/$outfile \
  ILLUMINACLIP:/opt/Trimmomatic-0.33/adapters/TruSeq3-SE.fa:2:30:10 \
  TRAILING:25 \
  MINLEN:35
  
done
    
# Run FastQC on all trimmed files
echo "Running FastQC..."
fastqc -t 6 ../trimmed_fastq/*.fq
```
Now that we have our commands complete, add the shebang line and LSF directives to the top of the script:

```
#!/bin/bash

#BSUB -q priority 	# queue name
#BSUB -W 2:00 		# hours:minutes runlimit after which job will be killed.
#BSUB -n 6 		# number of cores requested
#BSUB -J rnaseq_mov10_qc         # Job name
#BSUB -o %J.out       # File to which standard out will be written
#BSUB -e %J.err       # File to which standard err will be written
```

`$ bsub < trimmomatic_mov10.lsf`

It is good practice to load the modules we plan to use at the beginning of the script. Therefore, if we run this script in the future, we don't have to worry about whether we have loaded all of the necessary modules prior to executing the script. 

Do you remember how the variable name in the first line of a 'for loop' specifies a variable that is assigned the value of each item in the list in turn?  We can call it whatever we like.  This time it is called `infile`.  Note that the fifth and sixth line of this 'for loop' creates the variables called `base` and `outfile`.  We assign `base` the value of `$infile` with the `.subset.fq`, and we assign `outfile` the value of `base` with `'.qualtrim25.minlen35.fq'` appended to it. **There are no spaces before or after the '='.**

After we have created the trimmed fastq files, we wanted to make sure that the quality of our reads look good, so we ran a *FASTQC* on our `$outfile`, which is located in the ../trimmed_fastq directory.

Let's make a new directory for our fasqc files for the trimmed reads:

`$ mkdir results/fastqc_trimmed_reads`

Now move all fastqc files to the `fastqc_trimmed_reads` directory:

`$ mv data/trimmed_fastq/*fastqc* results/fastqc_trimmed_reads/`

Let's use *FileZilla* to download the fastqc html for Mov10_oe_1. Has our read quality improved with trimming?

It is good practice to record the reads passing through each step of the workflow. For example, for each of our samples, we should record in a spreadsheet the number of input sequences and the number of surviving reads after trimming. Note that you can find all of that information in the `<job#>.err` file.

`$ less <job#>.err`

---
*This lesson has been developed by members of the teaching team at the [Harvard Chan Bioinformatics Core (HBC)](http://bioinformatics.sph.harvard.edu/). These are open access materials distributed under the terms of the [Creative Commons Attribution license](https://creativecommons.org/licenses/by/4.0/) (CC BY 4.0), which permits unrestricted use, distribution, and reproduction in any medium, provided the original author and source are credited.*

* *The materials used in this lesson were derived from work that is Copyright © Data Carpentry (http://datacarpentry.org/). 
All Data Carpentry instructional material is made available under the [Creative Commons Attribution license](https://creativecommons.org/licenses/by/4.0/) (CC BY 4.0).*
* *Adapted from the lesson by Tracy Teal. Original contributors: Paul Wilson, Milad Fatenejad, Sasha Wood and Radhika Khetani for Software Carpentry (http://software-carpentry.org/)*

