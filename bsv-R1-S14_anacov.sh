#!/bin/bash


module load gatk/4.1.2.0 

round=1

labSampleID=`echo $1 | cut -d ',' -f 1` 

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
	

if grep -q -i error $log
then 
        printf "Error in GATK log ${log}\n" >> $err
fi 

if grep -q Exception $log
then 
        printf "Exception in GATK log ${log}\n" >> $err
fi



	

