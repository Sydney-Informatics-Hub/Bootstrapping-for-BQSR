#!/bin/bash

#########################################################
# 
# Platform: NCI Gadi HPC
# Description: run GATK Base Recalibrator over parallel tasks
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

module load gatk/4.1.2.0
 
ref=<ref>
cohort=<cohort>
round=<round>

labSampleID=`echo $1 | cut -d ',' -f 1` 
intNum=`echo $1 | cut -d ',' -f 2`
interval=`echo $1 | cut -d ',' -f 3`

bam=./Dedup_sort/${labSampleID}.coordSorted.dedup.bam 
log=./GATK_logs/BQSR_round${round}/${labSampleID}.${intNum}.recal.oe
err=./Error_capture/Bootstrap_BQSR_round${round}/${labSampleID}.${intNum}.err
out=./BQSR_recal_tables/Round${round}/${labSampleID}.${intNum}.recal_data.table
known_snps=./VCFs/${cohort}_bootstrap-R${round}-S5_SNP_filtered.vcf
known_indels=./VCFs/${cohort}_bootstrap-R${round}-S6_INDEL_filtered.vcf

rm -f $log $err $out 

echo "$(date): Bootstrap round ${round} step 7: Base recalibrator for interval $interval" >> ${log} 2>&1

gatk BaseRecalibrator \
	--java-options "-Xmx7G -DGATK_STACKTRACE_ON_USER_EXCEPTION=true" \
	-R $ref \
	-L $interval \
	-I $bam  \
	--known-sites $known_snps \
	--known-sites $known_indels \
	-O $out >> $log 2>&1

echo "$(date): Finished." >> ${log} 2>&1

if grep -q -i error $log
then 
        printf "Error in GATK log ${log}\n" >> $err
fi 

if grep -q Exception $log
then 
        printf "Exception in GATK log ${log}\n" >> $err
fi
	
	
