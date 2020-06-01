#!/bin/bash
  while IFS='' read -r line || [[ -n "$line" ]]; do
    echo "Text read from file: $line"
    samtools faidx long.reads.fasta $line > $line.tfa
  done < "$1" 
