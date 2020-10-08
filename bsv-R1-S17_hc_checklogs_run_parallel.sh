#!/bin/bash

#PBS -P ch81
#PBS -N bsv-R1-S17
#PBS -l walltime=00:10:00
#PBS -l ncpus=37
#PBS -l mem=148GB
#PBS -q express
#PBS -W umask=022
#PBS -l wd
#PBS -o ./Logs/bsv-R1-S17.o
#PBS -e ./Logs/bsv-R1-S17.e
#PBS -lstorage=scratch/er01+scratch/ch81

module load openmpi/4.0.2
module load nci-parallel/1.0.0

set -e

round=1

SCRIPT=./bsv-R1-S17_hc_checklogs.pl
INPUTS=./Inputs/hc_checklogs.inputs
OUTPUTS=./Inputs/hc_checklogs_missing.inputs # if this script discovers any failed tasks, they will be written here


NCPUS=1  

#########################################################
# Do not edit below this line (unless running on a node that 
# does not have 48 CPU, in which case edit the value of 'CPN'
#########################################################

CPN=48 #CPUs per node.  48 for intel xeon, 28 for broadwell  
M=$(( CPN / NCPUS )) #tasks per node

sed "s|^|${SCRIPT} |" ${INPUTS} > ${PBS_JOBFS}/input-file

mpirun --np $((M * PBS_NCPUS / 48)) \
        --map-by node:PE=${NCPUS} \
        nci-parallel \
        --verbose \
        --input-file ${PBS_JOBFS}/input-file


# Now report the samples with failed intervals, and make a list for rerunning
# The reports cannot be made from within the parallel tasks, as they will overwrite each other to the .o file

find ./GATK_logs/HC_round${round}/ -name *_errors.txt -print | xargs cat > $OUTPUTS

tasks=`wc -l < $OUTPUTS`

if [[ $tasks -gt 0 ]]
then
	printf "Number of failed GATK4 HC tasks: ${tasks}\nPlease use $OUTPUTS as input to bsv-R${round}-S16_hc_missing_run_parallel.pbs\n"
else
	printf "No failed GATK4 HC tasks were detected.\n"
	rm -rf $OUTPUTS	
fi	
	

