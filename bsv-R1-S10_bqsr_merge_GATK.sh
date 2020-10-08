#!/bin/bash

#########################################################
# 
# Platform: NCI Gadi HPC
# Description: merge recalibrated split BAM files into a final 
# BAM per sample with GATK GatherBamFiles, parallel by sample
# Usage: this script is executed by bqsr_merge_GATK_run_parallel.pbs
# Author: Cali Willet
# cali.willet@sydney.edu.au
# Date last modified: 24/07/2020
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


labSampleID=$1

round=1

jvm=28 # Set this variable to 28 for hugemem queue or 10 for normal queue
ref=./Reference/GCA_902635505.1_mSarHar1.11_genomic.fna


module load gatk/4.1.2.0 samtools/1.10


log=./GATK_logs/BQSR_merge_round${round}/${labSampleID}.log
err=./Error_capture/BQSR_merge_round${round}/${labSampleID}.err
bam_out=./BQSR_bams/Round${round}/${labSampleID}.bqsr-R${round}.bam
list=./Inputs/BQSR_merge_lists/${labSampleID}.list

rm -rf $log $err $bam_out

\rm -rf $bam_out #attempt to set stripe on existing file will cause fatal error
lfs setstripe -c 15 $bam_out


gatk GatherBamFiles \
	--java-options "-Xmx${jvm}G -Dsamjdk.compression_level=5 -DGATK_STACKTRACE_ON_USER_EXCEPTION=true" \
	-I $list \
	-O $bam_out \
	--CREATE_INDEX=false \
	-R $ref  >> $log 2>&1
	
	
	#--CREATE_INDEX=true # GATK won't CSI index - tested, tries to make a BAI and dies. Can't find flag to specify CSI. Do it with samtools in a subsequent multithreaded step 
	#--CREATE_MD5_FILE=true # Do not create md5 in this job, as it will cost more SU than needed re higher mem requirements for merge


if ! samtools quickcheck $bam_out
then 
        printf "Corrupted or missing BAM\n" > $err  
fi

if grep -q -i error $log
then 
        printf "Error in GATK log ${log}\n" >> $err
fi 

if grep -q Exception $log
then 
        printf "Exception in GATK log ${log}\n" >> $err
fi
