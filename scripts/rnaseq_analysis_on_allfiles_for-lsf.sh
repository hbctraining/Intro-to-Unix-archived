#! /bin/bash

for fastq in ~/unix_workshop/rnaseq_project/data/trimmed_fastq/*fq
do
bsub -q priority -n6 -W 1:30 -R "rusage[mem=4000]" -J rnaseq_mov10 -o %J.out -e %J.err "sh ~/unix_workshop/rnaseq_project/rnaseq_analysis_on_input_file.sh $fastq"
sleep 1
done
exit
