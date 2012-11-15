#!/bin/bash

set -e

for file in greenplum-chorus-*.sh
do
    echo "Deploying $file"
    chmod +x $file
    rake deploy["load_test","$file"]
    break
done

rake bulk_data:generate_fake_users["load-test-users.csv",200]
 #setup_load_test["load-test","load-test-users.csv"]
