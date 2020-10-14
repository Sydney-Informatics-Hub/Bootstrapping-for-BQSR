#!/bin/bash

#########################################################
# 
# Platform: NCI Gadi HPC
# Description: create input for gather GVCFs
# Made  change to the config file format by adding 5th col for group 
# and now library can't be left blank for default (if so, would require 
# changing the align script that reads lib from col 4) 
# New group method will use the type specified in 'Group' col to name the 
# by-group inputs files. This is useful when you have groups of differnet 
# sequencing coverage eg high and low, as the run time for this task is ~ 
# double for double coverage
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

set -e

cohort=<cohort>
config=${cohort}.config
round=<round>
group=false
 
vcfdir=./GVCFs/Round${round}

input=./Inputs/hc_gathervcfs.inputs
rm -rf $input

if [[ $group = true ]]
then
	groups=$(awk 'NR>1 {print $5}' ${config} | sort | uniq)
	groups=($groups)
	for (( i = 0; i < ${#groups[@]}; i ++ ))
	do
		rm -rf ${input}-${groups[$i]}
		echo Making inputs file ${input}-${groups[$i]}
	done
fi	

# Make inputs and args files: 	
awk 'NR>1' ${config} | while read LINE
do
	sample=`echo $LINE | cut -d ' ' -f 2`
	
	# Make inputs file for run parallel:
	if [[ $group = true ]]
	then
		group_name=`echo $LINE | cut -d ' ' -f 5`	
		echo $sample >> ${input}-${group_name}
	else
		echo $sample >> ${input}
	fi
	
	# Make args file per sample:
	args=${vcfdir}/${sample}/${sample}.gather.args
	rm -rf ${args}
	for interval in $(seq -f "%04g" 0 3199)
	do
		echo "--I ${vcfdir}/${sample}/${sample}.${interval}.vcf" >> ${args}
	done
done

# Report number of inputs: 
if [[ $group = true ]]
then
	for (( i = 0; i < ${#groups[@]}; i ++ ))
	do
		file=${input}-${groups[$i]}
		if [ -f $file ]
		then
        		tasks=`wc -l < $file`
        		printf "Number of GVCF gather tasks to run for group ${groups[$i]}: ${tasks}\n"
		else
        		echo Something went wrong - $file file not created 
		fi		
	done
else 
	if [ -f $input ]
	then
        	tasks=`wc -l < $input`
        	printf "Number of GVCF gather tasks to run: ${tasks}\n"
	else
        	echo Something went wrong - $input file not created 
	fi
fi
