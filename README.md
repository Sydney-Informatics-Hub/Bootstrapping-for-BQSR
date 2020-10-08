# Bootstrapping-for-BQSR

# Introduction
This is a pipeline for bootstrapping a variant resource to enable GATK base quality score recalibration (BQSR; see links below) for non-model organisms that lack a publicly available variant resource. Multiple rounds of bootstrapping can be performed. After the initial round, assess your final VCF variants and metrics and if a second round is desired, repeat all bootstrapping steps.

# Useful links
Thorough overview of steps: https://gencore.bio.nyu.edu/variant-calling-pipeline-gatk4/

BQSR overview - https://gatk.broadinstitute.org/hc/en-us/articles/360035890531-Base-Quality-Score-Recalibration-BQSR-

Known vars/training/truth sets: https://gatk.broadinstitute.org/hc/en-us/articles/360035890831-Known-variants-Training-resources-Truth-sets

Checking BQSR pre vs post AnalyseCovariates plots - https://gatk.broadinstitute.org/hc/en-us/articles/360035890531-Base-Quality-Score-Recalibration-BQSR- 

# Data pre-processing
Prior to commencing this bootstrapping pipeline, the Sydney Informatics Hub Bioinformatics workflows https://github.com/Sydney-Informatics-Hub/Fastq-to-BAM and https://github.com/Sydney-Informatics-Hub/Germline-ShortV must be completed. 

In brief, these steps are:

1)	Index the reference genome seqeunce
2)	Create intervals for variant calling (3200)
3)	FastQC		
4)	Fastq split
5)	Collect fastq logs (perl) – reports reads, estimates duplication, etc
6)	Check fastq split sizes (requires fastQC data.txt)
7)	Align parallel (tasks per sample = number of split fastq pairs) 
8)	Check Bam sizes – quick check that assumes the fastq.gz are in default gzip format (eg some pre-processing tools write the new fastq in a different compression so this will throw out the values -expect Bam to be ~ 1.4-~1.45 times larger than the total fastq input size per sample 
9)	Merge to per-sample raw bam
10)	Dedup/sort and index
11)	Collect dup logs (summarises dup % etc)
12)	Reformat split disc (converts the split/disc read sam files to sorted, indexed BAM – useful for SV calling later) 
13)	Index 
14)	Alignment metrics
15)	Haplotype caller parallel (tasks per sample = 3200)
16)	HC check scripts
17)	Gather VCFs (tasks per sample = 1)
18)	Genomics db import ( tasks per cohort = 3200)
19)	Db import check scripts
20)	Genotype GVCFs (tasks per cohort = 3200)
21)	Genotype GVCFs check scripts
22)	Gather VCFs (tasks per cohort = 1)


# Samples
The sample information needs to be in the <cohort>.config format used in the Fastq-to_BAM and Germline-ShortV pipelines. If there is a large discrepancy in sample BAM size, samples may be grouped into batches for some steps eg "high-cov" and "low-cov" in order to increase CPU efficiency and decrease KSU usage, but this is not necessary. In this event, please make <cohort>.config-<group> files per sized batches and edit the "make input" and "run parallel" scripts as appropriate at each step. 

# Bootstrapping steps

The following 24 steps are for ONE round of bootstrapping. If multiple rounds are desired, repeat steps 1 - 24 and update the 'round' variable in each script to avoid overwriting the outputs from round 1. 

The scripts are labelled 'bsv-R<round>-S<stepNumber>_<step_name>' to make it easy to understand the order in which the steps are executed. 

Resources are indicated from one cohort of 37 Tasmanian devils. 

Step 0: Create intervals for BQSR. Number of intervals must be (genome_size/100 Mb) – min interval size is 100 Mb. Number of intervals is determined by the script. Not listing this as a step, because ideally it should go in the same script as the generate HC intervals part - this will be updated later. 

Update the PBS directives (project, lstorage) and edit the 'ref' and 'dict' variables, then run:

