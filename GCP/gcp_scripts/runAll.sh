#!/bin/bash
#synchronous=1
no_setup=1

project="serverless-test-262607"
label="gcp_60".$(date "+%Y%m%d-%H%M%S")
seqs_dir="/mnt/data/Seqs"
logs_dir="/mnt/data/logs/logs.$label"

fastq_suffix="fastq.gz"
file_max=60000
aligns_dir="/mnt/data/Aligns"
barcode_file="/mnt/data/References/Broad_UMI/barcodes_trugrade_96_set4.dat"
umi_length=16
split_threads=1

bucket="gcpdtoxsbucket"
seqs_glob="longseqs"
#seqs_glob="short_seqs"
download_threads=12
splitDoneFile="/mnt/data/Aligns/done_file"
min_upload_split_threads=8
max_upload_split_threads=24

cloud_work_dir='gcp_test'
local_work_dir="/mnt/data"
cloud_saf_dir="saf" #relative to cloud_work_dir
local_saf_dir="saf" #relative to local_work_dir
aligns_glob="$cloud_work_dir/Aligns"
sample_id='RNAseq_20150409'
sym_to_ref=/mnt/data/References/Broad_UMI/Human_RefSeq/refGene.hg19.sym2ref.dat
ercc=/mnt/data/References/Broad_UMI/ERCC92.fa
counts_dir="/mnt/data/Counts"
merge_threads=20

times_file="$logs_dir/times"

#invoke parameters
topicID="dtoxs"
recv_topic="dtoxsrecv"
split_suffix=".fq"
output_upload_dir="saf"
credentials="/mnt/data/credentials.json"
invoke_threads=16
start_timeout=600
finish_timeout=1000

#make sure these directories exist before starting
mkdir -p $seqs_dir
mkdir -p $aligns_dir
mkdir -p $counts_dir
mkdir -p $logs_dir
mkdir -p $local_work_dir/$local_saf_dir

#find number of seqs to use as stop condition - otherwise can get race condition with all_done file

#deploy function parameters
function_name="dtoxsfunction"
function_dir="/mnt/data/function"
function_entrypoint="gcp_handler"
function_runtime="python37"
function_topic_id=$topicID
function_region=us-central1
function_timeout=300
function_memory=2048
function_max_instances=2000
if [[ -z no_setup ]]; then
 echo "Deploying function"
 echo "./deploy_function.sh  $project $bucket $function_name $function_dir $function_entrypoint $function_runtime $function_topic_id $function_timeout $function_memory $function_max_instances $function_region"
 ./deploy_function.sh  $project $bucket $function_name $function_dir $function_entrypoint $function_runtime $function_topic_id $function_timeout $function_memory $function_max_instances $function_region
fi

nPairs=$(gsutil ls gs://$bucket/$seqs_glob | grep R1\.$fastq_suffix |  wc -l)
nSeqs=$(gsutil ls gs://$bucket/$seqs_glob | grep $fastq_suffix |  wc -l)
echo "There are $nPairs pairs and $nSeqs fastq files in total"
if [[ -z $synchronous ]]; then
    echo "asynchronous run" > $times_file
	echo "start_all"$'\t'"$(date)" >> $times_file
	echo "./uploadSplitFiles_async.sh  $aligns_dir gs://$bucket/$aligns_glob $max_upload_split_threads $nSeqs &> $logs_dir/upload_split_log &"
    ./uploadSplitFiles_async.sh  $aligns_dir gs://$bucket/$aligns_glob $max_upload_split_threads $nSeqs &> $logs_dir/upload_split_log &
    upload_split_pid=$!	
	echo "sudo nice -n 10 sudo -u ubuntu ./runSplit_async.sh $seqs_dir $nPairs $fastq_suffix $file_max $aligns_dir $barcode_file $umi_length $split_threads &> "$logs_dir/split_log" &"
	sudo nice -n 10 sudo -u ubuntu ./runSplit_async.sh $seqs_dir $nPairs $fastq_suffix $file_max $aligns_dir $barcode_file $umi_length $split_threads &> "$logs_dir/split_log" &
	echo "./multidownload_async.sh $bucket $seqs_glob $seqs_dir $download_threads &> $logs_dir/download_log &"
	./multidownload_async.sh $bucket $seqs_glob $seqs_dir $download_threads &> "$logs_dir/download_log" &
	wait $upload_split_pid
else
    echo "synchronous run" > $times_file
	echo "start_all"$'\t'"$(date)" >> $times_file
	label="Synch_"$label
	echo "start_download"$'\t'"$(date)" >> $times_file
	echo "gsutil -m cp -r gs://$bucket/$seqs_glob/* $seqs_dir/"   
	gsutil -m cp -r "gs://$bucket/$seqs_glob/*" "$seqs_dir"/ 
	echo "start_split"$'\t'"$(date)" >> $times_file
   	echo "./runSplit_sync.sh  $seqs_dir $fastq_suffix $file_max $aligns_dir $barcode_file $umi_length $split_threads &> $logs_dir/split_log "
	./runSplit_sync.sh $seqs_dir $fastq_suffix $file_max $aligns_dir $barcode_file $umi_length $split_threads &> "$logs_dir/split_log"
	echo "start_split_upload"$'\t'"$(date)" >> $times_file
	echo "./uploadSplitFiles_sync.sh  $aligns_dir gs://$bucket/$aligns_glob $max_upload_split_threads &> $logs_dir/upload_split_log"
	./uploadSplitFiles_sync.sh  $aligns_dir gs://$bucket/$aligns_glob $max_upload_split_threads &> $logs_dir/upload_split_log 
fi

echo "start_invoke"$'\t'"$(date)" >> $times_file
echo "./invoke_google.py  $bucket $topicID  $cloud_work_dir $aligns_glob $recv_topic $split_suffix $output_upload_dir $project $invoke_threads $credentials $start_timeout $finish_timeout &> $logs_dir/invoke_log"
./invoke_google.py  $bucket $topicID  $cloud_work_dir $aligns_glob $recv_topic $split_suffix $output_upload_dir $project $invoke_threads $credentials $start_timeout $finish_timeout &> "$logs_dir/invoke_log"
echo "start_download_saf"$'\t'"$(date)" >> $times_file
echo "gsutil -m cp -r gs://$bucket/$cloud_work_dir/$cloud_saf_dir/* $local_work_dir/$local_saf_dir"
gsutil -m cp -r gs://$bucket/$cloud_work_dir/$cloud_saf_dir/* $local_work_dir/$local_saf_dir
echo "start_merge"$'\t'"$(date)" >> $times_file
echo "umimerge_parallel -m -p 0 -f -i $sample_id -s $sym_to_ref -e $ercc -b $barcode_file -a $local_work_dir/$local_saf_dir -o $counts_dir -t $merge_threads &> $logs_dir/mergeLog"
umimerge_parallel -m -p 0 -f -i $sample_id -s $sym_to_ref -e $ercc -b $barcode_file -a $local_work_dir/$local_saf_dir -o $counts_dir -t $merge_threads &> "$logs_dir/mergeLog"
echo "finish_merge"$'\t'"$(date)" >> $times_file



