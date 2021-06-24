#!/bin/bash

# Jitendra et al 2020, paired end (PE) CoViD genome assembler pipeline
# sample reads https://bigd.big.ac.cn/gsa/browse/CRA002424
# sanmple assembly  https://bigd.big.ac.cn/gwh/Assembly/956/show

#time ./setu.sh -k yes -m pe -t 1 -r /home/jit/Downloads/setu/sampleDATA/G1/SRR11140750_1.fastq,/home/jit/Downloads/setu/sampleDATA/G1/SRR11140750_2.fastq -f on -o see_pe


echo "You opted for Paired End (PE) option"
  IFS=, VER=(${reads##,-})
  forR1=${VER[0]}
  revR2=${VER[1]}
  echo $forR1 $revR2 #forwardRead,ReverseRead -- this should be the order

#Lets check the software first
allTools=(bwa mummer trimmomatic Rscript samtools bamToFastq ragout spades.py Gap2Seq kat assembly_stats megahit)
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
echo "Trimming reads"
  trimmomatic PE -threads $core -trimlog logfile $forR1 $revR2 sequence_PR1_trimmed.fq sequence_UR1_trimmed.fq sequence_PR2_trimmed.fq sequence_UR2_trimmed.fq LEADING:3 TRAILING:3 MINLEN:36 SLIDINGWINDOW:4:15

echo "Plotting the read length" 
  cat sequence_PR1_trimmed.fq | awk '{if(NR%4==2) print length($1)}' | sort -n | uniq -c > read_length.txt
  Rscript ./scriptBase/plotReadLen.R read_length.txt

echo "Mapping the raw reads"
  bwa index ./scriptBase/refGenome/corona.fa
  #This works fine for reads more than >70 base pairs -- does not fit for small sequences
  bwa mem -B 2 -t $core -O 5,5 -E 3 ./scriptBase/refGenome/corona.fa sequence_PR1_trimmed.fq sequence_PR2_trimmed.fq > aln-pe.sam
  samtools view -bS aln-pe.sam > aln-pe.bam
  #need to add -i flag sort -n (sort by name) -- is this really needed. Do i need to sort before hunting PE reads

echo "Plotting the coverage"
  samtools sort -@ $core -o cov.bam aln-pe.bam
  samtools depth cov.bam > corona.cov
  awk '{print $0}' corona.cov > covid.cov
  Rscript ./scriptBase/plotCov.R covid.cov

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

echo "Genome assembly begun"
  spades.py -t $core --memory 33 --pe1-1 lib_JIT_mapped.1.fastq --pe1-2 lib_JIT_mapped.2.fastq -o ASM_CORONA_PE >spades.out 2>&1

cp ./scriptBase/config/recipe_file_pe_spades .

echo "Re-assembly using reference"
  ragout -s sibelia --refine --repeats --threads $core --overwrite -o ragout_spades --solid-scaffolds recipe_file_pe_spades

  #Megahit assembly -- I wrote just for testing purposes -- it create more fragmented genome
  #megahit -1 lib_JIT_mapped.1.fastq  -2 lib_JIT_mapped.2.fastq  --no-mercy -t 2  --out-prefix megahit -o megahit_result
  #Re-assembly using reference
  #ragout -s sibelia --refine --repeats --threads 2 --overwrite -o ragout_megahit --solid-scaffolds ./scriptBase/config/recipe_file_pe_megahit

  #Bwise assembly -- this will be fine but fragmented
  #bwise -x interleaved.fq -o bwise_assembly

  #pip install assembly_stats
  assembly_stats ragout_spades/setu_scaffolds.fasta > assembly.spades.stats
  #assembly_stats ragout_megahit/setu_scaffolds.fasta > assembly.megahit.stats
  
echo "Fillig the gap"
  #Fill the Gaps -- it fill up the NNNN regions in scaffolded genome
  #https://www.cs.helsinki.fi/u/lmsalmel/Gap2Seq/README.txt
   Gap2Seq -scaffolds ragout_spades/setu_scaffolds.fasta -filled ragout_spades/setu_scaffolds.filled.fa -reads lib_JIT_mapped.1.fastq,lib_JIT_mapped.2.fastq

  #KAT plot -- a nice kmer based plot to visualize
  #kat comp -t 2 -o KAT_pe_v_asm $forR1 $revR2 ragout-out/spade_scaffolds.filled.fa

echo "Final mapping to visual check"
  source ./scriptBase/mapping.sh

echo "Final assembly files"
  if [[ $force == 'on' ]] ; then rm -rf mkdir finished_Assembly; mkdir finished_Assembly; else mkdir finished_Assembly; fi
  cp ragout_spades/setu_scaffolds.fasta finished_Assembly
  cp assembly.spades.stats finished_Assembly
  cp ragout_spades/setu_scaffolds.filled.fa finished_Assembly


