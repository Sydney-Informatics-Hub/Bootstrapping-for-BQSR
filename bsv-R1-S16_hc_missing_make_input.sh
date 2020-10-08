#!/bin/bash

#After running gatk4_hc_run_parallel.pbs, check that all .vcf and .vcf.idx files
#have been created for each interval for each sample
#If not, this script creates gatk4_hc_missing.inputs
#Then run gatk4_hc_missing_run_parallel.pbs to re-run these in parallel, with a single node

#########################################################
# 
# Platform: NCI Gadi HPC
# Description: 
# Usage: 
# Details:
#
# Author: Cali Willet
# cali.willet@sydney.edu.au
# Date last modified: 28/08/2020
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

round=1

RED='\033[0;31m' 
NC='\033[0m'

input=./Inputs/hc_missing.inputs
rm -rf $input

vcfdir=./GVCFs/Round${round}
logs=./GATK_logs/HC_round${round}
scatterdir=./Reference/HC_intervals


#For each sample, check intervals with no/empty .vcf and .vcf.idx files
awk 'NR>1' ${cohort}.config | while read LINE
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
