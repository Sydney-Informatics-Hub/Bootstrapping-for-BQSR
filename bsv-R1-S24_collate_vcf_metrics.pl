#/usr/bin/env perl

use warnings;
use strict; 


my $round = $ARGV[0]; 
my $cohort = $ARGV[1]; 
chomp ($round, $cohort); 
my $config = "$cohort\.config"; 

# Collect the data
my $summary_unrecal = "./VCF_metrics/Round$round\/$cohort\_unrecalibrated_round$round\.variant_calling_summary_metrics";
my $summary_recal = "./VCF_metrics/Round$round\/$cohort\_recalibrated_round$round\.variant_calling_summary_metrics";
my $detail_unrecal = "./VCF_metrics/Round$round\/$cohort\_unrecalibrated_round$round\.variant_calling_detail_metrics";
my $detail_recal = "./VCF_metrics/Round$round\/$cohort\_recalibrated_round$round\.variant_calling_detail_metrics";

my $summary = "./VCF_metrics/Round$round\/$cohort\_collated_metrics_summary.txt";
my $sample_summary = "./VCF_metrics/Round$round\/$cohort\_collated_sample_metrics_summary.txt";

open (OUT, ">$summary") || die "$! write $summary\n"; 

my $summary_header = `grep -A 1 "## METRICS CLASS" $summary_recal | tail -1`; 
my $summary_recal_data = `grep -A 2 "## METRICS CLASS" $summary_recal | tail -1`;
my $summary_unrecal_data = `grep -A 2 "## METRICS CLASS" $summary_unrecal | tail -1`;
my $detail_header = `grep -A 1 "## METRICS CLASS" $detail_recal | tail -1`;

chomp ($summary_header, $summary_recal_data, $summary_unrecal_data, $detail_header); 

my @summary_header = split(' ', $summary_header); 
my @summary_recal_data = split(' ', $summary_recal_data);
my @summary_unrecal_data = split(' ', $summary_unrecal_data);
my @detail_header = split(' ', $detail_header);

# Collate the summary files
my $col_num = @summary_header; 
print OUT "#CATEGORY\tRECAL\tUNRECAL\tDIFFERENCE\n"; 
for ( my $i = 0; $i < $col_num; $i++ ) {
	my $diff = sprintf("%.2f", ($summary_recal_data[$i] -  $summary_unrecal_data[$i]));  
	print OUT "$summary_header[$i]\t$summary_recal_data[$i]\t$summary_unrecal_data[$i]\t$diff\n";  	
} close OUT;  

# Collate the details files
my $samplehash= {}; 
open (R, $detail_recal) || die "$! $detail_recal\n"; 
while (my $line =  <R>) {
	chomp $line;
	if ( ($line!~m/^\#/) && ($line!~m/^\SAMPLE_ALIAS/) && ($line=~m/^\S/) ) { 
		my ($sample, @cols) = split(' ', $line);  
		$samplehash->{$sample}->{recal_data} = $line; 				
	}
} close R;  

open (U, $detail_unrecal) || die "$! $detail_unrecal\n"; 
while (my $line =  <U>) {
	chomp $line;
	if ( ($line!~m/^\#/) && ($line!~m/^\SAMPLE_ALIAS/) && ($line=~m/^\S/) ) {		
		my ($sample, @cols) = split(' ', $line); 
		$samplehash->{$sample}->{unrecal_data} = $line; 				
	}
} close U; 

open (OUT, ">$sample_summary") || die "$! write $sample_summary\n";
print OUT "#CATEGORY";  

my @samples_in_order = split(' ', `awk 'NR>1 {print \$2}' $config`); 
 
foreach my $sample (@samples_in_order) {
	print OUT "\t$sample\_recal\t$sample\_unrecal\t$sample\_diff"; 
} print OUT "\n"; 

$col_num = @detail_header;
for ( my $i = 1; $i < $col_num; $i++ ) { #start at 1 to miss 'SAMPLE_ALIAS' header
	print OUT "$detail_header[$i]"; 
	foreach my $sample (@samples_in_order) {
		my $recal_data = $samplehash->{$sample}->{recal_data};
		my @recal_cols = split(' ', $recal_data); 
		my $recal_data_point = $recal_cols[$i]; 
		my $unrecal_data = $samplehash->{$sample}->{unrecal_data};
		my @unrecal_cols = split(' ', $unrecal_data); 
		my $unrecal_data_point = $unrecal_cols[$i];	
		my $diff = sprintf("%.2f", ($recal_data_point - $unrecal_data_point));	
		print OUT "\t$recal_data_point\t$unrecal_data_point\t$diff";
	} print OUT "\n"; 
} close OUT; 
	



