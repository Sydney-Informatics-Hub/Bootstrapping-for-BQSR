#!/bin/bash

#########################################################
# 
# Platform: NCI Gadi HPC
# Description: merge recalibrated split BAM files into a final 
# BAM per sample with SAMbamba merge, parallel by sample
# Details:
#	SAMbamba will automatically create bai given that the input is 
#	coordinate sorted
# Author: Cali Willet
# cali.willet@sydney.edu.au
# Date last modified: 14/10/2020
#
# If you use this script towards a publication, please acknowledge the
# Sydney Informatics Hub (or co-authorship, where appropriate).
#
# Suggested acknowledgement:
# The authors acknowledge the scientific and technical assistance 
# <or e.g. bioinformatics assistance of <PERSON>> of Sydney Informatics
# Hub and resources and services from the National Computational 
# Infrastructure (NCI), which is supported by the Australian Government
# with access facilitated by the University of Sydney.
# 
#########################################################

set -e

round=<round>

module load sambamba/0.7.1 samtools/1.10 # sambamba is a local install 

labSampleID=`echo $1 | cut -d ',' -f 1` 

cd ./BQSR_apply/Round${round} #bams in
bams=$(find . -name "${labSampleID}*.bam" | xargs echo)

err=../Error_capture/BQSR_merge_round${round}/${labSampleID}.err

bam_out=../../BQSR_bams/Round${round}/${labSampleID}.bqsr-R${round}.bam

rm -rf $err $bam_out #attempt to set stripe on existing file will cause fatal error

lfs setstripe -c 15 $bam_out

sambamba merge -t $NCPUS $bam_out $bams

if ! samtools quickcheck $bam_out
then 
        printf "Corrupted or missing BAM\n" > $err  
fi
