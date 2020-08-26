#!/bin/bash
##Copy your credentials file to ~/.aws - do this before executing script

#general params
bucket=dtoxstest
bucket_region=us-east-2
credentials_dir=/home/ubuntu/.aws
base_glob=lambda_test/dtoxs
nTrials=1

#function params
function_name=dtestfunction
function_region=us-east-2
function_zip_file=/mnt/data/serverless-UMI/AWS/RNA_seq_scripts/dtoxsfunction.zip
max_RAM=3008

#pubsub params
topic=dtoxspubsub
role=dtoxsrole
policy=dtoxspolicy
user=dtoxsuser

##Download dependencies

sudo apt-get update && sudo apt-get install -y build-essential libboost-all-dev zlib1g-dev zlib1g git python3-pip nano awscli curl unzip jq

##Compile split  and merge function

git clone https://github.com/BioDepot/LINCS_RNAseq_cpp.git
cd LINCS_RNAseq_cpp/source && make
sudo ln -s ${PWD}/w96/umimerge_parallel /usr/local/bin/umimerge_parallel
sudo ln -s ${PWD}/w96/umisplit /usr/local/bin/umisplit

##remove the segment with biodepot share if it is already there
sed -i '/biodepot-share/,/region/d' ~/.aws/credentials

##set up PROFILE for downloading from biodepot-share
   echo '[biodepot-share]' >> ~/.aws/credentials
   echo 'aws_access_key_id = AKIAXJASWUXDVS5RBIAS'  >> ~/.aws/credentials
   echo 'aws_secret_access_key = 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' >> ~/.aws/credentials
   echo 'region = us-east-2' >> ~/.aws/credentials

##Create the RAID
aws s3 cp s3://biodepot-share/serverless-UMI/AWS/mount_RAID0.sh mount_RAID0.sh --profile biodepot-share
chmod +x ./mount_RAID0.sh
sudo mkdir -p /mnt/data
sudo ./mount_RAID0.sh

##Download the full sequences
glob="dtoxs"
##Uncomment the next line if you do not want the full sequences downloaded
##glob="demo/dtoxs"
aws s3 cp s3://biodepot-share/$glob/ /mnt/data --profile biodepot-share --recursive
sudo chown -R ubuntu:ubuntu /mnt/data
aws s3 cp s3://biodepot-share/serverless-UMI/ /mnt/data/serverless-UMI --profile biodepot-share --recursive
pip3 install boto3


##Create bucket
echo "creating bucket $bucket"
aws s3api  head-bucket --bucket $bucket --region $bucket_region &>/dev/null && echo "bucket exists" || aws s3api create-bucket --bucket $bucket --region $bucket_region --create-bucket-configuration LocationConstraint=$bucket_region

##Create function
echo "python3 /mnt/data/serverless-UMI/AWS/deploy.py -c $credentials_dir -t $topic --fn $function_name --fr $function_region --handler main.lambda_handler -m $max_RAM -p $policy --role $role --fz $function_zip_file -u $user"
python3 /mnt/data/serverless-UMI/AWS/deploy.py -c $credentials_dir -t $topic --fn $function_name --fr us-east-2 --handler main.lambda_handler -m $max_RAM -p $policy --role $role --fz $function_zip_file -u $user

##Upload reference
echo "uploading Reference"
aws s3 cp /mnt/data/References s3://$bucket/$base_glob/References --recursive

##Upload executables

echo "uploading executables"
aws s3 cp /mnt/data/executables s3://$bucket/$base_glob/executables --recursive

##Upload exed

##Upload sequence files to users S3 - benchmarks start with files in S3
echo "moving sequence files to bucket"
echo "aws s3 mv /mnt/data/Seqs s3://$bucket/Seqs/ --recursive"
aws s3 mv /mnt/data/Seqs s3://$bucket/Seqs/ --recursive

##Copy RNA_scripts
echo "Copying RNA_scripts"
cp -r /mnt/data/serverless-UMI/AWS/RNA_seq_scripts /home/ubuntu/.
chmod +x /home/ubuntu/RNA_seq_scripts/*

##Replacing hardcoded variables in original script
echo "Replacing hardcoded variables in original script"
cp -r /mnt/data/serverless-UMI/AWS/RNA_seq_scripts /home/ubuntu/.
chmod +x /home/ubuntu/RNA_seq_scripts/*
sed -i "s/bucket=.*\"/bucket=\'${bucket}\'/" /home/ubuntu/RNA_seq_scripts/runAll.sh
sed -i "s/bucket=.*\'/bucket=\'${bucket}\'/" /home/ubuntu/RNA_seq_scripts/runInvokeAWS.sh
sed -i "s|lambda_test\/dtoxs|${base_glob}|g" /home/ubuntu/RNA_seq_scripts/runAll.sh
sed -i "s|lambda_test\/dtoxs|${base_glob}|g" /home/ubuntu/RNA_seq_scripts/cleanup_all.sh
sed -i "s|lambda_test\/dtoxs|${base_glob}|g" /home/ubuntu/RNA_seq_scripts/cleanup_local.sh
sed -i "s|lambda_test\/dtoxs|${base_glob}|g" /home/ubuntu/RNA_seq_scripts/cleanup_warm.sh
sed -i "s|lambda_test\/dtoxs|${base_glob}|g" /home/ubuntu/RNA_seq_scripts/cleanup.sh
sed -i "s|lambda_test\/dtoxs|${base_glob}|g" /home/ubuntu/RNA_seq_scripts/runInvokeAWS.sh

echo "setup is done"

#start benchmark run
echo "starting $nTrials benchmark runs"
echo "cd /home/ubuntu/RNA_seq_scripts && ./runMany.sh $nTrials &> /mnt/data/runLog &"
cd /home/ubuntu/RNA_seq_scripts && ./runMany.sh $nTrials &> /mnt/data/runLog &


