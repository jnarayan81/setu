#!/usr/bin/perl
 
use strict;
use warnings;
 
use Bio::DB::Sam;
#use Data::Dumper;
 
my $usage = "Usage $0 <infile.bam>\n";
my $infile = shift or die $usage;
 
my $sam = Bio::DB::Sam->new(-bam  => $infile);
 
my %error_profile = ();
 
#store all the targets which should be all assembled chromosomes
my @targets = $sam->seq_ids;
 
#@targets = 'chrM'; #comment out this line if you are game to test it on all alignments
my $total_tag = '0';
 
#iterate through each target individually, since each target is stored in memory
foreach my $target (@targets){
   warn "$target\n";
   my @alignments = $sam->get_features_by_location(-seq_id => $target);
 
   for my $a (@alignments) {
      ++$total_tag;
 
      #tag id
      my $id  = $a->name;
 
      #alignment information in the reference sequence
      #my $seqid  = $a->seq_id;
      #my $start  = $a->start;
      #my $end    = $a->end;
      #strand is stored as -1 or 1
      my $strand = $a->strand;
      $strand = '+' if $strand =~ /^1$/;
      $strand = '-' if $strand =~ /^-1$/;
      my $cigar  = $a->cigar_str;
      my $md_tag = $a->get_tag_values('MD');
      my $nm_tag = $a->get_tag_values('NM');
 
      die "$id MD tag not defined on line $." if ($md_tag =~ /^$/);
      die "$id NM tag not defined on line $." if ($nm_tag =~ /^$/);
 
      #alignment information in the query sequence
      #my $query_start = $a->query->start;
      #my $query_end   = $a->query->end;
      my $ref_dna   = $a->dna;        # reference sequence bases
      my $query_dna = $a->query->dna; # query sequence bases
      my @scores    = $a->qscore;     # per-base quality scores
      my $match_qual= $a->qual;       # quality of the match
 
      #store reference and query into separate variable for manipulation later
      my $reference = $ref_dna;
      my $query = $query_dna;
 
      #from the CIGAR string, fill in the insertions and deletions
      my $position = '0';
      while ($cigar !~ /^$/){
         if ($cigar =~ /^([0-9]+[MIDS])/){
            my $cigar_part = $1;
            if ($cigar_part =~ /(\d+)M/){
               $position += $1;
            } elsif ($cigar_part =~ /(\d+)I/){
               my $insertion = '-' x $1;
               substr($reference,$position,0,$insertion);
               $position += $1;
            } elsif ($cigar_part =~ /(\d+)D/){
               my $insertion = '-' x $1;
               substr($query,$position,0,$insertion);
               $position += $1;
            } elsif ($cigar_part =~ /(\d+)S/){
               die "Not ready for this!\n";
               #my $insertion = 'x' x $1;
               #substr($new_ref,$position,0,$insertion);
               #$position += $1;
            }
            $cigar =~ s/$cigar_part//;
         } else {
            die "Unexpected cigar: $id $cigar\n";
         }
      }
 
      #in the bam files I process, the original tags are reverse complemented
      #re-reverse complement to see the original tag
      if ($strand eq '-'){
         $query = rev_com($query);
         $reference = rev_com($reference);
      }
 
      my $ed = '0';
      for (my $i =0; $i < length($reference); ++$i){
         my $q = substr($query,$i,1);
         my $r = substr($reference,$i,1);
         if ($q ne $r){
            ++$ed;
            #annotated as a deletion into the reference sequence
            if ($q eq '-'){
               if (exists $error_profile{$i}{'deletion'}){
                  $error_profile{$i}{'deletion'}++;
               } else {
                  $error_profile{$i}{'deletion'} = '1';
               }
            }
            #annotated as an insertion into the reference sequence
            elsif ($r eq '-'){
               if (exists $error_profile{$i}{'insertion'}){
                  $error_profile{$i}{'insertion'}++;
               } else {
                  $error_profile{$i}{'insertion'} = '1';
               }
            }
            #mismatch
            else {
               if ($q eq 'A'){
                  if (exists $error_profile{$i}{$q}){
                     $error_profile{$i}{$q}++;
                  } else {
                     $error_profile{$i}{$q} = '1';
                  }
               }
               elsif ($q eq 'C'){
                  if (exists $error_profile{$i}{$q}){
                     $error_profile{$i}{$q}++;
                  } else {
                     $error_profile{$i}{$q} = '1';
                  }
               }
               elsif ($q eq 'G'){
                  if (exists $error_profile{$i}{$q}){
                     $error_profile{$i}{$q}++;
                  } else {
                     $error_profile{$i}{$q} = '1';
                  }
               }
               elsif ($q eq 'T'){
                  if (exists $error_profile{$i}{$q}){
                     $error_profile{$i}{$q}++;
                  } else {
                     $error_profile{$i}{$q} = '1';
                  }
               }
               elsif ($q eq 'N'){
                  if (exists $error_profile{$i}{$q}){
                     $error_profile{$i}{$q}++;
                  } else {
                     $error_profile{$i}{$q} = '1';
                  }
               }
               else {
                  die "That was unexpected q = $q que = $query ref = $reference\n";
               }
            }
         }
      }
      #double check
      die "Error in calculating edit distance nm: $nm_tag ed: $ed\n" if $ed ne $nm_tag;
 
      #print "$id $strand $match_qual $nm_tag $md_tag\n";
      #print "Que: $query\nRef: $reference\n\n";
 
   }
}
 
foreach my $base (sort {$a <=> $b} keys %error_profile){
   print "$base\n";
   foreach my $type (keys %{$error_profile{$base}}){
      print "\t$type\t$error_profile{$base}{$type}\n";
   }
}
 
print "Total tag = $total_tag\n";
 
exit(0);
 
sub rev_com {
   my ($seq) = @_;
   $seq = reverse($seq);
   $seq =~ tr/ACGT/TGCA/;
   return($seq);
}
 
__END