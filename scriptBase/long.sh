#!/bin/bash

# Jitendra et al 2020, longread CoViD genome assembler pipeline
# TODO we can add extension approaches

#time ./setu.sh -k yes -m long -t 1 -r /home/jit/Downloads/setu/sampleDATA/reads_100x.fastq,ont -f on -o see_long


IFS=, VER=(${reads##,-})
  longR=${VER[0]}
  readN=${VER[1]}
  echo $longR,$readN

  if [ -z "$longR" ]
  then
      echo " ${Red} $longR is NULL, please provide long reads ${Reset}"
      exit 1
  elif [ -z "$readN" ]
  then
      echo " ${Red} $readN long read name is NULL, please provide read name: ont or pacbio ${Reset}"
      exit 1
  else
      echo " $longR used for long read based assembly"
  fi


#Lets check the software first
allTools=(bwa seqtk minimap2 trimmomatic Rscript samtools bamToFastq ragout seqkit miniasm Gap2Seq kat assembly_stats megahit shasta canu odgi seqwish )
decFlag=0;
for name in ${allTools[@]}; do
#echo "enter your package name"
#read name
    #echo "Checking $name"
    #dpkg -s $name &> /dev/null

    if ! [ -x "$(command -v $name)" ]; then
                echo " $name     -- NOT installed." >&2
                decFlag=1
        else
                echo    " $name     -- installed"
    fi
done

if [[ $decFlag -ne 0 ]]
        then
        echo "Install all the missing sotware first"
        exit 1
fi


#echo "Trimming the reads" --- expecting corrected long reads 
#Currently not ont and pacbio flags active

echo "Extract the long reads of interest"
  seqtk seq -a $longR > long.reads.fasta
  minimap2 long.reads.fasta ./scriptBase/refGenome/corona.fa > overlaps.long.reads.paf
  awk '{print $6}' overlaps.long.reads.paf > all.long.ids.txt
  samtools faidx long.reads.fasta
  ./scriptBase/extract_seq.sh all.long.ids.txt
  seqtk subseq $longR all.long.ids.txt > final.long.reads.fastq
  cat *.tfa > final.long.reads.fasta
  rm -rf *.tfa

echo "Mapping way of extracting the long reads"
  minimap2 -ax map-ont ./scriptBase/refGenome/corona.fa $longR > aln.long.sam
  samtools view -bS aln.long.sam > aln.long.bam
  samtools view -b -F 4 aln.long.sam > mapped.long.bam
  samtools view -F 2048 -bo mapped.long.filered.bam mapped.long.bam
  #bedtools bamtofastq -i mapped.ont.bam -fq mapped.ont.fastq
  samtools bam2fq mapped.long.filered.bam > mapped.long.fastq
  seqtk seq -a mapped.long.fastq > mapped.long.fasta

echo "Plotting the coverage"
  samtools sort -@ $core -o cov.long.bam aln.long.bam
  samtools depth cov.long.bam > corona.cov
  awk '{print $0}' corona.cov > covid.cov
  Rscript ./scriptBase/plotCov.R covid.cov

#Plot the length distro
  seqkit fx2tab mapped.long.fasta -l | csvtk cut -t -f 4 | csvtk plot hist -H > hist.png

#My way -- testing mode only
  #minimap2 -c -w 1 -k 21 -X -t 1 mapped.long.fastq  mapped.long.fastq > self.overlaps.final.ont.reads.paf
  #seqwish -t 1 -k 16 -s mapped.long.fastq -p self.overlaps.final.ont.reads.paf -g self.overlaps.final.ont.reads.gfa

  #odgi build -g self.overlaps.final.ont.reads.gfa -o - | odgi prune -i - -b 3 -o - | odgi view -i - -g >filtered.self.overlaps.final.ont.reads.gfa

  #awk '/^S/{print ">"$2"\n"$3}' filtered.self.overlaps.final.ont.reads.gfa | fold > filtered.self.overlaps.final.ont.reads.fa

#Using miniasm approach
  #minimap2 -x ava-ont -t 1 final.long.reads.fastq  final.long.reads.fastq > self.overlaps.final.long.reads.paf
  #miniasm -R -m 50 -r 0.8,0.6 -c 1 -h 100 -s 10 -e 2 -f final.long.reads.fastq self.overlaps.final.long.reads.paf > self.overlaps.final.long.reads.gfa
  #awk '$1 ~/S/ {print ">"$2"\n"$3}' self.overlaps.final.ont.reads.gfa > raw.assembly.overlaps.final.ont.reads.fasta
  #minimap2 -t 1 raw.assembly.overlaps.final.ont.reads.fasta self.overlaps.final.ont.reads.paf > mapping.overlaps.final.ont.reads.paf

#Shasta way
  ./scriptBase/shasta-Linux-0.7.0 --input mapped.long.fasta --conf ./scriptBase/shasta_local2.conf --memoryBacking 2M --memoryMode filesystem

#Flye way  
  #flye --nano-raw mapped.long.fastq --meta --out-dir out_ont.corona --genome-size 29k --threads 1

#Canu way
  #canu -assemble -p corona useGrid=false -d corona-oxford genomeSize=0.029m -nanopore-corrected mapped.long.fastq

<<COMMENT1
#Lets extend at the end --- this will work only when long reads qre corrected
  minimap2 mapped.long.fasta ./scriptBase/refGenome/corona.fa > overlaps.long.reads.paf
  awk '{print $6}' overlaps.long.reads.paf > all.long.ids.txt
  samtools faidx mapped.long.fasta
  ./scriptBase/extract_seq.sh all.long.ids.txt
  seqtk subseq mapped.long.fasta all.long.ids.txt > final.long.reads.fastq
  cat *.tfa > final.hang.reads.fasta
  rm -rf *.tfa
  cat final.hang.reads.fasta ShastaRun/Assembly.fasta > added.reads.assembly.fa
COMMENT1

cp ./scriptBase/config/recipe_file_long .

echo "Re-assembly using reference"
  ragout -s sibelia --repeats --threads $core --overwrite -o ragout_long --solid-scaffolds recipe_file_long

  #pip install assembly_stats
  assembly_stats ragout_long/setu_scaffolds.fasta > assembly.stats

echo "Final mapping to visual check" #Not necessary, but better to validate by eye ;)
  source ./scriptBase/mapping_long.sh

echo "Final assembly files"
  if [[ $force == 'on' ]] ; then rm -rf mkdir finished_Assembly; mkdir finished_Assembly; else mkdir finished_Assembly ; fi
  cp ragout_long/setu_scaffolds.fasta finished_Assembly
  cp assembly.stats finished_Assembly
  cp ShastaRun/Assembly.fasta finished_Assembly

