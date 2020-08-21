#!/bin/bash

LOCAL_DIR=$1
bucket=$2
cloudPath=$3
nThreads=$4

if [ "$cloudPath" == "." ] ; then
  cloudPath=""
fi

lockDir=/tmp/locks.$$
mkdir -p $lockDir
mkdir -p $LOCAL_DIR

runJob(){
 lasti=$((${#files[@]} - 1))
 for i in $(seq 0 ${lasti}); do
  if ( mkdir $lockDir/lock$i 2> /dev/null ); then
   file=${files[i]}
   basefile="$(basename -- $file)"
   echo "thread $1: cd $LOCAL_DIR &&  aws s3 cp s3://$bucket/$file $basefile"
   cd $LOCAL_DIR &&  aws s3 cp s3://$bucket/$file $basefile
  fi
 done
 exit
}
files=()
if [ -z "$SUFFIX" ]; then
   files=( $(aws s3 ls $bucket/$cloudPath --recursive | tr -s ' ' | cut -d ' ' -f 4 | grep -v '^[[:space:]]*$') )
else
   files=( $(aws s3 ls $bucket/$cloudPath --recursive | tr -s ' ' | cut -d ' ' -f 4 | grep '.*{}$') )
fi
for i in $(seq 2 $nThreads); do
	  runJob $i &
done
runJob 1 &
wait
rm -rf $lockDir
