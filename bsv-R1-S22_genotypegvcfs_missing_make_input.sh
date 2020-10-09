#! /bin/bash

# Check output of genotypeGVCFs
# Create input file to rerun failed tasks


if [ -z "$1" ]
then
	echo "Please run this script with the base name of ../<cohort>.config as argument"
	exit
fi

cohort=$1
round=1


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
