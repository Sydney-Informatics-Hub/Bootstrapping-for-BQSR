#!/bin/bash

#########################################################
# 
# Platform: NCI Gadi HPC
# Description: run GATK GatherBQSRReports over parallel tasks
# Usage: this script is executed by bqsr_gather_run_parallel.pbs
# Author: Cali Willet
# cali.willet@sydney.edu.au
# Date last modified: 02/09/2020
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

module load gatk/4.1.2.0

labSampleID=$1

tables=$(find ./BQSR_recal_tables/Round${round} -name "${labSampleID}.*.recal_data.table")
tables=($tables)
tables_list=''

log=GATK_logs/BQSR_round${round}/${labSampleID}.gather.oe
err=./Error_capture/Bootstrap_BQSR_round${round}/${labSampleID}.gather.err
out=./BQSR_recal_tables/Round${round}/${labSampleID}.recal_data.table

rm -f $log $err

echo "$(date): Bootstrap round ${round} step 8: Gather BQSR reports for sample ${labSampleID}" > ${log}

for file in ${tables[@]}
do 
	tables_list+=" -I $file"
done

gatk GatherBQSRReports \
	$tables_list \
	-O $out >> $log 2>&1


if grep -q -i error $log
then 
        printf "Error in GATK log ${log}\n" >> $err
fi 

if grep -q Exception $log
then 
        printf "Exception in GATK log ${log}\n" >> $err
fi

