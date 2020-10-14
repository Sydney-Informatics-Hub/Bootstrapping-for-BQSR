#!/bin/bash

#########################################################
# 
# Platform: NCI Gadi HPC
# Description: make inputs file for parallel exectuion of GATK BaseRecalibrator
# Details:
# 	Comma-delimited list for BQSR must have N entries per sample, 
# 	where N is the maximum number of chunks that GATK recommends 
# 	BQSR can operate over (min 100 Mb per chunk, N = genome_size / 100 Mb,
#	rounded down to integer)
# 	Contig names cannot be used to name the output files as 
# 	they contain special characters and this makes bash have a hissy fit
# 	For tumour/normal, run time is ~ half for normal so best to split
# 	into 2 jobs 
# 	This script assumes all non-cancer samples are designated 
# 	'N' ('normal'), and are lower coverage. All other phenotype IDs are assigned 
# 	to 'tumour'
# 	If no binomial grouping is desired, change group=true to group=false
# 	Sample info is read from <cohort>.config
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

group=false

t_input=./Inputs/bqsr_recal.inputs-tumour
n_input=./Inputs/bqsr_recal.inputs-normal
input=./Inputs/bqsr_recal.inputs

rm -f $t_input
rm -f $n_input
rm -f $input

intervals=$(ls -1 ./Reference/BQSR_intervals/*list) #directory of text files generated by GATK SplitIntervals
intervals=($intervals)

awk 'NR>1' ${config} | while read LINE
do 
        labSampleID=`echo $LINE | cut -d ' ' -f 2`
	
        if [[ $group = true ]]
        then
		if [[ $labSampleID = *-N ]]
        	then
			group_input=${n_input}		
		else
			group_input=${t_input}
		fi
	else
		group_input=${input}
	fi
	
	for ((i=0;i<${#intervals[@]};i++))	
	do         
                printf "${labSampleID},${i},${intervals[i]}\n" >> ${group_input}
	done
done 

if [ -f $input ]
then	
	tasks=`wc -l < $input`
	printf "Number of BaseRecalibrator tasks to run: ${tasks}\n"
fi

if [ -f $n_input ]
then
	tasks=`wc -l < $n_input`
	printf "Number of BaseRecalibrator normal sample tasks to run: ${tasks}\n"
fi

if [ -f $t_input ]
then
	tasks=`wc -l < $t_input`
	printf "Number of BaseRecalibrator tumour sample tasks to run: ${tasks}\n"
fi


