#!/bin/bash

local_base_dir=$1
download_dir=gcp_test
credentials_file=credentials.json
bucket_name=gcpdtoxsbucket
function_name=dtoxsfunction
function_dir=$download_dir/function
function_entrypoint=gcp_handler
function_runtime=python37
function_topic_id=dtoxs
function_region=us-central1
function_timeout=300
function_memory=2048
function_max_instances=2000
executables_dir=$download_dir/dtoxs/executables
references_dir=$download_dir/dtoxs/References/Broad_UMI
executables_blob=gcp_test/executables
references_blob=gcp_test/References
long_seqs_dir=fullDtoxSSeqs/longSeqs
long_seqs_blob=gcp_test/longSeqs
short_seqs_dir=gcp_test/dtoxs/Seqs
short_seqs_blob=gcp_test/shortSeqs


exit 0
echo "docker  run -i --rm --init  -v $local_base_dir:/data   biodepot/downloadurl:alpine-3.7__012820 /root/download.sh --decompress --directory /data/$download_dir https://drive.google.com/open?id=14Tz2lznUjBZME_UUHFUEXtL7IUzkGCS7 https://drive.google.com/file/d/1Oiukqp2gfQAebrlWYblZRT1SWaSjjUrM/view?usp=sharing "

docker  run -i --rm --init  -v $local_base_dir:/data   biodepot/downloadurl:alpine-3.7__012820 /root/download.sh --decompress --directory /data/$download_dir https://drive.google.com/open?id=14Tz2lznUjBZME_UUHFUEXtL7IUzkGCS7 https://drive.google.com/file/d/1Oiukqp2gfQAebrlWYblZRT1SWaSjjUrM/view?usp=sharing 

echo "docker  run -i --rm --init  -v $local_base_dir:/data   biodepot/gcpcreate:python_3.8.0__alpine_3.10__4d00a9a9 create.py -c /data/$credentials_file -b $bucket_name"
docker  run -i --rm --init  -v $local_base_dir:/data   biodepot/gcpcreate:python_3.8.0__alpine_3.10__4d00a9a9 create.py -c /data/$credentials_file -b $bucket_name

echo "docker  run -i --rm --init  -v $local_base_dir:/data   biodepot/gcpdeploy:277.0.0-alpine__366868e4 deploy_function.sh  /data/$credentials_file $bucket_name $function_name /data/$function_dir $function_entrypoint $function_runtime $function_topic_id $function_timeout $function_memory $function_max_instances $function_region"
docker  run -i --rm --init  -v $local_base_dir:/data   biodepot/gcpdeploy:277.0.0-alpine__366868e4 deploy_function.sh  /data/$credentials_file $bucket_name $function_name /data/$function_dir $function_entrypoint $function_runtime $function_topic_id $function_timeout $function_memory $function_max_instances $function_region

echo " docker  run -i --rm --init  -v $local_base_dir:/data   biodepot/gcpupload:277.0.0-alpine__5194d59f upload.sh  /data/$credentials_file $bucket_name /data/$executables_dir $executables_blob "
docker  run -i --rm --init  -v $local_base_dir:/data   biodepot/gcpupload:277.0.0-alpine__5194d59f upload.sh  /data/$credentials_file $bucket_name /data/$executables_dir $executables_blob
echo " docker  run -i --rm --init  -v $local_base_dir:/data   biodepot/gcpupload:277.0.0-alpine__5194d59f upload.sh  /data/$credentials_file $bucket_name /data/references_dir $references_blob "
docker  run -i --rm --init  -v $local_base_dir:/data   biodepot/gcpupload:277.0.0-alpine__5194d59f upload.sh  /data/$credentials_file $bucket_name /data/$executables_dir $executables_blob

echo " docker  run -i --rm --init  -v $local_base_dir:/data   biodepot/gcpupload:277.0.0-alpine__5194d59f upload.sh  /data/$credentials_file $bucket_name /data/$short_seqs_dir $short_seqs_blob "
docker  run -i --rm --init  -v $local_base_dir:/data   biodepot/gcpupload:277.0.0-alpine__5194d59f upload.sh  /data/$credentials_file $bucket_name /data/$short_seqs_dir $short_seqs_blob 
exit 0

