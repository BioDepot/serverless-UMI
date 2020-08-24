#!/bin/bash
startDir=$1
docker build -t biodepot/bwb-umi:latest .
if  [ -z startDir ]; then
  startDir="."
fi
cd $startDir
docker run --rm  -p 6080:6080 -v ${PWD}/:/data -v /var/run/docker.sock:/var/run/docker.sock -v /tmp/.X11-unix:/tmp/.X11-unix --privileged --group-add root biodepot/bwb-umi
