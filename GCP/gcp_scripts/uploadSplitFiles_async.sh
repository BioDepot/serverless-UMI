#!/bin/bash
#will look at all the files in the ALIGN DIR
ALIGN_DIR=$1
S3Path=$2
nThreads=$3
nSeqFiles=$4
complete_dir=$ALIGN_DIR"_complete"


lockDir=/tmp/locks.$$
echo $complete_dir

mkdir -p $lockDir

runJob(){
 lasti=$((${#files[@]} - 1))
 for i in $(seq 0 ${lasti}); do
  if (mkdir $lockDir/lock$i 2> /dev/null ); then
   fileDone=${files[$i]}
   file=${fileDone:2:(-5)}
   echo thread $1 working on $file
   #cd $ALIGN_DIR && nice mv $file $S3Path/$file && rm $fileDone
  fi
 done
 exit
}
#check if split is done
makeSubDirs(){
 subDirs=( $(cd $ALIGN_DIR && find * -type d) )
 for subDir in "${subDirs[@]}"
 do
	mkdir -p "$complete_dir/$subDir"
 done
}
move_complete(){
	for fileDone in "${files[@]}"
	do	
		file=${fileDone:2:(-5)}
		echo "cd $ALIGN_DIR && mv $file $complete_dir/$file && rm $fileDone"
	    cd $ALIGN_DIR && mv $file $complete_dir/$file && rm $fileDone 
	done
}

while [ -z $loop_done ]; do
	nDoneFiles=$(ls $ALIGN_DIR/*.done | wc -l)
	echo $nDoneFiles
	files=( $(cd $ALIGN_DIR && find . -mindepth 2 -name '*.done') )
	if (( ${#files[@]} )); then
		makeSubDirs
		move_complete
		echo "gsutil -m rsync -r $complete_dir $S3Path"
		gsutil -m rsync -r $complete_dir $S3Path
	fi
	if [ $nDoneFiles -eq $nSeqFiles ]; then
		echo "Split done"
		rm -rf $lockDirq
		loop_done=1
	fi
	sleep 1
done
echo "cleaning up"
rm $ALIGN_DIR/*done
