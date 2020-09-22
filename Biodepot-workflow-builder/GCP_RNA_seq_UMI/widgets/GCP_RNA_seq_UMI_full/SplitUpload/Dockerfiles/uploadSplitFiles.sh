#!/bin/bash
#will look at all the files in the ALIGN DIR
ALIGN_DIR=$1
S3Path=$2
done_dir=$3
nSeqFiles=$4
complete_dir=$ALIGN_DIR"_complete"

lockDir=/tmp/locks.$$
echo $complete_dir

mkdir -p $done_dir

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
		echo "cd $ALIGN_DIR && mv $file $complete_dir/$file && mv $fileDone"
	    cd $ALIGN_DIR && mv $file $complete_dir/$file && mv $fileDone $done_dir/ 
	done
}

files=( $(cd $ALIGN_DIR && find . -mindepth 2 -name '*.done') )
if (( ${#files[@]} )); then
	makeSubDirs
	move_complete
	echo "gsutil -m rsync -r $complete_dir $S3Path"
	nice gsutil -m rsync -r $complete_dir $S3Path
fi
mv $complete_dir $done_dir/.
