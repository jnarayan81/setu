#!/bin/bash

# Jitendra et al Hybrid CoViD genome assembler pipeline 
# TODO Add clipped plot !!

#time ./setu.sh -k yes -m hybrid -t 1 -r /home/jit/Downloads/setu/sampleDATA/G1/SRR11140750_1.fastq,/home/jit/Downloads/setu/sampleDATA/G1/SRR11140750_2.fastq,/home/jit/Downloads/SRR11140751/SRR11140751.fastq,ont -f on -o see_hybrid



IFS=, VER=(${reads##,-})
  forR1=${VER[0]}
  revR2=${VER[1]}
  longR=${VER[2]}
  longN=${VER[3]}
  echo $forR1 $revR2 $longR $longN

  if [ -z "$longR" ]
  then
      echo " ${Red} $longR is NULL, please provide long reads ${Reset}"
      kill %%
  elif [ -z "$longN" ]
  then
      echo " ${Red} $longN is NULL, please provide read name: ont or pacbio ${Reset}"
      kill %%
  else
      echo " $longR used for hybrid assembly"
  fi

echo "Checking the raw coverage"
  source ./scriptBase/fastqCov.sh $forR1 $revR2 ./scriptBase/refGenome/corona.fa > rawCov.stats

echo "Trimming the reads"
  trimmomatic PE -threads 1 -trimlog logfile $forR1 $revR2 sequence_PR1_trimmed.fq sequence_UR1_trimmed.fq sequence_PR2_trimmed.fq sequence_UR2_trimmed.fq LEADING:3 TRAILING:3 MINLEN:36 SLIDINGWINDOW:4:15

echo "Plotting the read length" 
  cat sequence_PR1_trimmed.fq | awk '{if(NR%4==2) print length($1)}' | sort -n | uniq -c > read_length.txt
  Rscript ./scriptBase/plotReadLen.R read_length.txt

echo "Mapping the reads to reference"
  bwa index ./scriptBase/refGenome/corona.fa
  bwa mem -B 2 -t $core -O 5,5 -E 3 ./scriptBase/refGenome/corona.fa sequence_PR1_trimmed.fq sequence_PR2_trimmed.fq > aln-pe.sam
  samtools view -bS aln-pe.sam > aln-pe.bam

echo "Plotting the coverage"
  samtools sort -@ $core -o cov.bam aln-pe.bam
  samtools depth cov.bam > corona.cov
  awk '{print $0}' corona.cov > covid.cov
  Rscript ./scriptBase/plotCov.R covid.cov
  
echo "Removing supplementary alignments from a bam file"
  samtools view -F 2048 -bo aln-pe.filtered.bam aln-pe.bam

echo "Hunting mapped pairs"
  samtools view -b -f 0x2 aln-pe.filtered.bam > mappedPairs.bam

echo "Sorting the bam"
  samtools sort -n -o mappedPairs.sorted.bam mappedPairs.bam

echo "Extract the unmapped" 
  samtools view -u -f 4 -F 264 aln-pe.bam > temp1.bam #Extracting unmapped reads ... whose mate is mapped
  samtools view -u -f 8 -F 260 aln-pe.bam > temp2.bam #Extracting mapped reads ... whose mate pair is unmapped

  #if bam file is enmpty
  #This is most hilarious way to check the bam file <<< might need to update with better one
  #if bam file is enmpty 13 line begin with 0
  lCount=$(samtools flagstat temp2.bam | grep -c "^[0]"); echo $lCount
  
# This unmapped could be a treasure to fix the tail
  if [ $lCount -ne 13 ]
  then
      echo "BAM is not empty, lets merge it"
      samtools merge -f -u - temp[12].bam | samtools sort -n -@ $core -o unmapped.jit.bam
      #JITU for (U for unmapped)
      bamToFastq -i unmapped.jit.bam -fq lib_JITU_mapped.1.fastq -fq2 lib_JITU_mapped.2.fastq
  fi

echo "Extracting reads from bam"
  bamToFastq -i mappedPairs.sorted.bam -fq lib_JIT_mapped.1.fastq -fq2 lib_JIT_mapped.2.fastq
  
echo "Estimate the coverage"
  #readLen = 250
  #readCount = (wc -l lib_JIT_mapped.1.fastq)/4 
  #coverage = ($readCount * $readLen )/3000
  #echo $coverage

echo "Extract the long reads"
  seqtk seq -a $longR > long.reads.fasta
  minimap2 long.reads.fasta ./scriptBase/refGenome/corona.fa > overlaps.ont.reads.paf
  awk '{print $6}' overlaps.ont.reads.paf > all.ont.ids.txt
  samtools faidx long.reads.fasta
  ./scriptBase/extract_seq.sh all.ont.ids.txt
  seqtk subseq $longR all.ont.ids.txt > final.ont.reads.fastq

  cat *.tfa > final.ont.reads.fasta
  rm -rf *.tfa

#echo "Genome assembly begun -- PEAR not needed , just for testing" 
  #PE merge -- can be use in 'reliable' or 'long reads' // This PE merging appraoch does not seems to work well !!!
  #pear -f lib_JIT_mapped.1.fastq -r lib_JIT_mapped.2.fastq -o pear
  #seqtk seq -a pear.assembled.fastq > pear.assembled.fasta

  if [[ ${longN,,} == ont ]]
  then
    spades.py -t 2 --memory 33 --pe1-1 lib_JIT_mapped.1.fastq --pe1-2 lib_JIT_mapped.2.fastq --nanopore final.ont.reads.fastq -o ASM_CORONA_HYBRID >spades.out 2>&1
  elif [[ ${longN,,} == pacbio ]]
  then
    spades.py -t 2 --memory 33 --pe1-1 lib_JIT_mapped.1.fastq --pe1-2 lib_JIT_mapped.2.fastq --pacbio final.ont.reads.fastq -o ASM_CORONA_HYBRID >spades.out 2>&1
  else
     echo "Did you forgot to provide the read name info"
     kill %%
  fi

  #Re-assembly using reference
  ragout -s sibelia --refine --repeats --threads 1 --overwrite -o ragout_spades --solid-scaffolds ./scriptBase/config/recipe_file_hybrid
  #pip install assembly_stats
  assembly_stats ragout_spades/setu_scaffolds.fasta > assembly.stats

echo "Fillig the gap"
  #Fill the Gaps -- it fill up the NNNN regions in scaffolded genome
  #https://www.cs.helsinki.fi/u/lmsalmel/Gap2Seq/README.txt
   Gap2Seq -scaffolds ragout_spades/setu_scaffolds.fasta -filled ragout_spades/setu_scaffolds.filled.fa -reads lib_JIT_mapped.1.fastq,lib_JIT_mapped.2.fastq

echo "Final mapping to visual check" #Not necessary, but better to validate by eye
  source ./scriptBase/mapping.sh

echo "Final assembly files"
  if [[ $force == 'on' ]] ; then rm -rf mkdir finished_Assembly; mkdir finished_Assembly; else mkdir finished_Assembly ; fi
  cp ragout_spades/setu_scaffolds.fasta finished_Assembly
  cp assembly.stats finished_Assembly
  cp ragout_spades/setu_scaffolds.filled.fa finished_Assembly


