#!/bin/bash

#Create input files for run gatk4 GenomicsDBImport in parallel
#Consolidates VCFs across multiple samples for each interval
#Run after merging interval VCFs into GVCF per sample (operates on GVCFs)
# this job needs lots of ram - 192 GB per interval for Devils - so run as 
# 5 x 640 task batches
# Use the interval times fro fist round (pre bootstrap) calling to sort tasks so 
# the  handful of slow runners are first

if [ -z "$1" ]
then
        echo "Please run this script with the base name of your config file"
        exit
fi

cohort=$1

round=1

chunks=5
ints=3200 

map=./Inputs/genomicsdbimport.round${round}.sample_map
input=./Inputs/genomicsdbimport.inputs
vcfdir=./GVCFs/Round${round}

# Make sample map:
awk 'NR>1' ${cohort}.config | while read LINE
do
	sample=`echo $LINE | cut -d ' ' -f 2`	
	#printf "${sample}\t./GVCFs/${sample}/${sample}.g.vcf.gz\n" >> gatk4_genomicsdbimport.sample_map # can't have GZ for Devils 
	printf "${sample}\t./GVCFs/Round${round}/${sample}/${sample}.g.vcf\n" >> $map
done

# Make input list, sort intervals based on last import run:
times=/scratch/ch81/Devil_resequencing/Program_logs/genomicsdbimport_interval_duration_memory.txt
intervals=$(awk 'NR>1' $times | sort -rnk 2  | awk '{print $1}')
intervals=($intervals)

c=$(expr $ints / $chunks)

echo There are $ints intervals, process as $chunks job chunks with $c tasks per chunk 
s=0
for (( i = 1; i <= ${chunks}; i ++ ))
do
	input_chunk=${input}-chunk${i}
	printf "\tWriting ${input_chunk}\n"
	rm -rf $input_chunk
	for (( n = 1; n <= $c; n++ ))
	do
		int_num=$(expr $s + $n )
		interval=${intervals[$int_num - 1]}
		echo $interval	>> $input_chunk
	done
	s=$(expr $i \* $c )	
done

echo Sample map is $map  	

