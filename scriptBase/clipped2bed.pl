use strict;
use warnings;
 
my $filename = $ARGV[0];
open(my $fh, '<:encoding(UTF-8)', $filename) or die "Could not open file '$filename' $!";
 
while (my $row = <$fh>) {
  chomp $row;
  my @clipLine = split /\t/, $row;
  #next if $clipLine[4] < 500;
  my $stLoc=($clipLine[2]-0); my $edLoc=($clipLine[2]+0);
  print "$clipLine[1]\t$stLoc\t$edLoc\n";
}