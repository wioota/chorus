#!/bin/bash
hostname = $1
echo "Running backup"
ssh $hostname chorus_control.sh backup -d backups
echo "Running restore"
ssh $hostname chorus_control.sh restore backups/*.tar
