#!/bin/bash

#########################################################
# 
# Platform: NCI Gadi HPC
# Description: run GATK GatherBQSRReports over parallel tasks
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

module load gatk/4.1.2.0  

round=<round>

labSampleID=$1

tables=$(find ./BQSR_recal_tables/Round${round} -name "${labSampleID}.*.recal_data.after.table")
tables=($tables)
tables_list=''

log=GATK_logs/BQSR_round${round}/${labSampleID}.gather-after.oe
err=./Error_capture/Bootstrap_BQSR_round${round}/${labSampleID}.gather-after.err
out=./BQSR_recal_tables/Round${round}/${labSampleID}.recal_data.after.table

rm -f $log $err

echo "$(date): Bootstrap round ${round} step 13: Gather BQSR "after recal" reports for sample ${labSampleID}" > ${log}

for file in ${tables[@]}
do 
	tables_list+=" -I $file"
done

gatk GatherBQSRReports \
	--java-options "-DGATK_STACKTRACE_ON_USER_EXCEPTION=true"\
	$tables_list \
	-O $out >> $log 2>&1
	
echo "$(date): Finished." >> ${log} 2>&1

if grep -q -i error $log
then 
        printf "Error in GATK log ${log}\n" >> $err
fi 

if grep -q Exception $log
then 
        printf "Exception in GATK log ${log}\n" >> $err
fi

