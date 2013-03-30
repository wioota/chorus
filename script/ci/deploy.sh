#!/bin/bash

server=$1
if [ -z $server ]; then
    server=stage
fi

for file in greenplum-chorus-*.sh
do
  echo "Deploying $file"
  chmod +x $file
  rake deploy["$server","$file"]
  exit $?
done