```{bash Create BQSR intervals}
qsub create_bqsr_ref_intervals.pbs
```

Resources: 1 CPU, 1 GB mem, < 1 minute. 

## Extract SNPs
Use 'SelectVariants' to extract SNPs from the joint-called final output VCF from 'Germline-ShortV' pipeline to a SNP-only VCF. 

Update the PBS directives (project, lstorage) and edit the 'ref', 'round' (eg round 1, 2 etc of bootstrapping) and 'cohort' variables. Update the 'vcf_in' varable to the final VCF joint-genotyped output from the 'Germline-ShortV' pipeline, then run:

```{bash Extract SNPs}
qsub bsv-R1-S1_select_variants_snps.pbs
```

Resources: 1 hugemem CPU, 22 GB mem, ~ 5 minutes.

## Extract indels
Use 'SelectVariants' to extract indels from the joint-called final output VCF from 'Germline-ShortV' pipeline to an indel-only VCF. 

Update the PBS directives (project, lstorage) and edit the 'ref', 'round' and 'cohort' variables. Update the 'vcf_in' varable to the final VCF joint-genotyped output from the 'Germline-ShortV' pipeline, then run:

```{bash Extract indels}
qsub bsv-R1-S2_select_variants_indels.pbs
```

Resources: 1 hugemem CPU, 13 GB mem, ~ 4 minutes.

## Filter SNPs
Use 'VariantFiltration' to filter SNPs from the SNP-only VCF output from step 1. Filtering parameters have been taken from https://gencore.bio.nyu.edu/variant-calling-pipeline-gatk4/

Update the PBS directives (project, lstorage) and edit the 'ref', 'round' and 'cohort' variables, then run:

```{bash Filter SNPs}
qsub bsv-R1-S3_filter_variants_snps.pbs
```

Resources: 1 hugemem CPU, 15 GB mem, ~ 2 minutes.

## Filter indels
Use 'VariantFiltration' to filter indels from the indel-only VCF output from step 2. Filtering parameters have been taken from https://gencore.bio.nyu.edu/variant-calling-pipeline-gatk4/

Update the PBS directives (project, lstorage) and edit the 'ref', 'round' and 'cohort' variables, then run:

```{bash Filter indels}
qsub bsv-R1-S4_filter_variants_indels.pbs
```

Resources: 1 hugemem CPU, 11 GB mem, ~ 1 minute.

## Apply filter SNPs
Use 'SelectVariants' to keep only the SNPs passing the filters applied in step 3.

Update the PBS directives (project, lstorage) and edit the 'ref', 'round' and 'cohort' variables, then run:

```{bash Apply filter SNPs}
qsub bsv-R1-S5_apply_filter_snps.pbs
```

Resources: 1 hugemem CPU, 19 GB mem, ~ 5 minutes.

## Apply filter indels
Use 'SelectVariants' to keep only the indels passing the filters applied in step 4.

Update the PBS directives (project, lstorage) and edit the 'ref', 'round' and 'cohort' variables, then run:

```{bash Apply filter indels}
qsub bsv-R1-S6_apply_filter_indels.pbs
```

Resources: 1 hugemem CPU, 15 GB mem, ~ 3 minutes.

## BQSR 1a: Make recalibration tables 
Run 'BaseRecalibrator' over the intervals determined in step 0 to make a recalibration table per interval. 

No edits are required for the script `bsv-R1-S7_bqsr_recal_make_input.sh`

Run the following, supplying the base name of your config file on the command line:

```{bash BQSR 1a make input}
bash bsv-R1-S7_bqsr_recal_make_input.sh <cohort>
```

Edit the variables 'ref' and 'cohort' in `bsv-R1-S7_bqsr_recal.sh`. 

Edit PBS directives (project, lstorage) and 'round' varaible in `bsv-R1-S7_bqsr_recal_run_parallel.pbs` then run the following:

```{bash BQSR 1a run}
qsub bsv-R1-S7_bqsr_recal_run_parallel.pbs
```

