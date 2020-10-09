#! /bin/bash

# Create input file to run gatk4_genotypegvcfs_run_parallel.pbs
# Operates on per interval GenomicsDBImport database files
# Performs joint genotyping (output is uncalibrated jointly genotyped VCF)
#Sort the input list largest to smallest based on first roundof genotypeGVCFs 
# (pre bootstrap). Time range is 2 - 87 minutes per interval. There are not a handful of long
# running outliers like genomicsDBimport - the walltime is fairly spread.
# Given last run was oK at 15.4 GB per task, run this on normal nodes not hugemem,
# so that having an ordered list willbe beneficial (unlike if it was 5 chunks on hugemem where 
# the first chunk would have all the long runners)



if [ -z "$1" ]
then
        echo "Please run this script with the base name of ../<cohort>.config as argument"
	exit
fi

cohort=$1

round=1

logdir=./GATK_logs/GenomicsDBImport_round${round}
list=/scratch/ch81/Devil_resequencing/Program_logs/GenotypeGVCFs_logs/interval_duration_memory.txt

input=./Inputs/genotypegvcfs.inputs
rm -rf $input

echo Writing $input

awk 'NR>1' $list | sort -rnk 2 | awk '{print $1}' > $input

if [ -f $input ]
then
        tasks=`wc -l < $input`
        printf "Number of genotype GVCF tasks to run: ${tasks}\n"
else
	echo Something went wrong - no $input file created
fi
