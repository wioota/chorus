#!/bin/bash
hostname=$1
dir=$2
echo "Running backup"
ssh $hostname "cd $dir && CHORUS_HOME=$dir ./chorus_control.sh backup -d backups"
echo "Running restore"
ssh $hostname "cd $dir && CHORUS_HOME=$dir ./chorus_control.sh restore backups/*.tar"