Resources: 1120 normalbw CPUs, 3.6 TB mem, 23 minutes.

## BQSR 1b: Gather tables

Use 'GatherBQSRReports' to gather the scattered interval tables into one table per sample. 

No edits are required for the scripts `bsv-R1-S8_bqsr_gather.sh` or `bsv-R1-S8_bqsr_gather_make_input.sh`. 

Run the following, supplying the base name of your config file on the command line:

```{bash BQSR 1b make input}
bash bsv-R1-S8_bqsr_gather_make_input.sh <cohort>
```


Edit PBS directives (project, lstorage) and 'round' varaible in `bsv-R1-S8_bqsr_gather_run_parallel.pbs` then run:


```{bash BQSR 1b run}
qsub bsv-R1-S8_bqsr_gather_run_parallel.pbs
```


Resources: 37 CPUs, 33 GB mem, 40 seconds.

## BQSR 1c: Print recalibrated BAMs

Use the gathered recalibration tables to print BAMs with relcaibrated base quality scores. Each sequence in the .dict file can be printed as its own BAM for massive parallelisation, however the subsequent merge step proceeds faster and using far less RAM if the number of BAMs to merge is not in the thousands. Two approaches to minimising this merge burden are described below. Follow the Tas Devils example for species with 'normal' reference sequences ie a small number of large sequences and a few to many much smaller sequences. Follow the de novo method if your reference sequence has many small sequences. 

### For species with large autosomes, such as the Tasmanian Devils:

Future improvements to this pipeline will automate the determination of number of BAMs to print per sample, but for now, this is set in the 'make input' script manually, using the following guidelines:

View the .dict file for your species, and determine the number of intervals where each of the large sequences are run as their own interval, and all of the small sequences are run as one interval. The 'small' sequences are usually the Y (if present), MT and unplaced or alt contigs. This will give you the number of tasks to run per sample, ie tasks=<number of autosomes + X + 1>. 

Once you have determined the value for 'tasks', edit 'tasks' and 'dict' variables in `bsv-R1-S9_bqsr_apply_make_input.sh`, then run:


```{bash BQSR 1c make input}
bash bsv-R1-S9_bqsr_apply_make_input.sh <cohort>
```


For species with very large chromosomes (eg Tas devils) GATK has a strange bug where the '-L unmapped' flag does not work. This is currently under investigation, see https://gatk.broadinstitute.org/hc/en-us/community/posts/360072812491-ApplyBQSR-to-unmapped-reads-for-non-model-organism-does-not-work-with-L-unmapped-flag?page=1#community_comment_360013025951. The `bsv-R1-S9_bqsr_apply.sh` script as it currently stands includes a workaround where the unmapped f12 reads are first extracted, and the apply recal performed in the standalone unmapepd BAMs. This will work for any species, but adds ~ 20 minutes run time per sample. Please contact me if you need help adjusting this for your species. 


Edit PBS directives (project, lstorage) and 'round' varaible in `bsv-R1-S9_bqsr_apply_run_parallel.pbs` then run:


```{bash BQSR 1c run}
qsub bsv-R1-S9_bqsr_apply_run_parallel.pbs
```


Resources: 224 normalbw CPUs, 1.1 TB mem, 85 minutes.

### For species with many small contigs, such as from a de novo genome assembly:


If there is no clear separation between "large sequences" and "small sequences" as expected from a polished genome assembly, the 'split intervals without subdivision' is a good approach. The arbitrary value of 100 is chosen for the number of intervals to make from the genome. If this number is too high for the specified genome, GATK will simply emit fewer intervals. 

Edit the PBS directives (project, lstorage) and 'ref' variable in `bsv-R1-S9_denovo_bqsr_apply_create_intervals.pbs`, then run:

```{bash BQSR 1c de novo prep}
qsub bsv-R1-S9_denovo_bqsr_apply_create_intervals.pbs
```

