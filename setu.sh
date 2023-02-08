#!/bin/bash

set -e 
set -o pipefail

echo -e "\nAutomated pipeline to assemble the SARS-CoV-2 genome in one go!"
cat ./scriptBase/logo.txt

# © Jitendra Narayan 
# Cite: Jitendra et al, setu: a bridge to corona virus genome structure, 2020
# Contact: jnarayan81@gmail.com

#USAGE: time ./setu.sh -k yes -d /home/jit/Downloads/setu -m pe -t 1 -r /home/jit/Downloads/SRR11140750_1.fastq,/home/jit/Downloads/SRR11140750_2.fastq,/home/jit/Downloads/SRR11140751/SRR11140751.fastq -o see2

#To test the result
#minimap2 -a GWHABKO00000000.genome.fasta spade_scaffolds.fasta  > test.sam
#samtools view -Sb test.sam | samtools sort -m 2G -@ 1 -o out.sorted.bam - && samtools index -@ 1 out.sorted.bam

#Location of scripts
perlScript=./scriptBase

Red=`tput setaf 1`
Green=`tput setaf 2`
Reset=`tput sgr0`

# location to getopts.sh file
source ./scriptBase/getopt.sh
#source scriptBase/*

USAGE="-k KEEP -m MODE -r READS -t THREAD -o OUTDIR -f FORCE [-a START_DATE_TIME ]" #-s SCAFFOLD
parse_options "${USAGE}" ${@}

echo "${Green}--:LOCATIONS and FLAGS:--${Reset}"
echo "${Green}MODE name provided:${Reset} ${MODE}"
echo "${Green}THREAD used:${Reset} ${THREAD}"
echo "${Green}OUTDIR used:${Reset} ${OUTDIR}"
echo "${Green}READS location :${Reset} ${READS}"
echo "${Green}FORCE flag :${Reset} ${FORCE}"
#echo "${Green}SCAFFOLD flag :${Reset} ${SCAFFOLD}"

#Parameters accepted -- write absolute path of the BAM file
mode=${MODE}
core=${THREAD}
reads=${READS}
out=${OUTDIR}
force=${FORCE}
#scaffold=${SCAFFOLD}

#Set time
start_time="$(date +%s)"

#Lower case and upper case in bash var1=TesT; var2=tEst; echo ${var1,,} ${var2,,}; echo ${var1^^} ${var2^^}
#shopt -s nocasematch

if [[ ${mode,,} == pe ]]
then
   #All the paired end subs
   if [[ $force == 'on' ]] ; then rm -rf mkdir $out; mkdir $out; else mkdir $out ; fi
   source ./scriptBase/pe.sh
   #Move all to OUTFILE
   mv spades trimlog ragout final_output assembly_stats $out
   mv *.{bam,sam,fastq,stats,fq,pdf,txt,cov} $out
#PE ends here

elif [[ ${mode,,} == long ]]
then
#  echo "You opted for nanopore(ONT) reads"
#  if [[ $force == 'on' ]] ; then rm -rf mkdir $out; mkdir $out; else mkdir $out ; fi
  echo "Work on long reads based assembly is ongoing"
#  source ./scriptBase/long.sh
  #Move all to OUTFILE
#  mv ShastaRun ragout_long $out
#  mv *.{bam,sam,out,bai,fastq,stats,txt,paf,fai,fasta,fq,cov,pdf,gfa,fa,png,} $out

#long end here
#elif [[ ${mode,,} == hybrid ]]
#then
#   echo "You opted for hybrid assembly approach"
#   if [[ $force == 'on' ]] ; then rm -rf mkdir $out; mkdir $out; else mkdir $out ; fi
  echo "Work on hybrid reads assembly is ongoing"
#   source ./scriptBase/hybrid.sh
   #Move all to OUTFILE
#  mv ASM_CORONA_HYBRID ragout_spades logfile finished_Assembly $out
#   mv *.{bam,sam,out,bai,fastq,stats,txt,paf,fai,fasta,fq,cov,pdf,h5} $out

#hybrid ends here
else
  echo "Did you forgot to provide the mode info"
fi

stop_time="$(expr "$(date +%s)" - $start_time)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Setu completed successfully!"
printf "Total runtime: %.0f hours " "$(printf "$(expr $stop_time / 3600)")"
printf "%.0f minutes " "$(printf "$(expr $stop_time / 60 % 60)")"
printf "%.0f seconds\n" "$(printf "$(expr $stop_time % 60)")"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
