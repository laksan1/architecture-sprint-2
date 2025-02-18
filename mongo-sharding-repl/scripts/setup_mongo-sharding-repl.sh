#!/bin/bash

# Логирование
log_file="setup_mongo_sharding.log"
touch $log_file

log_message() {
    echo "$(date "+%Y-%m-%d %H:%M:%S") - $1" | tee -a $log_file
}
