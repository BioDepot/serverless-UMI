#/bin/bash

local_dir=/mnt/data
cloud_glob=gcp_test
bucket=gcpdtoxsbucket

rm -r $local_dir/Seqs
rm -r $local_dir/Aligns
rm -r $local_dir/Aligns_complete
rm -r $local_dir/saf
rm -rf $local_dir/Counts

gsutil -m rm -r gs://$bucket/$cloud_glob/Aligns/*
gsutil -m rm -r gs://$bucket/$cloud_glob/start
gsutil -m rm -r gs://$bucket/$cloud_glob/saf
