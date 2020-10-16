#!/bin/bash
SEQS_DIR=$1
fastq_suffix=$2
size=$3
alignsDir=$4
barcode=$5
umilength=$6
threads=$7


splitR1R2Pairs(){
 for fastqFile in ${fastqFiles[@]}; do
   fastqbase=${fastqFile##*/}
   if [[ $fastqFile == *"R1.${fastq_suffix}"* ]]; then
     R1Files[$fastqFile]=1
   elif [[ $fastqbase == *"R2.${fastq_suffix}"* ]]; then
     R2Files[$fastqFile]=1
   fi
 done
 pids=()
 for fastqFile in "${!R1Files[@]}"; do
   if [[  -z ${pairSeen[$fastqFile]} ]]; then
     fastqbase=${fastqFile##*/}
     filebase="${fastqbase%R1.${fastq_suffix}}"
     fileExt="${fastqbase#*.}"
     R2fastqFile="$SEQS_DIR/$filebase""R2.$fileExt"    
     logFile="$alignsDir/$filebase""R1R2.log"
     echo "working on $fastqbase"
     echo "R1 file is $fastqFile"
     echo "R2 file is $R2fastqFile"
     echo "logFile is $logFile"
     if [[ ${R2Files[$R2fastqFile]+1}  ]]; then
       pairSeen[$fastqFile]=1
       echo "umisplit -s $size -d -v -l $umilength -m 0 -N 0 -f -o $alignsDir -t $threads -b $barcode $fastqFile $R2fastqFile &> $logFile &"
       umisplit -s $size -d -v -l $umilength -m 0 -N 0 -f -o $alignsDir -t $threads -b $barcode $fastqFile $R2fastqFile &> $logFile &
       pids+=($!)
     fi
   fi
 done
 for pid in ${pids[*]}; do
    wait $pid
 done
}
date
declare -A R1Files
declare -A R2Files
declare -A pairSeen
fastqFiles=( $( find $SEQS_DIR -name *.${fastq_suffix}* ) )
splitR1R2Pairs


