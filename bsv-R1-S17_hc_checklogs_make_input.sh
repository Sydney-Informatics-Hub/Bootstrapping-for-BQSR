#!/bin/bash

#########################################################
# 
# Platform: NCI Gadi HPC
# Description: make inputs file for parallel exectuion of GATK HC checklogs
# Usage: bash bsv-R1-S17_hc_checklogs_make_input.sh <cohort_name>
# Details:
# 	Provide cohort name as argument. Sample info is read from <cohort>.config
#
# Author: Cali Willet
# cali.willet@sydney.edu.au
# Date last modified: 09/09/2020
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

if [ -z "$1" ]
then
        echo "Please run this script with the base name of your config file"
        exit
fi

cohort=$1


input=./Inputs/hc_checklogs.inputs

rm -f $input

awk 'NR>1' ${cohort}.config | while read LINE
do 
	sample=`echo $LINE | cut -d ' ' -f 1`
	labSampleID=`echo $LINE | cut -d ' ' -f 2`
	printf "${labSampleID}\n" >> $input							
done	


if [ -f $input ]
then
	tasks=`wc -l < $input`
	printf "Number of checklogs tasks to run: ${tasks}\n"
else
	echo Something went wrong - $input file not created 
fi
