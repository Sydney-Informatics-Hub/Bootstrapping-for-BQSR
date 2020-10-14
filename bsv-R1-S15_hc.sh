#!/bin/bash

#########################################################
# 
# Platform: NCI Gadi HPC
# Description: Run GATK HC using scatter-gather method
# Author: Tracy Chew and Cali Willet
# tracy.chew@sydney.edu.au;cali.willet@sydney.edu.au
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

ulimit -s unlimited 

round=<round>
ref=<ref>

module load gatk/4.1.2.0 samtools/1.10

set -e

sample=`echo $1 | cut -d ',' -f 1`
interval=`echo $1 | cut -d ',' -f 2`
counter=$(echo $interval | cut -d '/' -f 4 | cut -d '-' -f 1)

bam=./BQSR_bams/Round${round}/${sample}.bqsr-R${round}.bam

mkdir -p ./GVCFs/Round${round}/${sample} 
gvcf=./GVCFs/Round${round}/${sample}/${sample}.${counter}.vcf

mkdir -p ./GATK_logs/HC_round${round}/${sample}
log=./GATK_logs/HC_round${round}/${sample}/${sample}.${counter}.oe

err=./Error_capture/HC_round${round}/${sample}.${counter}.hc.err

rm -rf $log $err $gvcf

echo "$(date) : Start GATK 4 HaplotypeCaller on recalibrated BAM from bootstrapping round ${round} for sample ${sample} interval ${interval}" > ${log}

gatk HaplotypeCaller \
	--java-options "-Xmx6g -DGATK_STACKTRACE_ON_USER_EXCEPTION=true" \
	-R ${ref} \
	-I ${bam} \
	-L ${interval} \
	-O ${gvcf} \
	-G StandardAnnotation \
	-G AS_StandardAnnotation \
	-G StandardHCAnnotation \
	--native-pair-hmm-threads ${NCPUS} \
	-ERC GVCF 2>>${log}

echo "$(date) : Finished." >> ${log}

if grep -q -i error $log
then 
        printf "Error in GATK log ${log}\n" >> $err
fi 

if grep -q Exception $log
then 
        printf "Exception in GATK log ${log}\n" >> $err
fi