This will create interval files in the ./Reference directory. There may be 100 as specified, or fewer, this does not matter. The next step will create the inputs file from the intervals files created, also adding the 'unmapped' interval to the list to ensure the f12 unmapped reads are retained in the recalibrated BAM. 

Run the following, providing your config file base name as argument:

```{bash BQSR 1c de novo make input}
bash bsv-R1-S9_denovo_bqsr_apply_make_input.sh <cohort>
```

Edit the 'ref' and 'round' variables in `bsv-R1-S9_denovo_bqsr_apply.sh`, then run:


```{bash BQSR 1c de novo run}
qsub bsv-R1-S9_denovo_bqsr_apply_run_parallel.pbs
```


## BQSR 1d: Merge the recalibrated BAMs

This step merges the multiple interval recalibrated BAMs into one recalibrated BAM per sample. GATK or SAMbamba can be used; SAMbamba is more efficient and (usually) faster but uses many more CPUs and KSUs. For small interval numbers (say < 100) the time saving with SAMbamba is probably negligible so GATK would be fine. For many (thousands) of interval BAMs to merge, SAMbamba will be much faster. Caveat on SAMbamba: every so often, a sample will inexplicably fail to merge with SAMbamba. The options are to merge that sample with GATK, or perform a 'cyclical merge' with SAMbamba, eg merge batches of BAMs and then perform a final merge.

For both merge approaches, we need a sample list for the parallel PBS script. Run the following, providing your config file base name as argument:


```{bash BQSR 1d merge make input}
bash bsv-R1-S10_bqsr_merge_make_input.sh <cohort>
```


### Merge with GATK

Edit the variable 'round' in `bsv-R1-S10_bqsr_merge_GATK_make_bamLists.sh`. Note that this is a draft pipeline, so you will need to 'hash out' some code depending on which method you used to print recalibrated interval BAMs (5.9.1 or 5.9.2). This will be improved later!


Run the following, providing your config file base name as argument:

```{bash BQSR 1d merge make bamlists}
bash bsv-R1-S10_bqsr_merge_GATK_make_bamLists.sh <cohort>
```

This will make a list of BAM files to merge per sample, required for GATK. We could parse these as a string, but list format is more reliable for long lists. 

Edit the variables 'round' and 'ref' in  `bsv-R1-S10_bqsr_merge_GATK.sh`. 

**Important:** if your reference genome has contigs longer than 2^29-1 bp, you need to make sure that this script has `--CREATE_INDEX=false` set in the GATK GatherBamFiles command. Step 11 creates CSI indexes for these BAMs. If your reference genome has contigs shorter than this, you can change false to true: `--CREATE_INDEX=true` and miss step 11, OR leave this setting as 'false' and change the BAM indexing method at step 11 to create BAI indexes. 

Edit the PBS directives (project, lstorage) and 'ref' variable in `bsv-R1-S10_bqsr_merge_GATK_run_parallel.pbs`. Adjust the CPUs and mem: allow 1 hugemem CPU and 32 GB per sample. Then run:

```{bash BQSR 1d run}
qsub bsv-R1-S10_bqsr_merge_GATK_run_parallel.pbs
```

Resources: 37 hugemem CPUs, 767 GB mem, 36 minutes.

### Merge with SAMbamba

You will nede to install and compile sambamba v 0.7.1 from source, and set up your local install to load as a module. 

Edit the variable 'round' in `bsv-R1-S10_bqsr_merge_SAMbamba.sh`.

Edit the PBS directives (project, lstorage), 'round' variable and adjust resources in `bsv-R1-S10_bqsr_merge_SAMbamba_run_parallel.pbs`. For mammalian samples up to ~ 30X coverage, allow 14 normalbw CPUs per task, or 24 normal. For normal, request 4 CB mem per CPU requested, or number of nodes X 191 GB. For normalbw, request 9 GB mem per CPU, or number of nodes X 255 GB (whole nodes only can be requested for Gadi jobs >1 node). Check that the variable 'CPN' is set to 28 for normalbw or 48 for normal. Then run the following:


