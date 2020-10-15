#!/bin/bash

#########################################################
# 
# Platform: NCI Gadi HPC
# Description: Create input file to run genotypegvcfs in parallel
# Author: Cali Willet
# cali.willet@sydney.edu.au
# Date last modified: 14/10/2020
#
# If you use this script towards a publication, please acknowledge the
# Sydney Informatics Hub (or co-authorship, where appropriate).
#
# Suggested acknowledgement:
# The authors acknowledge the scientific and technical assistance 
# <or e.g. bioinformatics assistance of <PERSON> of Sydney Informatics
# Hub and resources and services from the National Computational 
# Infrastructure (NCI), which is supported by the Australian Government
# with access facilitated by the University of Sydney.
# 
#########################################################

cohort=<cohort>
config=${cohort}.config
round=<round>

logdir=./GATK_logs/GenomicsDBImport_round${round}
list=../GenotypeGVCFs_logs/interval_duration_memory.txt # this is from Germline-ShortV genotype GVCFs checklogs step OR previous round of bootstrapping

input=./Inputs/genotypegvcfs.inputs
rm -rf $input

echo Writing $input

awk 'NR>1' $list | sort -rnk 2 | awk '{print $1}' > $input

if [ -f $input ]
then
        tasks=`wc -l < $input`
        printf "Number of genotype GVCF tasks to run: ${tasks}\n"
else
	echo Something went wrong - no $input file created
fi
