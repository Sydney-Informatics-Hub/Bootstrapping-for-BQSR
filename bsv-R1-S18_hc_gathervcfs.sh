#!/bin/bash

#Merge interval level haplotypecaller VCFs per sample
#Final output is tabix indexed but NOT gzipped (issue with Devils chr sizes)

### Failed run for devils: has -Xmx28 per task for 1 CPU hugemem - low cov samples took
# twice as long to run as March run (6 x normal CPUs, no Xmx value) and high cov samples
# died on 2 hrs walltime on chr 1 despite completing in 59 mins in March run
# Re-submit the parallel tasks without Xmx and with separate batches for high and low cov


#########################################################
# 
# Platform: NCI Gadi HPC
# Description: Merge interval level haplotypecaller VCFs per sample
# Final output is tabix indexed but NOT gzipped (issue with Devils chr sizes)
# If you have species with 'normal' size chrs (human range or smaller) you can 
# add .gz suffix to $out and gatk will write zipped output
# Author: Cali Willet and Tracy Chew
# cali.willet@sydney.edu.au;tracy.chew@sydney.edu.au
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

module load gatk/4.1.2.0

set -e

sample=$1

round=<round>

args=./GVCFs/Round${round}/${sample}/${sample}.gather.args

mkdir -p ./GVCFs/Round${round}/${sample} ./GATK_logs/HC_round${round}/${sample}

out=./GVCFs/Round${round}/${sample}/${sample}.g.vcf #had to drop the GZ for devils, it threw an invalid file pointer error 
log=./GATK_logs/HC_round${round}/${sample}/${sample}.gather.oe
err=./Error_capture/HC_gather_round${round}/${sample}.err

rm -rf $out $log $err 

echo "$(date): Bootstrap round ${round} step 18: Gather GVCFs for sample ${sample}" >> ${log} 2>&1

gatk GatherVcfs \
	--java-options "-DGATK_STACKTRACE_ON_USER_EXCEPTION=true" \
	--arguments_file ${args} \
	--MAX_RECORDS_IN_RAM 100000000 \
	-O ${out} > ${log} 2>&1
	
echo "$(date): Finished." >> ${log} 2>&1

if grep -q -i error $log
then 
        printf "Error in GATK log ${log}\n" >> $err
fi 

if grep -q Exception $log 
then 
        printf "Exception in GATK log ${log}\n" >> $err
fi