```{bash BQSR 1d sambamba run}
qsub bsv-R1-S10_bqsr_merge_SAMbamba_run_parallel.pbs
```

Resources: 532 normalbw CPUs, 2.14 TB mem, 32 minutes.


## Create CSI indexes

If your reference genome has contigs longer than 2^29-1 bp, or you have run step 10 with `--CREATE_INDEX=false`, you will need to run this step. If not, proceed to step 12. 

Run the following, providing your config file base name as argument:


```{bash Index make input}
bash bsv-R1-S11_index_make_input.sh <cohort>
```

Edit the variable 'round' in `bsv-R1-S11_index.sh`. If your genome has contigs longer than 2^29-1 bp, ensure that the index command including the '-c' flag is unhashed and that the index command without '-c' is hashed out. If your genome has all contigs less than this size, hash out the command containing '-c' and unhash the command without '-c'. I will make this cleaner in future versions :-) Ie automate this from the .dict file. 


Edit the PBS directives (project, lstorage) and adjust resources in `bsv-R1-S11_index_run_parallel.pbs`. Allow 24 normal CPUs per sample. Then run:

```{bash Index run}
qsub bsv-R1-S11_index_run_parallel.pbs
```

Resources: 912 normal CPUs, 1.7 TB mem, 3 minutes.
 

## BQSR 2a: create "after" recal tables

Create BQSR recalibration tables on the recalibrated BAMs. These tables will be used to generate plots to assess the effectiveness of the recalibration. 

Edit the variables 'round', 'cohort' and 'ref' in `bsv-R1-S12_bqsr_recal.sh`. 

There is no need to make a .inputs file, as the same file can be used as BQSR recal step 7.

Edit the PBS directives (project, lstorage) in `bsv-R1-S12_bqsr_recal_run_parallel.pbs` then run:

```{bash BQSR 2a}
qsub bsv-R1-S12_bqsr_recal_run_parallel.pbs
```

Resources: 1120 normalbw CPUs, 4.4 TB mem, 26 minutes.


## BQSR 2b: gather the "after" recal tables

Use 'GatherBQSRReports' to gather the scattered interval tables into one table per sample. 

Edit the variable 'round' in `bsv-R1-S13_bqsr_gather.sh`. 

There is no need to make a .inputs file, as the same file can be used as BQSR recal step 8.

Edit PBS directives (project, lstorage) in `bsv-R1-S13_bqsr_gather_run_parallel.pbs` then run:


```{bash BQSR 2b}
qsub bsv-R1-S13_bqsr_gather_run_parallel.pbs
```

Resources: 19 CPUs, 28 GB mem, 1 minute.

## Create and analyse covariate plots

Use AnalyzeCovariates to plot the base quality scores before and after recalibration, to assess the efficacy of BQSR. 

Edit the variable 'round' in `bsv-R1-S14_anacov.sh`.

Run the following, providing your config file base name as argument:

```{bash anacov make input}
bash bsv-R1-S14_anacov_make_input.sh <cohort>
```

Edit PBS directives (project, lstorage) in `bsv-R1-S14_anacov_run_parallel.pbs`, and adjust resources. This step is very fast so <number of samples>/2 is the maximum CPUs that should be requested. Then run:

```{bash anacov run}
qsub bsv-R1-S14_anacov_run_parallel.pbs
```

Resources: 19 CPUs, 15 GB mem, 1 minute. 

Open the PDF files for a graphical comparison of the before and after base quality scores. This site can be helpful (although your plots will not look exactly like this): https://gatk.broadinstitute.org/hc/en-us/articles/360035890531-Base-Quality-Score-Recalibration-BQSR- . I have not found a way to assess a large sample cohort of AnalyseCovariates output programatically (looking for the anacov version of multiqc for fastqc!) so if you write or come by one, please let me know :-) I recomend checking a handful of samples with some meaningful difference, eg the smallest and the largest, a representative from each run, each lane, different instruments, etc. 

