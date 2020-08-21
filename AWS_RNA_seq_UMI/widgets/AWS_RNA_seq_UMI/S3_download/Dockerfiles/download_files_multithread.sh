#!/bin/bash
#files is passes as a variable and as an array
LOCAL_DIR=$1 
bucket=$2
nThreads=$3
files=( $(echo $FILES | jq -r '.[]') ) 


lockDir=/tmp/locks.$$
mkdir -p $lockDir
mkdir -p $LOCAL_DIR

runJob(){
 lasti=$((${#files[@]} - 1))
 for i in $(seq 0 ${lasti}); do
  if (mkdir $lockDir/lock$i 2> /dev/null ); then
   file=${files[i]}
   basefile="$(basename -- $file)"
   echo "thread $1: cd $LOCAL_DIR &&  aws s3 cp s3://$bucket/$file $basefile"
   cd $LOCAL_DIR && aws s3 cp s3://$bucket/$file $basefile
  fi
 done
 exit
}
for i in $(seq 2 $nThreads); do
	  runJob $i &
done
runJob 1 &
wait
rm -rf $lockDir
