#!/bin/bash

#These files could be use to visualie it in 'tablet' or 'IGV'
  bwa index ragout_spades/setu_scaffolds.filled.fa
  #bwa mem ragout_spades/setu_scaffolds.filled.fa sequence_PR1_trimmed.fq sequence_PR2_trimmed.fq > finalAln-pe.sam
  bwa mem ragout_spades/setu_scaffolds.filled.fa lib_JIT_mapped.1.fastq lib_JIT_mapped.2.fastq > finalAln-pe.sam
  samtools sort finalAln-pe.sam > finalAln-pe.sorted.bam
  samtools index finalAln-pe.sorted.bam


