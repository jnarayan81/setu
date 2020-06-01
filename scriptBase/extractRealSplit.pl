#!/usr/bin/perl
use strict;
use warnings;

#USAGE perl extractRealSplit.pl pilonCor_round1.fasta.fai final.all.clip 1000000 10 > aaaa

open LEN, "$ARGV[0]";
my %seqLen;
my $lenFilter = $ARGV[2];
my $clipCount = $ARGV[3];
#Load the length data
while(<LEN>){
my @val = split '\t', $_; 
$seqLen{$val[0]}= $val[1];
}
close LEN;

#Now reads the final clipped data
open CLIP, "$ARGV[1]";
while(<CLIP>){
chomp;
my @clipVal = split '\t', $_;
my $size = $seqLen{$clipVal[0]};

if ($size <= $lenFilter*2) { print "$_\tSMALL\n"; next;} #Next if less then twice the size of the threahold
if ($clipVal[3] <= $clipCount) { print "$_\tLESSCLIP\n"; next;} #If clipped reads are less than user provided threshold

#Create the range
my $fromAHead = 0;
my $toAHead = $lenFilter;
my $fromATail = $size-$lenFilter;
my $toATail = $size;

#Check overlaps
my @common_range_Head = get_common_range($fromAHead, $toAHead, $clipVal[1], $clipVal[2]);
my @common_range_Tail = get_common_range($fromATail, $toATail, $clipVal[1], $clipVal[2]);

if((!@common_range_Head) && (!@common_range_Tail)){ print "$_\tREAL\n"; } else {  print "$_\tchrEND\n";}
}


=pod
my $fromA = 12;
my $toA = 15;
my $fromB = 14;
my $toB = 35;
=cut

#my @common_range = get_common_range($fromA, $toA, $fromB, $toB);
#my $common_range = $common_range[0]."-".$common_range[-1];


#It will print the range common between two ranges.
#Start should be smaller than end ... otherwise no overlaps ERROR !!
sub get_common_range {
  my @A = $_[0]..$_[1];
  my %B = map {$_ => 1} $_[2]..$_[3];
  my @common = ();

  foreach my $i (@A) {
    if (defined $B{$i}) {
      push (@common, $i);
    } 
  }
  return sort {$a <=> $b} @common;
}
