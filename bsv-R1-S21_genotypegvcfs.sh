#!/bin/bash

#########################################################
# 
# Platform: NCI Gadi HPC
# Description: perform joint genotyping in parallel
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

module load gatk/4.1.2.0 

# Oct 2020: Ran with 4.1.8.1 and newer java to test a new flag "--genomicsdb-shared-posixfs-optimizations"
# in latest ver, but the efficiency and lustre load was not improved 


int=$1
interval=./Reference/HC_intervals/${int}-scattered.interval_list


round=<round>
ref=<ref>
cohort=<cohort>


gendbdir=./GenomicsDBImport/Round${round}
outdir=./GenotypeGVCFs/Round${round}
logdir=./GATK_logs/GenotypeGVCFs_round${round}
log=${logdir}/${int}.oe
err=./Error_capture/GenotypeGVCFs_round${round}/${int}.err
rm -rf $log $err

out=${outdir}/${cohort}.${int}.vcf.gz
rm -rf ${out}*
tmp=${PBS_JOBFS}/${int} # Andrey has recommended to use jobfs for temp. He said it will slow down by 10% but still recommends...
mkdir -p ${tmp}

echo "$(date) : Start GATK 4 GenotypeGVCFs. Reference: ${ref}; Cohort: ${cohort}; Interval: ${interval}" > ${log} 2>&1

gatk GenotypeGVCFs \
	--java-options "-Xmx6g -Dsamjdk.compression_level=5 -DGATK_STACKTRACE_ON_USER_EXCEPTION=true" \
	-R ${ref} \
	-V gendb://${gendbdir}/${int} \
	--tmp-dir ${tmp} \
	-OVI FALSE \
	-O ${out} >> ${log} 2>&1

echo "$(date) : Finished." >> ${log} 2>&1

if grep -q -i error $log
then 
        printf "Error in GATK log ${log}\n" >> $err
fi 

if grep -q Exception $log
then 
        printf "Exception in GATK log ${log}\n" >> $err
fi


## Options to explore
# --sample-ploidy,-ploidy:Integer : for different sex chromosomes, Mt
# --interval-padding - but genomicsdbimport needs to include padded sites
# --include-non-variant-sites : up to the researcher
# --dbsnp
