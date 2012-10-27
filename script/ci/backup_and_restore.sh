#!/bin/bash
echo "Running backup"
chorus_control.sh backup -d backups
echo "Running restore"
chorus_control.sh restore backups/*.tar
