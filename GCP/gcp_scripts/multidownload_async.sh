#!/bin/bash
bucket=$1
seqsglob=$2
SEQS_DIR=$3
nThreads=$4
lockDir=/tmp/locks.$$
mkdir -p $lockDir
mkdir -p $SEQS_DIR
rm -f $SEQS_DIR/*done

runJob(){
 lasti=$((${#files[@]} - 1))
 for i in $(seq 0 ${lasti}); do
  if (mkdir $lockDir/lock$i 2> /dev/null ); then
   file=${files[$i]}
   basefile=$(basename -- "$file")
   echo "gsutil cp $file $SEQS_DIR/$basefile && touch $SEQS_DIR/$basefile.done"   
   gsutil cp $file "$SEQS_DIR"/"$basefile" && touch "$SEQS_DIR/$basefile.done"
 fi
 done
 exit
}
echo "gsutil ls gs://$bucket/$seqsglob/ "
files=( $(gsutil ls gs://$bucket/$seqsglob/) )

for i in $(seq 2 $nThreads); do
	  runJob $i &
done
runJob 1 &
wait
touch $SEQS_DIR/all_done
rm -rf $lockDir
