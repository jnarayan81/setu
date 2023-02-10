#!/bin/bash

#These files could be use to visualie it in 'tablet' or 'IGV'
  mkdir -p visualization
  bwa index ragout/setu_scaffolds.fasta
  #bwa mem ragout_spades/setu_scaffolds.filled.fa sequence_PR1_trimmed.fq sequence_PR2_trimmed.fq > finalAln-pe.sam
  bwa mem ragout/setu_scaffolds.fasta lib_JIT_mapped.1.fastq lib_JIT_mapped.2.fastq > visualization/finalAln-pe.sam
  samtools sort visualization/finalAln-pe.sam > visualization/finalAln-pe.sorted.bam
  samtools index visualization/finalAln-pe.sorted.bam

