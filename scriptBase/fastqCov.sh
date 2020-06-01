#!/bin/bash
fastq1=$1  #fastq input 1 read forward
fastq2=$2  #fastq input 2 read reverse
fasta=$3 #fasta input -- we provide reference fasta here 

#To calculate average read length
 #calculate read length for fastq file 1
readlength1=$(awk 'NR % 4 == 2 { s += length($1); t++} END {print s/t}' $fastq1)
 #calculate read length for fastq file 2
readlength2=$(awk 'NR % 4 == 2 { s += length($1); t++} END {print s/t}' $fastq2)
 #calculate total read length
totalreadlength=$(echo "$readlength1+$readlength2"|bc)
 #calculate average read length by parsing into bc command - which truncates the decimal numbers by default in multiplication/division
averagereadlength=$(echo "$totalreadlength/2"|bc)

#To calculate readcount
 #read count in file 1
readcount1=$(cat $fastq1| echo $((`wc -l`/4)))
 #read count in file 2
readcount2=$(cat $fastq2| echo $((`wc -l`/4)))
 #total read count of file 1 and file 2
totalreadcount=$(echo "$readcount1+$readcount2"|bc)
 #average read count - parsed into bc command to be rounded
averagereadcount=$(echo "$totalreadcount/2"|bc)

#To calculate genome size
awk '!/^>/ { printf "%s", $0; n = "\n" } /^>/ { print n $0; n = "" } END { printf "%s", n }' $fasta > "$fasta"-single
cat "$fasta"-single|awk 'NR%2==0'| awk '{print length($1)}' > "$fasta"-oneline
genomesize=$(awk '{ sum += $1 } END { print sum }' "$fasta"-oneline)

#To calculate actual sequencing depth/coverage
#sequencing depth= LN/G =average read length * average reads / genome size
LN=$(echo "$averagereadcount*$averagereadlength*2")
G=$genomesize
coverage=$(echo "$LN/$G"|bc)

#To print the tab-delimited table on standard output
echo -n -e "\taverage_read_length\t"
echo -n -e "reads\t"
echo -n -e "genome\t"
echo -e "coverage"
echo -n -e "$fasta\t"
echo -n -e "$averagereadlength\t"
echo -n -e "$averagereadcount\t"
echo -n -e "$genomesize\t"
echo -e "$coverage"

#To remove intermediary files (due to the size, these files cannot be parsed into variables)
rm "$fasta"-single;
rm "$fasta"-oneline;

