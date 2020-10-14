#!/bin/bash

#########################################################
# 
# Platform: NCI Gadi HPC
# Description: run parallel exectuion of GATK AnalyzeCovariates
# Author: Cali Willet
# cali.willet@sydney.edu.au
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

module load gatk/4.1.2.0 

round=<round>

labSampleID=$1 

before=./BQSR_recal_tables/Round${round}/${labSampleID}.recal_data.table
after=./BQSR_recal_tables/Round${round}/${labSampleID}.recal_data.after.table

log=GATK_logs/BQSR_round${round}/${labSampleID}.anacov.oe
err=./Error_capture/BQSR_round${round}/${labSampleID}.anacov.err
plots=./Analyse_covariates/Round${round}/${labSampleID}.anacov-R${round}.pdf 
csv=./Analyse_covariates/Round${round}/${labSampleID}.anacov-R${round}.csv

rm -rf $log $err

echo "$(date): Bootstrap round ${round} step 14: Analyse covariates pre vs post recalibration for sample ${labSampleID}" > ${log}

gatk AnalyzeCovariates \
	--java-options "-DGATK_STACKTRACE_ON_USER_EXCEPTION=true" \
	-before ${before} \
	-after ${after} \
	-plots ${plots} \
	-csv ${csv} >> $log 2>&1
	
echo "$(date): Finished." >> ${log} 2>&1

if grep -q -i error $log
then 
        printf "Error in GATK log ${log}\n" >> $err
fi 

if grep -q Exception $log
then 
        printf "Exception in GATK log ${log}\n" >> $err
fi



	

