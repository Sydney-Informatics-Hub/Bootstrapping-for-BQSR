#!/bin/bash

#########################################################
# 
# Platform: NCI Gadi HPC
# Description: create CSI index for the dedup/sort BAM file
# Usage: this script is executed by index_run_parallel.pbs
# Author: Cali Willet
# cali.willet@sydney.edu.au
# Date last modified: 24/07/2020
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

round=1

module load samtools/1.10

labSampleID=`echo $1 | cut -d ',' -f 1`


bam=./BQSR_bams/Round${round}/${labSampleID}.bqsr-R${round}.bam

# For CSI indexing: 
samtools index -@ $NCPUS -c $bam #Note -c for CSI indexes

# For BAI indexing: 
#samtools index -@ $NCPUS $bam 

