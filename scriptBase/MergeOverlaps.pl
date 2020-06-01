#!/usr/bin/env perl
# -*- coding: utf-8 -*-

use strict;
use warnings;
use Data::Dumper;

#USAGE: perl mergeOverlaps.pl aaaa_REAL 1000
#1000 here is to extend the coordinates 1000x both side

my %ranges;
open COR, "$ARGV[0]";

#Remenmer to sort the coordinates by chr/st/ed
#iterate line by line. 
while (<COR>) {
   chomp;
   #split by line
   my ( $name, $startR, $endR ) = split;
   #set a variable to see if it's within an existing range. 
   my $start_range = $startR - $ARGV[1];
   my $end_range = $endR + $ARGV[1];
   my $in_range = 0;
   #iterate all the existing ones. 
   foreach my $range ( @{ $ranges{$name} } ) {

      #merge if start or end is 'within' this range. 
      if (
         ( $start_range >= $range->{start} and $start_range <= $range->{end} )

         or

         ( $end_range >= $range->{start} and $end_range <= $range->{end} )
        )
      {


         ## then the start or end is within the existing range, so add to it:
         if ( $end_range > $range->{end} ) {
            $range->{end} = $end_range;
         }
         if ( $start_range < $range->{start} ) {
            $range->{start} = $start_range;
         }
         $in_range++;
      }

   }
   #didn't find any matches, so create a new range identity. 
   if ( not $in_range ) {
      push @{ $ranges{$name} }, { start => $start_range, end => $end_range };
   }
}

#print Dumper \%ranges;

#iterate by sample
foreach my $sample ( sort keys %ranges ) {
   #iterate by range (sort by lowest start)
   foreach
     my $range ( sort { $a->{start} <=> $b->{start} } @{ $ranges{$sample} } )
   {
      print join "\t", $sample, $range->{start}+$ARGV[1], $range->{end}-$ARGV[1], "\n";
   }
}
