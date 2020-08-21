#!/bin/bash

awsdir=$1
bucket=$2
outputDir=$3

mkdir -p outputDir

cp -r $awsdir/* /root/.aws
if [ -z $nThreads ]; then 
	if [ -z $DIRS ]; then
		echo "no directories to download"
	elif [ "$DIRS" == "[]" ]; then
		echo "downloading the entire bucket $bucket"
		echo aws s3 cp s3://$bucket $outputDir/. --recursive
		aws s3 cp s3://"${bucket}" "${outputDir}/." --recursive
	else
		darray=( $(echo $DIRS | jq -r '.[]') )
		if [ -z $darray ]; then
			echo "cannot parse $DIRS"
		else
			for dir in "${darray[@]}"; do
				echo "aws s3 cp s3://$bucket/$dir $outputDir/. --recursive"
				aws s3 cp s3://"${bucket}"/"${dir}" "${outputDir}/." --recursive
			done
		fi
	fi
	if [ -z $FILES ]; then
		echo "no files to download"
	else
		echo $FILES
		farray=( $(echo $FILES | jq -r '.[]') )
		for f in "${farray[@]}"; do
			echo "aws s3 cp s3://$bucket/$f $outputDir/."
			aws s3 cp s3://"${bucket}"/"${f}" "${outputDir}/."
		done
	fi
else
	if [ -z $DIRS ]; then
		echo "no directories to download"
	elif [ "$DIRS" == "[]" ]; then
		echo "downloading the entire bucket $bucket"
		#the "." will be substituted with an empty string inside the download_dir script
		echo "download_dir_multithread.sh $outputDir $bucket . $nThreads"
		download_dir_multithread.sh $outputDir $bucket . $nThreads
	else
		darray=( $(echo $DIRS | jq -r '.[]') )
		if [ -z $darray ]; then
			echo "cannot parse $DIRS"
		else
			for dir in "${darray[@]}"; do
				echo "download_dir_multithread.sh $outputDir $bucket $dir $nThreads"
				download_dir_multithread.sh $outputDir $bucket $dir $nThreads
			done
		fi
	fi
	if [ -z $FILES ]; then
		echo "no files to download"
	else
		echo "download_files_multithread.sh $outputDir $bucket $nThreads"
		download_files_multithread.sh $outputDir $bucket $nThreads
	fi
fi
#echo ${FILES[@]}
#copy credentials
#cp -r $awsdir/* /root/.aws
#download directory
#aws s3 cp $uploadDir s3://$bucket/$s3Dir --recursive
