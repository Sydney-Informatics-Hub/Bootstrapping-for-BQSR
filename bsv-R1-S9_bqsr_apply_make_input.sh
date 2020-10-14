#!/bin/bash

#########################################################
# 
# Platform: NCI Gadi HPC
# Description: make inputs file for parallel exectuion of GATK ApplyBQSR
# Details:
# 	Job can be run as separate tumour/normal jobs, or as one job. 
#	The contigs do take longer to print for tumour compared to normal re 
#	more data to print, but the impact of input sample size on effiency is 
#	lower than for other jobs, as there are many more tasks than CPUs for 
#	this job and the walltime discrepancies among tasks are somewhat absorbed 
#	by the large number of tasks. The walltime is capped by the time to print 
#	chromosome 1, so the inputs are sorted by contig size so that the largest 
#	contigs are processed first. If no binomial grouping is desired, change 
#	group=true to group=false. Assumes all non-cancer samples have suffix '-N',
#	all other phenotype IDs are assigned to tumour.
#	Sample info is read from <cohort>.config
#
# Author: Cali Willet
# cali.willet@sydney.edu.au
# Date last modified: 14/10/2020
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


cohort=<cohort>
config=${cohort}.config

group=false

t_input=./Inputs/bqsr_apply.inputs-tumour
n_input=./Inputs/bqsr_apply.inputs-normal
input=./Inputs/bqsr_apply.inputs

rm -f $t_input
rm -f $n_input
rm -f $input

dict=<dict>

tasks=7 # Need to work out a way of automating this, but for now ths is decided  manually: use the dict file to determine the optimal number of tasks, which will usually be the number of autosomes + X plus 1, 
# ie do all the large contigs as separate tasks, then 1 extra task to do the remaining contigs (Y if present, MT, unplaced) plus the unmapped in one list
# Doing it this way instead of all contigs as their own parallel tasks will not speed up this job, but will increase speed and lower RAM usage for the subsequent merge job. 


### 3/9/20: submitted ticket to GATK re -L unmapped not working for Devils. For now. must run unmapped as it's own task and use f12 extracted BAM and no -L flag, so intervals has been increased from 7 to 8
### 7/10/20: the issue with the -L unmapped not working seems to be due to the large chrs (of course!) as for read pairs where the inferred insert size is massive, ValidateSamFile throws an error.  
((tasks--)) # reduce the value of 'tasks' to be zero-based to match the contigs array

contigs=$(awk '$2~/^SN/ {print $2}' $dict | sed 's/SN\://')
contigs=($contigs)
#contigs+=( "unmapped" )

function print_inputs {
	if [[ $group = true ]]
	then
		if [[ $labSampleID = *-N ]]
       		then
                	printf "${labSampleID},${intervals_file}\n" >> $n_input
        	else
                	printf "${labSampleID},${intervals_file}\n" >> $t_input
        	fi
	else			
		printf "${labSampleID},${intervals_file}\n" >> $input 
	fi 
}

awk 'NR>1' ${config} | while read CONFIG
do 
        labSampleID=`echo $CONFIG | cut -d ' ' -f 2`
	intervals_file=./Inputs/bqsr_apply_${labSampleID}.intervals
	
	for ((i=0;i<${#contigs[@]};i++)) # make intervals file	
	do
		#chrs=$(expr $tasks - 2) ###hack re unmapped issue - was $i -lt $tasks
		#if [[ $i -le $chrs ]] # the first 6 chrs
		if [[ $i -lt $tasks ]] 
		then
			intervals="-L ${contigs[i]}"
			intervals_file=./Inputs/bqsr_apply_${labSampleID}.${i}.intervals
			echo ${intervals} > ${intervals_file}
			print_inputs
			intervals=''
		#elif [[ ${contigs[$i]} != 'unmapped' ]] # contigs 7 - 105. hack for unmapped issue - was just 'else' 
		else
			#label=$(expr $tasks - 1) # yet another hack 
			#intervals_file=./Inputs/bqsr_apply_${labSampleID}.${label}.intervals #hak - label var was tasks
			intervals_file=./Inputs/bqsr_apply_${labSampleID}.${tasks}.intervals			
			intervals+=" -L ${contigs[i]}"	
			#echo ${intervals} > ${intervals_file}
			
			#print_inputs

			
		#else # the unmapped hack - run unmapped as it's own private task 
			
			#intervals_file=./Inputs/bqsr_apply_${labSampleID}.${tasks}.intervals
			#intervals=''
			#touch ${intervals_file}
			#print_inputs
		fi    	
	done
	echo ${intervals} > ${intervals_file}
	print_inputs
	
	last=$(expr $tasks + 1) # hack to add on the unmapped as a separate task instead of being at the end of the long list interval 
	intervals_file=./Inputs/bqsr_apply_${labSampleID}.${last}.unmapped.intervals
	touch $intervals_file # just to make it easy to parse to run sh script 
	print_inputs		
done 


if [ -f $input ]
then
        tasks=`wc -l < $input`
        printf "Number of ApplyBQSR tasks to run: ${tasks}\n"
	sort -t '.' -n -k3 $input > ./Inputs/bqsr_apply_reordered.input
	mv ./Inputs/bqsr_apply_reordered.input $input
fi


if [ -f $n_input ]
then
        tasks=`wc -l < $n_input`
        printf "Number of ApplyBQSR normal sample tasks to run: ${tasks}\n"
	sort -t '.' -n -k3 $n_input > ./Inputs/bqsr_apply_reordered_normal.input
	mv ./Inputs/bqsr_apply_reordered_normal.input $n_input
fi

if [ -f $t_input ]
then
        tasks=`wc -l < $t_input`
        printf "Number of ApplyBQSR tumour sample tasks to run: ${tasks}\n"
	sort -t '.' -n -k3 $t_input > ./Inputs/bqsr_apply_reordered_tumour.input
	mv ./Inputs/bqsr_apply_reordered_tumour.input $t_input
fi
