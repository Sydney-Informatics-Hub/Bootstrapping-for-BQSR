#!/bin/bash

#Consolidate interval VCFs across multiple samples for GenotypeGVCFs (joint-calling)

module load gatk/4.1.2.0 

round=1
ref=./Reference/GCA_902635505.1_mSarHar1.11_genomic.fna

int=$1
interval=./Reference/HC_intervals/${int}-scattered.interval_list

sample_map=./Inputs/genomicsdbimport.round${round}.sample_map
log=./GATK_logs/GenomicsDBImport_round${round}/${int}.oe
err=./Error_capture/GenomicsDBImport_round${round}/${int}.err
rm -rf $err

outdir=./GenomicsDBImport/Round${round}
out=${outdir}/${int}
rm -rf ${out} #out must be an empty or non-existent directory

tmp=${outdir}/tmp/${int}
rm -rf ${tmp}
mkdir ${tmp}

echo "$(date) : Start GATK4 GenomicsDBImport for bootstrap round $round. Reference: ${ref}; Interval: ${interval}; Sample map: ${sample_map}; Out: ${out}; Log: ${log}" > ${log}

gatk GenomicsDBImport \
	--java-options "-Xmx182g -DGATK_STACKTRACE_ON_USER_EXCEPTION=true" \
	--sample-name-map ${sample_map} \
	--overwrite-existing-genomicsdb-workspace \
	--genomicsdb-workspace-path ${out} \
	--tmp-dir ${tmp} \
	--intervals ${interval} >> ${log} 2>&1

echo "$(date) : Finished GATK 4 consolidate VCFs with GenomicsDBImport for: ${out}" >> ${log}

if grep -q -i error $log
then 
        printf "Error in GATK log ${log}\n" >> $err
fi 

if grep -q Exception $log
then 
        printf "Exception in GATK log ${log}\n" >> $err
fi








#Caveats
#IMPORTANT: The -Xmx value the tool is run with should be less than the total amount of physical memory available by at least a few GB, as the native TileDB library 
#requires additional memory on top of the Java memory. Failure to leave enough memory for the native code can result in confusing error messages!
#At least one interval must be provided
#Input GVCFs cannot contain multiple entries for a single genomic position
#The --genomicsdb-workspace-path must point to a non-existent or empty directory.
#GenomicsDBImport uses temporary disk storage during import. The amount of temporary disk storage required can exceed the space available, especially when specifying a 
#large number of intervals. The command line argument `--tmp-dir` can be used to specify an alternate temporary storage location with sufficient space..
