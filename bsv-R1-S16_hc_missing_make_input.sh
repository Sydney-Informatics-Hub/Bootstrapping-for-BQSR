#!/bin/bash

#########################################################
# 
# Platform: NCI Gadi HPC
# Description: find failed HC tasks from step 15 and create inputs for these tasks to be re-run 
# Author: Tracy Chew and Cali Willet
# tracy.chew@sydney.edu.au;cali.willet@sydney.edu.au
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
round=<round>

RED='\033[0;31m' 
NC='\033[0m'

input=./Inputs/hc_missing.inputs
rm -rf $input

vcfdir=./GVCFs/Round${round}
logs=./GATK_logs/HC_round${round}
scatterdir=./Reference/HC_intervals


#For each sample, check intervals with no/empty .vcf and .vcf.idx files
awk 'NR>1' ${config} | while read LINE
do 
        sample=`echo $LINE | cut -d ' ' -f 2`
	i=0
	for interval in $(seq -f "%04g" 0 3199)
	do
		logfile=${logs}/${sample}/${interval}.oe
		vcf=${vcfdir}/${sample}/${sample}.${interval}.vcf
		idx=${vcfdir}/${sample}/${sample}.${interval}.vcf.idx
		if ! [[ -s "${vcf}" &&  -s "${idx}" ]]
		then
			int=${scatterdir}/${interval}-scattered.interval_list
			printf "${sample},$int\n" >> $input			
		else
			((++i))
		fi
	done
	
	if [[ $i == 3200 ]]
	then
		echo "${sample} OK. Ready for merging into GVCF."
	else
		num_missing=$((3200 - $i))
		echo -e "${RED}${sample} has ${num_missing} missing vcf or vcf.idx files.${NC}"
		total_missing=$(($total_missing+$num_missing))
	fi
done

if [[ $total_missing -gt 0 ]]
then
	printf "\nThere are $total_missing missing/empty vcf files. Please run bsv-R${round}-S16_hc_missing_run_parallel.pbs with ${input}\n"
fi