In general, you want to see your blue data points ("after" recalibration quality scores) following a straight line or normal distribution, depending on the plot. 

## Haplotye caller 

We will now call germline short variants again, this time using the reclibrated BAM output from step 10 as input instead of the "dedup_sort" BAMs generated in Fastq-to-BAM pipeline. 

The number of tasks equals 3200 X N. Task walltime is influnced by interval and by sample size, so the inputs list is ordered by both interval walltime and by sample size to try and increase CPU efficiency. To do this, the "3200_intervals_taskTimeSorted.list" produced during the initial round of variant calling for Germline-ShortV pipeline is used, as is the input BAM sizes. 

Check that the path to this time sorted list is correct in `bsv-R1-S15_hc_make_input.sh`, and that the syntax for collecting samples by size is correct for this dataset (eg, if there is a '.' character used in the sample IDs, this syntax will need to be adjusted). Also edit the 'round' variable, then run: 


```{bash HC make input}
bash bsv-R1-S15_hc_make_input.sh
```

Edit the 'round' and 'ref' variables in `bsv-R1-S15_hc.sh`. 

Edit PBS directives (project, lstorage) and 'round' varaible in `bsv-R1-S15_hc_run_parallel.pbs` then run:


```{bash HC run}
qsub bsv-R1-S15_hc_run_parallel.pbs
```

Resources: 7200 CPUs, 14 TB mem, 95 minutes. 

## Haplotye caller - missing/failed intervals

This step checks and resubmits tasks with missing or empty VCF or VCF index files. In the future, this step will be combined with step 17. 

Edit the 'round' variable in `bsv-R1-S16_hc_missing_mke_input.sh` then run the following, providing your config file base name as argument:

```{bash HC missing make input}
bash bsv-R1-S16_hc_missing_make_input.sh <cohort>
```

If this script presents the message:

"There are <N> missing/empty vcf files. Please run bsv-R1-S16_hc_missing_run_parallel.pbs with ./Inputs/hc_missing.inputs"

then continue with the following steps. If not, continue to step 18. 

Edit the 'round' and 'ref' variables in `bsv-R1-S16_hc_missing.sh`. 

Edit PBS directives (project, lstorage) and 'round' varaible in `bsv-R1-S16_hc_missing_run_parallel.pbs`. Adjust the resources depending on the number of tasks to run, allowing 2 CPU and 1 hour per task, then run:


```{bash HC missing run}
qsub bsv-R1-S16_hc_missing_run_parallel.pbs
```

Resources: 4 CPUs, 4.3 GB mem, 1 minute. 


## Haplotye caller - check logs

Perform an in-depth check on each HaplotypeCaller task by assessing the run time, memory used, and the presence of errors or java exceptions in the GATK logs. In addition to this, please (as always) check that the exit status for the parent HC job and each HC sub-task is zero. 

**Caveat:** this set of scripts has been heavily modified since last use and not tested in depth. Please let me know if you find any errors!

Run the following, providing your config file base name as argument:

```{bash HC check make input}
bash bsv-R1-S17_hc_checklogs_make_input.sh <cohort>
```

Edit PBS directives (project, lstorage) and 'round' varaible in `bsv-R1-S17_hc_checklogs_run_parallel.pbs`. Adjust the resources depending on the number of samples, allowing 1 CPU and 10 minutes per task (single test sample took 2.5 minutes on the login node), then run:


```{bash HC check run}
qsub bsv-R1-S17_hc_checklogs_run_parallel.pbs
```

At completion, the log file ./Logs/bsv-R1-S17.o should contain a message reporting whether or not any failed tasks were detected, and if so, list the .inputs file containing the tasks to rerun.


## Gather GVCFs 

## Genomics db import

## Genomics db import - missing/failed intervals

## Genotype GVCFs

## Genotype GVCFs - missing/failed intervals

## Final gather and sort VCF

## VCF metrics and evaluation


























