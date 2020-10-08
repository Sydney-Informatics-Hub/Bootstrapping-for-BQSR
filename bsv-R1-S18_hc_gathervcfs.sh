#!/bin/bash

#Merge interval level haplotypecaller VCFs per sample
#Final output is tabix indexed but NOT gzipped (issue with Devils chr sizes)

### Failed run for devils: has -Xmx28 per task for 1 CPU hugemem - low cov samples took
# twice as long to run as March run (6 x normal CPUs, no Xmx value) and high cov samples
# died on 2 hrs walltime on chr 1 despite completing in 59 mins in March run
# Re-submit the parallel tasks without Xmx and with separate batches for high and low cov


module load gatk/4.1.2.0

set -e

sample=$1

round=1

args=./GVCFs/Round${round}/${sample}/${sample}.gather.args

mkdir -p ./GVCFs/Round${round}/${sample} ./GATK_logs/HC_round${round}/${sample}

out=./GVCFs/Round${round}/${sample}/${sample}.g.vcf #had to drop the GZ for devils, it threw an invalid file pointer error 
log=./GATK_logs/HC_round${round}/${sample}/${sample}.gather.oe
err=./Error_capture/HC_gather_round${round}/${sample}.err

rm -rf $out $log $err 

gatk GatherVcfs \
	--java-options "-DGATK_STACKTRACE_ON_USER_EXCEPTION=true" \
	--arguments_file ${args} \
	--MAX_RECORDS_IN_RAM 100000000 \
	-O ${out} > ${log} 2>&1


if grep -q -i error $log
then 
        printf "Error in GATK log ${log}\n" >> $err
fi 

if grep -q Exception $log # This cannot be -i because the java option is printed to the log
then 
        printf "Exception in GATK log ${log}\n" >> $err
fi
