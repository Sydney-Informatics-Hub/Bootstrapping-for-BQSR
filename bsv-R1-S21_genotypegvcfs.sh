#!/bin/bash

# Ran with 4.1.8.1 and newer java to test a new flag "--genomicsdb-shared-posixfs-optimizations"
# in latest ver, but the efficiency and lustre load was not improved 

module load gatk/4.1.2.0 

index=$1
interval=./Reference/HC_intervals/${index}-scattered.interval_list


round=1
ref=./Reference/GCA_902635505.1_mSarHar1.11_genomic.fna
cohort=Devils_N37


gendbdir=./GenomicsDBImport/Round${round}
outdir=./GenotypeGVCFs/Round${round}
logdir=./GATK_logs/GenotypeGVCFs_round${round}
log=${logdir}/${index}.oe
err=./Error_capture/GenotypeGVCFs_round${round}/${index}.err
rm -rf $log $err

out=${outdir}/${cohort}.${index}.vcf.gz
rm -rf ${out}*
tmp=${PBS_JOBFS}/${index} # Andrey has recommended to use jobfs for temp. He said it will slow down by 10% but still recommends...
mkdir -p ${tmp}

echo "$(date) : Start GATK 4 GenotypeGVCFs. Reference: ${ref}; Cohort: ${cohort}; Interval: ${interval}" > ${log} 2>&1

gatk GenotypeGVCFs \
	--java-options "-Xmx6g -Dsamjdk.compression_level=5 -DGATK_STACKTRACE_ON_USER_EXCEPTION=true" \
	-R ${ref} \
	-V gendb://${gendbdir}/${index} \
	--tmp-dir ${tmp} \
	-OVI FALSE \
	-O ${out} >> ${log} 2>&1

echo "$(date) : Finished GATK 4 joing genotyping with GenotypeGVCFs for: ${out}" >> ${log} 2>&1

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
