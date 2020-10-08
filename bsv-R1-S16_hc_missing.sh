#!/bin/bash

# Run GATK HC using scatter-gather method

ulimit -s unlimited # Advise from Andrey B

round=1
ref=./Reference/GCA_902635505.1_mSarHar1.11_genomic.fna

module load gatk/4.1.2.0
module load samtools/1.10

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

echo "$(date) : Start GATK 4 HaplotypeCaller on recalibrated BAM from bootstrapping round ${round}. Reference: ${ref}; Sample: ${sample}; Bam: ${bam}; Interval: ${interval}" > ${log}

gatk HaplotypeCaller \
	--java-options "-Xmx7g -DGATK_STACKTRACE_ON_USER_EXCEPTION=true" \
	-R ${ref} \
	-I ${bam} \
	-L ${interval} \
	-O ${gvcf} \
	-G StandardAnnotation \
	-G AS_StandardAnnotation \
	-G StandardHCAnnotation \
	--native-pair-hmm-threads ${NCPUS} \
	-ERC GVCF 2>>${log}

echo "$(date) : Finished GATK 4 Haplotype Caller for: ${gvcf}" >> ${log}

if grep -q -i error $log
then 
        printf "Error in GATK log ${log}\n" >> $err
fi 

if grep -q Exception $log
then 
        printf "Exception in GATK log ${log}\n" >> $err
fi
