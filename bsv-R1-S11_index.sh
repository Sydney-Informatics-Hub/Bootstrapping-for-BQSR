#!/bin/bash

#########################################################
# 
# Platform: NCI Gadi HPC
# Description: create CSI or BAI index for the dedup/sort BAM file
# User must specify which
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

round=<round>

module load samtools/1.10

labSampleID=$1

index=<index> #options: BAI or CSI . Need to automate this from .dict


bam=./BQSR_bams/Round${round}/${labSampleID}.bqsr-R${round}.bam 

if [[ $index =~ BAI ]]
then
	samtools index -@ $NCPUS $bam 
elif [[ $index =~ CSI ]]
then
	samtools index -@ $NCPUS -c $bam
else
	echo Must specify CSI or BAI - you have specified $index. Aborting.
	exit
fi 


