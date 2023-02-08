#!/bin/bash

# Jitendra et al 2020, paired end (PE) CoViD genome assembler pipeline
# sample reads https://bigd.big.ac.cn/gsa/browse/CRA002424
# sanmple assembly  https://bigd.big.ac.cn/gwh/Assembly/956/show

#time ./setu.sh -k yes -m pe -t 1 -r /home/jit/Downloads/setu/sampleDATA/G1/SRR11140750_1.fastq,/home/jit/Downloads/setu/sampleDATA/G1/SRR11140750_2.fastq -f on -o see_pe
(
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "You opted for Paired End (PE) reads option"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  IFS=, VER=(${reads##,-})
  forR1=${VER[0]}
  revR2=${VER[1]}
  echo $forR1 $revR2 #forwardRead,ReverseRead -- this should be the order

#Lets check the software first
allTools=(bwa trimmomatic Rscript samtools bedtools ragout spades.py quast)
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


echo "Checking the raw coverage"
  source ./scriptBase/fastqCov.sh $forR1 $revR2 ./scriptBase/refGenome/corona.fa > rawCov.stats

#Trim the reads  
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Trimming reads"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  trimmomatic PE -threads $core -trimlog trimlog $forR1 $revR2 sequence_PR1_trimmed.fq sequence_UR1_trimmed.fq sequence_PR2_trimmed.fq sequence_UR2_trimmed.fq LEADING:3 TRAILING:3 MINLEN:36 SLIDINGWINDOW:4:15

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Plotting the read length"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  cat sequence_PR1_trimmed.fq | awk '{if(NR%4==2) print length($1)}' | sort -n | uniq -c > read_length.txt
  Rscript ./scriptBase/plotReadLen.R read_length.txt ReadLenPlot.pdf

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Mapping the raw reads"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  bwa index ./scriptBase/refGenome/corona.fa
  #This works fine for reads more than >70 base pairs -- does not fit for small sequences
  bwa mem -B 2 -t $core -O 5,5 -E 3 ./scriptBase/refGenome/corona.fa sequence_PR1_trimmed.fq sequence_PR2_trimmed.fq > aln-pe.sam
  samtools view -bS aln-pe.sam > aln-pe.bam
  #need to add -i flag pe.bamsort -n (sort by name) -- pe.bamis this really needed. Do i need to sort bpe.bamefore huntingpe.bam PE reads

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Plotting coverage"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  samtools sort -@ $core -o cov.bam aln-pe.bam
  samtools depth cov.bam > corona.cov
  awk '{print $0}' corona.cov > covid.cov
  Rscript ./scriptBase/plotCov.R covid.cov covPlot.pdf

echo "Removing supplementary alignments from a bam file"
  samtools view -F 2048 -bo aln-pe.filtered.bam aln-pe.bam

echo "Hunting mapped pairs of reads"
  samtools view -b -f 0x2 aln-pe.filtered.bam > mappedPairs.bam

echo "Sorting the bam file"
  samtools sort -n -@ $core -o mappedPairs.sorted.bam mappedPairs.bam
  
echo "Extracting the unmapped reads" 
  samtools view -u -f 4 -F 264 aln-pe.bam > temp1.bam #Extracting unmapped reads ... whose mate is mapped
  samtools view -u -f 8 -F 260 aln-pe.bam > temp2.bam #Extracting mapped reads ... whose mate pair is unmapped


  #if bam file is enmpty
  #This is most hilarious way to check the bam file <<< might need to update with better one
  lCount=$(samtools flagstat temp2.bam | grep -c "^[0]"); echo $lCount
  
  if [ $lCount -ne 13 ]
  then
      echo "BAM is not empty, lets merge it"
      #*****WARNING: Query SRR11177792.71253 is marked as paired, but its mate does not occur next to it in your BAM file.  Skipping.  IF NOT IN PAIR
      samtools merge -f -u - temp[12].bam | samtools sort -n -@ $core -o unmapped.jit.bam
      #JITU for (U for unmapped)
      bamToFastq -i unmapped.jit.bam -fq lib_JITU_mapped.1.fastq -fq2 lib_JITU_mapped.2.fastq
  fi

echo "Extracting reads from bam"
  bamToFastq -i mappedPairs.sorted.bam -fq lib_JIT_mapped.1.fastq -fq2 lib_JIT_mapped.2.fastq

  #interleave 
  #reformat.sh overwrite=true in1=lib_JIT_mapped.1.fastq in2=lib_JIT_mapped.2.fastq out=interleaved.fq

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Genome assembly begun"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  spades.py -t $core --corona -1 lib_JIT_mapped.1.fastq -2 lib_JIT_mapped.2.fastq -o spades -k 33 #>spades_log.txt 2>&1
 cp ./scriptBase/config/recipe_file_pe_spades .
 rm -rf recipe_file_pe_spades
 
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Re-assembly using reference"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  ragout -s sibelia --refine --repeats --threads $core --overwrite -o ragout --solid-scaffolds recipe_file_pe_spades

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Calculating stats using QUAST"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  quast -t $core -o assembly_stats ragout/setu_scaffolds.fasta
  
#Fill the Gaps -- filling the N regions in scaffolded genome
#https://www.cs.helsinki.fi/u/lmsalmel/Gap2Seq/README.txt  
# Currently does not work due to errors.
#if [[ $scaffold == 'yes' ]]
#  then
#   echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
#   echo "Filling the gap"
#   echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
#    Gap2Seq -s ragout/setu_scaffolds.fasta -f ragout/setu_scaffolds.filled.fa -r lib_JIT_mapped.1.fastq,lib_JIT_mapped.2.fastq
#fi

#KAT plot -- a nice kmer based plot to visualize
#Only works one read + contig file at a time.
#kat comp -t $core -o KAT_comp/ $forR1 $revR2 ragout/setu_scaffolds.fa

#echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
#echo "Final mapping to visual check"
#echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
#source ./scriptBase/mapping.sh

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Copying final assembly files"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  if [[ $force == 'on' ]] ; then rm -rf mkdir final_output; mkdir final_output; else mkdir final_output; fi
  cp ragout/setu_scaffolds.fasta final_output
  cp assembly_stats/report.tsv final_output
 # cp ragout/setu_scaffolds.filled.fa final_output
 
) 2>&1 | tee -a $out/log_setu.txt 
