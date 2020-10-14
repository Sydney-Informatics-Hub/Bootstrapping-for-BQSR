#!/bin/bash

#########################################################
# 
# Platform: NCI Gadi HPC
# Description: make inputs file for parallel exectuion of GATK ApplyBQSR
# Details:
# 	Job can be run as separate tumour/normal or highcov/lowcov jobs, or as one job. 
#	The contigs do take longer to print for tumour compared to normal re 
#	more data to print, but the impact of input sample size on effiency is 
#	lower than for other jobs, as there are many more tasks than CPUs for 
#	this job and the walltime discrepancies among tasks are somewhat absorbed 
#	by the large number of tasks. The walltime is capped by the time to print 
#	chromosome 1, so the inputs are sorted by contig size so that the largest 
#	contigs are processed first. If no binomial grouping is desired, change 
#	group=true to group=false. Assumes all non-cancer samples have suffix '-N',
#	all other phenotype IDs are assigned to tumour.
#	Sample info is read from <cohort>.config
#
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

cohort=<cohort>
config=${cohort}.config

#group=false

#t_input=./Inputs/bqsr_apply.inputs-tumour
#n_input=./Inputs/bqsr_apply.inputs-normal
input=./Inputs/bqsr_apply.inputs

#rm -f $t_input
#rm -f $n_input
rm -f $input


list=$(ls -1 ./Reference/BQSR_apply_intervals | cut -d '-' -f 1)
list=($list)
list+=( "unmapped" )

samples=$(awk 'NR>1 {print $2}' ${config})
samples=($samples)

for (( i = 0; i < ${#list[@]}; i ++ ))
do
	interval=${list[$i]}
	for (( s = 0; s < ${#samples[@]}; s++ ))
	do
		sample=${samples[$s]}
		printf "${interval},${sample}\n" >> ${input}
	done
done

tasks=`wc -l < $input`
printf "Number of ApplyBQSR tasks to run: ${tasks}\n"



