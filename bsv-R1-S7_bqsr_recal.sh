#!/bin/bash

#########################################################
# 
# Platform: NCI Gadi HPC
# Description: run GATK Base Recalibrator over parallel tasks
# Usage: this script is executed by bqsr_recal_run_parallel.pbs
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

module load gatk/4.1.2.0
 
ref=./Reference/GCA_902635505.1_mSarHar1.11_genomic.fna
cohort=Devils_N37

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

gatk BaseRecalibrator \
	--java-options "-Xmx7G" \
	-R $ref \
	-L $interval \
	-I $bam  \
	--known-sites $known_snps \
	--known-sites $known_indels \
	-O $out >> $log 2>&1


if grep -q -i error $log
then 
        printf "Error in GATK log ${log}\n" >> $err
fi 

if grep -q Exception $log
then 
        printf "Exception in GATK log ${log}\n" >> $err
fi
	
	
