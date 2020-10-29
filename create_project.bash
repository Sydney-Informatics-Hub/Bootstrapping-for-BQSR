#!/bin/bash

# Step 1 of the bootstrapping pipeline:
# There are 64 scripts in this pipeline, and the edits
# that are required are mainly project, 'round' number and 
# reference sequence name. Use this script to edit all of 
# the 64 pipeline scripts, as well as create the required directory set up.
# As the 'sed' commands within this script operate on .sh and .pbs files, 
# this setup script has been intentionally named .bash (easiest solution).

#### functions####
function storage {
echo Do you require read/write to any Gadi storage other than /scratch/${project}? If yes, please enter all separated by space \[enter for no\]:

read more_storage
IFS=' ' read -r -a array <<< "$more_storage"

lstorage=scratch/${project}
for i in "${!array[@]}"
do
    path=$(echo ${array[i]} | sed 's/^\///g')
    lstorage+="+${path}"
done

echo
echo PBS lstorage directive will be: $lstorage
echo Is this correct? Enter y or n

read answer

if [[ $answer != y ]]
then 
	storage
else
	echo Using lstorage $lstorage
	echo
	return 0	
fi

}
###################


# Make required starting directories:
echo Making Logs directory
mkdir -p Logs
echo

# Config file
echo Enter your cohort name / the basename of your config file:
read cohort
config=${cohort}.config

if [ -f $config ] 
then
	echo Using config $config
	sed -i "s/^cohort=.*/cohort=${cohort}/" *.sh
	sed -i "s/^cohort=.*/cohort=${cohort}/" *.pbs 
	sed -i "s/^config=.*/config=${config}/" *.sh
	sed -i "s/^config=.*/config=${config}/" *.pbs	
	echo
else
	echo $config does not exist - please fix. Aborting.
	exit
fi

# NCI project
echo Enter the name of your NCI project:
read project

echo Using NCI project $project for accounting and /scratch/${project} for read/write
sed -i "s/#PBS -P.*/#PBS -P ${project}/" *.pbs
echo


# Call storage function as many times as needed
storage
sed -i "s|#PBS -lstorage=.*|#PBS -lstorage=${lstorage}|" *.pbs


# Bootstrap round
echo Enter the round number of bootstraping \(eg 1, 2 \):
read round

echo Updating 'round' variable to ${round}
sed -i "s/^round=.*/round=${round}/" *.sh
sed -i "s/^round=.*/round=${round}/" *.pbs
echo


# Reference genome
echo This directory needs a symlink to your full \"Reference\" named directory \(as used in Fastq-to-BAM and Germline-ShortV\)
echo Enter the full path to your reference directory:
read refpath

if [ ! -d ./Reference ]
then
	echo Creating symlink $refpath to ./Reference
	ln -s $refpath Reference
else
	echo ./Reference already exists. Assuming this is the complete and correct directory and continuing
fi
echo

echo Enter the name of your reference genome sequence \(include suffix\):
read ref

ref=./Reference/${ref}
dict=${ref/\.[a-zA-Z]*/.dict}

if [ ! -f ${ref} ] 
then
	echo ${ref} does not exist - please check. Aborting. 
	exit
elif [ ! -f ${dict} ]
then
	 echo ${dict} does not exist - please check. Aborting. 
	 exit
else
	echo Using reference genome files ${ref} and ${dict}
	sed -i "s|^ref=.*|ref=${ref}|" *.sh
	sed -i "s|^ref=.*|ref=${ref}|" *.pbs 	
	sed -i "s|^dict=.*|dict=${dict}|" *.sh
	sed -i "s|^dict=.*|dict=${dict}|" *.pbs 	
	echo	
fi

echo Does your reference genome require CSI indexed BAM files? Enter y if your reference genome has very large chrs/contigs \(longer than 2^29-1 bp\) otherwise enter n:
read index_answer

if [[ $index_answer =~ y ]]
then
	index=CSI
	echo Using CSI indexing \(large chrs\/contigs\) for BAM files
else
	index=BAI
	echo Using BAI indexing \(\"normal\" sized chrs\/contigs\) for BAM files
	echo
fi
sed -i "s|^index=.*|index=${index}|" *.sh
sed -i "s|^index=.*|index=${index}|" *.pbs 
	

echo The scripts in this directory have now been updated to include the following:
printf "\tNCI accounting project: ${project}\n \
\tPBS lstorage directive: ${lstorage}\n \
\tCohort config file: ${cohort}.config\n \
\tBootstrapping round: ${round}\n \
\tReference genome sequence: ${ref}\n \
\tReference genome dictionary file: ${dict}\n \
\tBAM index format: ${index}\n"






