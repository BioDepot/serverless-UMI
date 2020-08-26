#!/bin/bash
#Script assumes that the AWS credentials files is the home directory
pemFile=$1
instance_ip=$2
credentials=$3

if [ -z $pemFile ] || [ -z $instance_ip ]; then
    echo "This script installs and downloads all the files needed and runs the benchmark script run_benchmark.sh on an AWS instance with the base ubuntu 18.04 image"
    echo "Usage:"
    echo "start_benchmark.sh <pem file> <ip> <optional credentials file>"
    echo "For example"
    echo "./start_benchmark.sh my_pem.pem ec2-3-22-209-143.us-east-2.compute.amazonaws.com"
    exit 0
fi
if [ -z $credentials ]; then
   echo "assuming credentials file is ~/.aws/credentials
   credentials="~/.aws/credentials"
fi 

echo "ssh -i $pemFile ubuntu@$ip 'mkdir -p /home/ubuntu/.aws'"
ssh -i $pemFile ubuntu@$ip 'mkdir -p /home/ubuntu/.aws'
echo "scp -i $pemFile $credentials ubuntu@$ip:.aws/credentials "
scp -i $pemFile $credentials ubuntu@$ip:.aws/credentials
echo "scp -i $pemFile run_benchmark.sh ubuntu@$ip:run_benchmark.sh"
scp -i $pemFile run_benchmark.sh ubuntu@$ip:run_benchmark.sh
echo "ssh -i $pemFile ubuntu@$ip 'run_benchmark.sh'"
ssh -i $pemFile ubuntu@$ip 'run_benchmark.sh'
