#!/bin/bash

#########################################################
# 
# Platform: NCI Gadi HPC
# Description: check output from step 21 and write any failed tassk to inputs list
# If no failed tasks, tarball the gatk logs.
# Author: Tracy Chew and Cali Willet
# tracy.chew@sydney.edu.au;cali.willet@sydney.edu.au
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


perlscript=./bsv-R1-S22_genotypegvcfs_checklogs.pl
logdir=./GATK_logs/GenotypeGVCFs_round${round}
errordir=./Error_capture/GenotypeGVCFs_round${round}
perlout=${logdir}/${cohort}_interval_duration_memory.txt
input=./Inputs/genotypegvcfs_missing.inputs
rm -rf $input


# Run perl script to get duration
`perl $perlscript $logdir $cohort`
wait


# Check output file 
{
read # skip header
while read -r interval duration memory
do
	err=${errordir}/${interval}.err
	if [[ $duration =~ NA || $memory =~ NA ]]
	then
		redo+=("$interval")
        elif [ -f $err ]
	then
		redo+=("$interval")
	fi
done 
} < $perlout


# Report errors
if [[ ${#redo[@]}>1 ]]
then
	echo "There are ${#redo[@]} intervals that need to be re-run."
	echo "Writing inputs to ${input}"
	
	for redo_interval in ${redo[@]}
	do
		echo ${redo_interval} >> ${input}
	done
else
	echo "There are no intervals that need to be re-run. Tidying up..."
	cd ${logdir}
	tar --remove-files -czf genotypegvcfs_logs.tar.gz *.oe
fi
