#!/bin/bash

#########################################################
# 
# Platform: NCI Gadi HPC
# Description: create BAM lists for merging recalibrated split 
# BAM files with GATK GatherBamFiles
# Details: GATK requires an ordered list of BAMs to merge. The 
#	inputs are N recalibrated contig BAMs labelled as
#	and a recalobrated BAM with f12 unmapped read pairs.
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


intervals=$(ls -1 ./Reference/BQSR_apply_intervals | cut -d '-' -f 1) # Use this for 5.9.2
intervals=($intervals)

#intervals=8 # use this for 5.9.1 . Set the number of intervals over which ApplyBQSR was run (including unmapped), eg for Devils: 8, for hg38: 3367

bams_in=./BQSR_apply/Round${round}
mkdir -p ./Inputs/BQSR_merge_lists

samples=$(awk 'NR > 1 {print $2}' ${config})
samples=($samples)

for (( s = 0; s < ${#samples[@]}; s++ ))
do
	labSampleID=${samples[$s]}
	list=./Inputs/BQSR_merge_lists/${labSampleID}.list
	\rm -rf $list
	
	# Following 5.9.1:
	#for (( i = 0; i < ${intervals}; i++ )) # manual interval set, include unmapped in interval count, counter used - man this is rough.. 
	#do 
		#printf "${bams_in}/${labSampleID}.${i}.recal.bam\n" >> $list		
	#done
	
	# Following 5.9.2:
	for (( i = 0; i < ${#intervals[@]}; i++ )) #when intervals are derived from SPlitIntervals
	do
		printf "${bams_in}/${labSampleID}.${interval[$i]}.recal.bam\n" >> $list
	done
	printf "${bams_in}/${labSampleID}.unmapped.recal.bam\n" >> $list
done
















