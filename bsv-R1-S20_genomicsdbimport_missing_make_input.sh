#! /bin/bash

# Create input file to check log files in parallel
# For each sample, record minutes taken per interval
# Flag any intervals with error messages
# If there are no error messages, archive log files in a per sample tarball

if [ -z "$1" ]
then
	echo "Please run this script with the base name of ../<cohort>.config as argument"
	exit
fi

cohort=$1

round=1

logdir=./GATK_logs/GenomicsDBImport_round${round}
errordir=./Error_capture/GenomicsDBImport_round${round}
perlscript=./bsv-R1-S20_genomicsdbimport_checklogs.pl
perlout=${logdir}/${cohort}_interval_duration_memory.txt
input=./Inputs/genomicsdbimport_missing.inputs
rm -rf $input


# Run perl script to get duration 
# hashed out the exist check as I want the existing updated with the tasks completed from missing run parallel
if [ ! -f $perlout ]
then
	`perl $perlscript $logdir $cohort`
	wait
fi


# Check output file 
{
read # skip header
while read -r interval duration memory
do
	err=${errordir}/${interval}.err	
	if [[ $duration =~ NA || $memory =~ NA ]]
	then
		redo+=("$interval")
	#elif grep -q Exception ${logdir}/${interval}.oe # no need to grep the .oe file, as this was done in the task and any grep printed to Error_capture
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
	tar --remove-files -czvf genomicsdbimport_logs.tar.gz *.oe
fi
