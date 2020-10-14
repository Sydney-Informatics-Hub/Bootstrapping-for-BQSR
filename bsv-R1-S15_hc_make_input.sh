#!/bin/bash

#########################################################
# 
# Platform: NCI Gadi HPC
# Description:  make inputs for parallel haplotype caller
# All BAMs present in the BAM directory are used to make the inputs. 
# If this is not suitable for your analysis, rectify the code or the directory. 
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


round=<round>

input=./Inputs/gatk4_hc.inputs

rm -f $input

intervals=$(cat ./Reference/HC_intervals/3200_intervals_taskTimeSorted.list) # check path/exists
intervals=($intervals)

#Put higher coverage samples first
samples=$(ls -l ./BQSR_bams/Round${round}/*bam | sort -rnk 5 | awk '{print $9}' | cut -d '/' -f 4 | cut -d '.' -f 1) # check regex for each batch - eg '.' in sample ID, or number of directoy levels
samples=($samples)

for (( i=0; i<${#intervals[@]}; i++ ))
do
	for (( c=0; c<${#samples[@]}; c++ ))     
	do
		interval=./Reference/HC_intervals/${intervals[i]}-scattered.interval_list
		printf "${samples[$c]},$interval\n" >> $input
	done
done


tasks=`wc -l < $input`
printf "Number of GATK4 HC tasks to run: ${tasks}\n"
