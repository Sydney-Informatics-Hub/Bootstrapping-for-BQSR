#!/usr/bin/env perl

#########################################################
# 
# Platform: NCI Gadi HPC
# Description: chck time and memory usage and errors in GATK logs to uncover failed tasks from step 16
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

use strict;
use warnings;

my $round = 1;  

my $sample= $ARGV[0]; 

my $logdir = "./GATK_logs/HC_round$round\/$sample"; 
my @files = <$logdir/*.oe>;

my $out = "$logdir\/$sample\_task_duration.txt"; 
open (OUT, ">$out") || die "$! write $out\n"; 
print OUT "#Interval\tDuration\tMemory\n";


my @errors = (); 

# Check GATK HC logs:
foreach my $file (@files){
	$file =~ m/(\d+).oe/;
	my $interval = $1;

        if(-s $file){
                my $timelog=`grep "HaplotypeCaller done. Elapsed time:" $file`;
                $timelog=~ m/([0-9]+\.[0-9]+) minutes\.\n$/;
                my $duration=$1;
                my $memory=`grep "Runtime.totalMemory" $file`;
                $memory=~ m/([0-9]+)\n$/;
                my $bytes=$1;
                if ($memory && $bytes) {
                        my $gigabytes = $bytes/1000000000;
                        print OUT "$interval\t$duration\t$gigabytes\n";
                }
                else {
                        print OUT "$interval\tNA\tNA\n";
			push @errors, $interval;  
                }
        }
        else {
                print OUT "$interval\tNA\tNA\n";
		push @errors, $interval;
        }
} close OUT; 

# Check for error capture reports (error and Exception in GATK log): 
my $errordir = "./Error_capture/HC_round${round}/$sample"; 
my @errfiles = <$errordir/*.err>;

foreach my $err (@errfiles) {
	$err =~ m/(\d+).err/;
	my $interval = $1; 
	push @errors, $interval;	
}

my @unique = do { my %seen; grep { !$seen{$_}++ } @errors };
my $count = @unique; 

if ($count) {
	my $errorlist = "$logdir\/$sample\_errors.txt"; 
	my $scatterdir = './Reference/HC_intervals';
	open (OUT, ">$errorlist") || die "$! write $errorlist\n"; 
	foreach my $e (@unique) {
		print OUT "$sample\,$scatterdir\/$e\-scattered.interval_list\n";  #formatted for HC inputs	
	} close OUT;  
}



