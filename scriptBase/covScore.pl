#!/usr/bin/perl
use strict;
use warnings;

open COV, "$ARGV[0]";
my %covScore;

#Load the covezrage data
while(<COV>){
my @val = split '\t', $_; 
$covScore{$val[0]}{$val[1]}= $val[2];
}
close COV;
#foreach my $name (sort keys %grades) {
#    foreach my $subject (keys %{ $grades{$name} }) {
#        print "$name, $subject: $grades{$name}{$subject}\n";
#    }
#}

open CLIP, "$ARGV[1]";
while(<CLIP>){
chomp;
my @clipVal = split '\t', $_; 
my $newLoc=$clipVal[1]+1; #Due to ZERO based
my $score= $covScore{$clipVal[0]}{$newLoc};
#my $scoreVal= eval {($clipVal[3]/$score)};
my $finalCovScore=0; # If coverage in bin size is ZERO - the final score is ZERO
if($score != 0) { $finalCovScore=sigmoid ($clipVal[3]/$score); }
print "$_\t$finalCovScore\n";
}

sub sigmoid {
   my ($h) = @_;
   return 1.0 / ( 1.0 + exp( -2.0 * $h ) );
}
