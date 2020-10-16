#!/bin/bash
SEQS_DIR=$1
npairs=$2
fastq_suffix=$3
size=$4
alignsDir=$5
barcode=$6
umilength=$7
threads=$8

npairs_launched=0
splitR1R2Pairs(){
 for doneFile in ${doneFiles[@]}; do
   donebase=${doneFile##*/}
   if [[ $donebase == *"R1.${fastq_suffix}"* ]]; then
     R1Files[$doneFile]=1
   elif [[ $donebase == *"R2.${fastq_suffix}"* ]]; then
     R2Files[$doneFile]=1
   fi
 done
 for doneFile in "${!R1Files[@]}"; do
   if [[  -z ${pairSeen[$doneFile]} ]]; then
     donebase=${doneFile##*/}
     filebase="${donebase%R1.${fastq_suffix}.*}"
     fileExt="${donebase#*.}"
     R2doneFile="$SEQS_DIR/$filebase""R2.$fileExt"    
     logFile="$alignsDir/$filebase""R1R2.log"
     if [[ ${R2Files[$R2doneFile]+1}  ]]; then
       pairSeen[$doneFile]=1
       R1File="${doneFile%.*}"
       R2File="${R2doneFile%.*}"
       echo "umisplit -s $size -d -v -l $umilength -m 0 -N 0 -f -o $alignsDir -t $threads -b $barcode $R1File $R2File &> $logFile &"
       umisplit -s $size -d -v -l $umilength -m 0 -N 0 -f -o $alignsDir -t $threads -b $barcode $R1File $R2File &> $logFile &
     fi
   fi
 done
}
date
declare -A R1Files
declare -A R2Files
declare -A pairSeen


while [ 1 ]; do
 echo "find $SEQS_DIR -name '*.done'"
 doneFiles=( $( find $SEQS_DIR -name '*.done' ) )
 splitR1R2Pairs
 npairs_launched="${#pairSeen[@]}"
 echo "${!pairSeen[@]}"
 echo "$npairs_launched"
 echo "$npairs"
 if ((npairs_launched>=npairs)); then
  echo "All $npairs pairs begun splitting $(date)" 
  exit 0
 fi
 sleep 1
done
