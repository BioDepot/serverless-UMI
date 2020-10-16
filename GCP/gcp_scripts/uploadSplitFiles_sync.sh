#!/bin/bash
#will look at all the files in the ALIGN DIR
ALIGN_DIR=$1
S3Path=$2
nThreads=$3

lockDir=/tmp/locks.$$
mkdir -p $lockDir


runJob(){
 lasti=$((${#files[@]} - 1))
 for i in $(seq 0 ${lasti}); do
  if (mkdir $lockDir/lock$i 2> /dev/null ); then
   fileDone=${files[$i]}
   file=${fileDone:2:(-5)}
   echo thread $1 working on $file
   #echo "cd $ALIGN_DIR && nice gsutil cp $file $S3Path/$file && rm $fileDone"
   echo "cd $ALIGN_DIR && nice gsutil cp $file $S3Path/$file"
   cd $ALIGN_DIR && nice gsutil cp $file $S3Path/$file
   #cd $ALIGN_DIR && aws s3 cp $file $S3Path/$file && rm $fileDone
  fi
 done
 exit
}
files=( $(cd $ALIGN_DIR && find . -mindepth 2 -name '*.done') )
#need the next line here - otherwise this may exit without doing anything - possibly race condition with files??
echo "${#files[@]} files found"
for i in $(seq 2 $nThreads); do
	  runJob $i &
done
runJob 1 &
wait
rm -rf $lockDir
