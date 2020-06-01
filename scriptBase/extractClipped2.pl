#!/usr/bin/perl
use strict;
use warnings;

#USAGE: perl $perlScript/extractClipped2.pl $dir/out_$fname.sam $dir

my $softFile = 'softClipped.txt';
my $hardFile = 'hardClipped.txt';
my $dirLoc=$ARGV[1];

open(my $sf, '>', "$dirLoc/$softFile") or die "Could not open file '$dirLoc/$softFile' $!";
open(my $hf, '>', "$dirLoc/$hardFile") or die "Could not open file '$dirLoc/$hardFile' $!";

open SAM,"$ARGV[0]";

        while(<SAM>){
        next if(/^(\@)/);  ## skipping the header lines (if you used -h in the samools command)
        s/\n//;  s/\r//;  ## removing new line
        my @sam = split(/\t+/);  ## splitting SAM line into array
	#print "$sam[5] \t $sam[3]\n"; #CIGAR value
	#check if CIGAR contain H or S
	#soft-clipped: bases in 5' and 3' of the read are NOT part of the alignment.
	#hard-clipped: bases in 5' and 3' of the read are NOT part of the alignment AND those bases have been removed 
	#Hard masked bases do not appear in the SEQ string, soft masked bases do
	#hard-clipping is applied when the clipped bases align elsewhere in the reference genome, i.e chimeric reads
	
	my $hardClipped="H";
	my $softClipped="S";
	my $string=$sam[5];

	if (index($string, $hardClipped) != -1) {
		#split with char
		my @clipSizeH = split /[A-Z]/, $sam[5];
		my $stValH = $sam[3]+$clipSizeH[0];
		my $edValH = $sam[3]+$clipSizeH[-1];
		next if (($clipSizeH[0] < 5000) && ($clipSizeH[-1] < 5000)); #Ignore if both end of the scipped reads are less than 500bp (independtly)
		print $hf "$sam[0]\t$sam[2]\t$sam[3]\t$sam[5]\t$clipSizeH[0]\t$clipSizeH[-1]\n";
    		#print $hf "'$sam[5]' matches the pattern\n";   
	}
	elsif (index($string, $softClipped) != -1) {
		my @clipSizeS = split /[A-Z]/, $sam[5]; 
		my $stValS = $sam[3]+$clipSizeS[0];
		my $edValS = $sam[3]+$clipSizeS[-1];
		next if (($clipSizeS[0] < 5000) && ($clipSizeS[-1] < 5000));
		print $sf "$sam[0]\t$sam[2]\t$sam[3]\t$sam[5]\t$clipSizeS[0]\t$clipSizeS[-1]\n";
    		#print $sf "'$sam[5]' matches the pattern\n";   
	}
       }
	close $hf; close $sf;
