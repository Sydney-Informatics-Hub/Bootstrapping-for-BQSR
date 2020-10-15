#!/bin/bash

#########################################################
# 
# Platform: NCI Gadi HPC
# Description: Create input files for run gatk4 GenomicsDBImport in parallel
# Requires 'times' path to be manually updated by user
# Author: Cali Willet and Tracy Chew
# cali.willet@sydney.edu.au;tracy.chew@sydney.edu.au
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

cohort=<cohort>
config=${cohort}.config
round=<round>
index=<index> # to determine whether .gz is appropriate for output or not. had to drop the GZ for devils, it threw an invalid file pointer error

chunks=5
ints=3200 

map=./Inputs/genomicsdbimport.round${round}.sample_map
input=./Inputs/genomicsdbimport.inputs
vcfdir=./GVCFs/Round${round}

# Make sample map:
awk 'NR>1' ${config} | while read LINE
do
	sample=`echo $LINE | cut -d ' ' -f 2`	
	if [[ $index =~ BAI ]]
	then
       		printf "${sample}\t./GVCFs/${sample}/${sample}.g.vcf.gz\n" >> $map
	elif [[ $index =~ CSI ]]
	then
        	printf "${sample}\t./GVCFs/Round${round}/${sample}/${sample}.g.vcf\n" >> $map
	else
        	echo Must specify CSI or BAI - you have specified $index. Aborting.
       	 exit
	fi	
done

# Make input list, sort intervals based on last import run:
times=/scratch/ch81/Devil_resequencing/Program_logs/genomicsdbimport_interval_duration_memory.txt ####manually check this path!!!!!!!!!
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

