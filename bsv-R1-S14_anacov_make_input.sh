#!/bin/bash

#########################################################
# 
# Platform: NCI Gadi HPC
# Description: make inputs file for parallel exectuion of 
# GATK AnalyzeCovariates
# Details:
#	Create sample list for gathering chunked BQSR recal tables 
#	to one recal table per sample. Provide cohort name as argument. 
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

input=./Inputs/anacov.inputs

rm -f $input

awk 'NR>1 {print $2}' ${config} > ${input}					
tasks=`wc -l < $input`
printf "Number of analyse covariates tasks to run: ${tasks}\n"
	
