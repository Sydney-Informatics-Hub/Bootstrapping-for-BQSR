#!/bin/bash

#Create input for: hc_gathervcfs_run_parallel.pbs
#Need a sample list for the run_parallel script and a
#list of VCFs per sample

# Devils have a low cov and high cov group - made  change to the config 
# by adding 5th col for group and now library can't be left blank for default (if 
# so, would require changing the align script that reads lib from col 4) 
# New group method will use the type specified in 'Group' col to name the 
# by-group inputs files. 

set -e


if [ -z "$1" ]
then
        echo "Please run this script with the base name of your config file"
        exit
fi

cohort=$1
round=1
group=false
 
vcfdir=./GVCFs/Round${round}

input=./Inputs/hc_gathervcfs.inputs
rm -rf $input

if [[ $group = true ]]
then
	groups=$(awk 'NR>1 {print $5}' ${cohort}.config | sort | uniq)
	groups=($groups)
	for (( i = 0; i < ${#groups[@]}; i ++ ))
	do
		rm -rf ${input}-${groups[$i]}
		echo Making inputs file ${input}-${groups[$i]}
	done
fi	

# Make inputs and args files: 	
awk 'NR>1' ${cohort}.config | while read LINE
do
	sample=`echo $LINE | cut -d ' ' -f 2`
	
	# Make inputs file for run parallel:
	if [[ $group = true ]]
	then
		group_name=`echo $LINE | cut -d ' ' -f 5`	
		echo $sample >> ${input}-${group_name}
	else
		echo $sample >> ${input}
	fi
	
	# Make args file per sample:
	args=${vcfdir}/${sample}/${sample}.gather.args
	rm -rf ${args}
	for interval in $(seq -f "%04g" 0 3199)
	do
		echo "--I ${vcfdir}/${sample}/${sample}.${interval}.vcf" >> ${args}
	done
done

# Report number of inputs: 
if [[ $group = true ]]
then
	for (( i = 0; i < ${#groups[@]}; i ++ ))
	do
		file=${input}-${groups[$i]}
		if [ -f $file ]
		then
        		tasks=`wc -l < $file`
        		printf "Number of GVCF gather tasks to run for group ${groups[$i]}: ${tasks}\n"
		else
        		echo Something went wrong - $file file not created 
		fi		
	done
else 
	if [ -f $input ]
	then
        	tasks=`wc -l < $input`
        	printf "Number of GVCF gather tasks to run: ${tasks}\n"
	else
        	echo Something went wrong - $input file not created 
	fi
fi
