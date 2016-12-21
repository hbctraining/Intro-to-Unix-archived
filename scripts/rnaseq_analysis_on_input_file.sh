#! /bin/bash

# This script runs through STAR and htseq-count on a fastq file specified on the command prompt
# USAGE sh rnaseq_analysis_on_input_file.sh <name of fastq file>

# Run this file from the rnaseq_project directory
cd ~/unix_workshop/rnaseq_project/

# Make directory
mkdir -p results/STAR

#accept information from positional parameter into a variable
fq=$1

#location of genome reference and gtf as variables
genome=~/unix_workshop/rnaseq_project/data/reference_STAR/
gtf=~/unix_workshop/rnaseq_project/data/reference_STAR/chr1-hg19_genes.gtf

#Load modules
module load seq/STAR/2.4.0j
module load seq/samtools/1.3
module load seq/htseq/0.6.1

#create output directories
mkdir -p ~/unix_workshop/rnaseq_project/results/STAR
mkdir -p ~/unix_workshop/rnaseq_project/results/counts

# grab base of filename for future naming
base=$(basename $fq .subset.fq.qualtrim25.minlen35.fq)

echo "basename is $base"

# set up output filenames and locations
align_out=~/unix_workshop/rnaseq_project/results/STAR/${base}_
counts_input_bam=~/unix_workshop/rnaseq_project/results/STAR/${base}_Aligned.sortedByCoord.out.bam
counts=~/unix_workshop/rnaseq_project/results/counts/${base}.counts


echo "starting STAR run"

# Run STAR on Mov10_oe_1
STAR --runThreadN 6 --genomeDir $genome \
--readFilesIn $fq  \
--outFileNamePrefix $align_out \
--outSAMtype BAM SortedByCoordinate \
--outSAMunmapped Within \
--outSAMattributes NH HI NM MD AS

echo "completed STAR run"

# Create BAM index
samtools index $counts_input_bam

# Count mapped reads
htseq-count --stranded reverse --format bam $counts_input_bam $gtf > $counts
