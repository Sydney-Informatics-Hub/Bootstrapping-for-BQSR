#!/usr/bin/env perl

use strict;
use warnings;

# Collect time and memory from logs. If these are unavailable, there was
# an error.
# Check the error capture directory, which will list any intervals where
# grep -i error or grep Exception yielded a result

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



