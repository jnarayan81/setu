#!/bin/bash

#These files could be use to visualie it in 'tablet' or 'IGV'
  bwa index ragout_long/setu_scaffolds.fasta
  minimap2 -ax map-ont ragout_long/setu_scaffolds.fasta $longR > final.aln.long.sam
  samtools view -bS final.aln.long.sam > final.aln.long.bam
  samtools sort final.aln.long.bam > final.aln.long.sorted.bam
  samtools index final.aln.long.sorted.bam


