#!/bin/bash

#Run Setu
cores=8
output=test_out
./setu.sh -k yes -m pe -t $cores -r ./data/test_1.fq,./data/test_2.fq -f on -o $output

#Final check
if [ -f "$output/ragout/setu_scaffolds.fasta" ];
then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "TEST SUCCESSFUL!"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━";
else
   echo "━━━━━━━━━━━━━━━━━━━━━"
   echo "FAILED"
   echo "━━━━━━━━━━━━━━━━━━━━━"
fi
