#!/usr/bin/env perl

#########################################################
# 
# Platform: NCI Gadi HPC
# Description: Check genotypegvcfs log files for errors
# Can be run alone (provide logdir path and cohort name on 
# command line - order matters) or run with bsv-R2-S22_gnotypegvcfs_missing_make_input.sh
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

my $logdir=$ARGV[0];
my $cohort=$ARGV[1];

my $out="$logdir/$cohort\_interval_duration_memory.txt";
`rm -rf $out`;

open(OUT,'>',"$out") or die "Could not write to $out: $!\n";

print OUT "#Interval\tDuration\tMemory_Gb\n";

for (my $i=0000; $i <3200; $i++) {
	my $interval=sprintf("%04d",$i);
	my $file="$logdir\/$interval\.oe";
	if (-s $file) {
		# Check for errors first, because errors will still print done and mem
		my $errors =`grep -i ERROR $file`;
		chomp $errors;
		my $exceptions = `grep Exception $file`;
		chomp $exceptions; 
		if ( ($errors) || ($exceptions) ){
			#print "Errors found in $file! You may want to check these\n";
			print OUT "$interval\tERR\tERR\n";
		}
		else {
			my $timelog=`grep "GenotypeGVCFs done. Elapsed time:" $file`;
			$timelog=~ m/([0-9]+\.[0-9]+) minutes\.\n$/;
			my $duration=$1;
			my $memory=`grep "Runtime.totalMemory" $file`;
			$memory=~ m/([0-9]+)\n$/;
			my $bytes=$1;
			if($memory && $bytes){
				my $gigabytes=$bytes/1000000000;
				print OUT "$interval\t$duration\t$gigabytes\n";
			}
			else {
				print OUT "$interval\tNA\tNA\n";
			}
		}
	}
	else {
		print OUT "$interval\tNA\tNA\n";
	}
} close OUT; 
exit;
