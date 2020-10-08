#!/bin/bash

#########################################################
# 
# Platform: NCI Gadi HPC
# Description: run GATK ApplyQSR over parallel tasks
# Usage: this script is executed by bqsr_apply_run_parallel.pbs
# Details:
# 	Compression needs to be applied at the ApplyBQSR step if merging with 
# 	GATK. SAMbamba merge makes compression=5 BAMs, but GATK merge can not
# 	compress (despite flags to that effect)
# Author: Cali Willet
# cali.willet@sydney.edu.au
# Date last modified: 24/07/2020
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

module load gatk/4.1.2.0 samtools/1.10

# special chracters in contig names requires this specific method to read in positional arguments:
IFS=','
params=($1)
labSampleID=${params[0]}
intervals_file=${params[1]}
counter=$(echo $intervals_file | cut -d '.' -f 3)

mem=7 #6 for normal or 7 for broadwell 

ref=./Reference/GCA_902635505.1_mSarHar1.11_genomic.fna
table=./BQSR_recal_tables/Round${round}/${labSampleID}.recal_data.table
bam_in=./Dedup_sort/${labSampleID}.coordSorted.dedup.bam
bam_out=./BQSR_apply/Round${round}/${labSampleID}.${counter}.recal.bam
log=./GATK_logs/BQSR_round${round}/${labSampleID}.${counter}.apply.oe
err=./Error_capture/BQSR_round${round}/${labSampleID}.${counter}.apply.err

rm -rf $log $err $bam_out

echo Using $NCPUS cpus > ${log}

if [[ $intervals_file =~ "unmapped" ]] #workaround re -L unmapped not working for devils (GATK ticket submitted)
then
	echo "$(date): Bootstrap round 1 step 9: Apply BQSR sample $labSampleID interval number $counter - unmapped. First make f12 BAM" >> ${log}
	
	f12_bam=./f12_unmapped_unrecal/${labSampleID}.f12.unrecal.bam
	samtools view -@ $NCPUS -f12 -bho ${f12_bam} ${bam_in} # ~ 20 mins at 2 CPU. chr1 takes 40 mins 
	gatk ApplyBQSR \
		--java-options "-Xmx${mem}G -Dsamjdk.compression_level=5 -DGATK_STACKTRACE_ON_USER_EXCEPTION=true" \
		-R ${ref} \
		-I ${f12_bam} \
		--bqsr-recal-file ${table} \
		--create-output-bam-index false \
		-O ${bam_out} >> ${log} 2>&1
else	
	echo "$(date): Bootstrap round 1 step 9: Apply BQSR sample $labSampleID interval number $counter" >> ${log}

	gatk ApplyBQSR \
		--java-options "-Xmx${mem}G -Dsamjdk.compression_level=5 -DGATK_STACKTRACE_ON_USER_EXCEPTION=true" \
		-R ${ref} \
		-I ${bam_in}  \
		--bqsr-recal-file ${table} \
		--arguments_file ${intervals_file} \
		--create-output-bam-index false \
		-O ${bam_out} >> ${log} 2>&1
fi


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
