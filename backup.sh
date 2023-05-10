#!/bin/bash

# Set variables for directory paths and file names
home_dir="/home/mohit"
cb_backup_dir="/home/mohit/backup/cb"
ib_backup_dir="/home/mohit/backup/ib"
log_file="/home/mohit/backup/backup.log"

timestamp=$(date +"%Y%m%d_%H%M%S")
backup_path="/home/mohit/backup"
cb_bool=true

mkdir -p "$cb_backup_dir"
mkdir -p "$ib_backup_dir"
cb_count=1
ib_count=1



function log_message {
  timestamp=$(date +"%a %d %b %Y %r %Z")
  echo "$timestamp $1" >> "$backup_path/backup.log"
}

# Function to create a complete backup of all .txt files in the directory tree
function create_complete_backup() {
    cb_backup_prefix="cb2000$cb_count"
    cb_backup_name="$cb_backup_prefix.tar"
    find "$home_dir" -type f -name "*.txt" -print0 | tar -cvf "$cb_backup_dir/$cb_backup_name" --null -T -
  log_message "$cb_backup_name was created"
  ((cb_count++))
  cb_bool=true
}

# Function to create an incremental backup of newly created or modified .txt files
function create_incremental_backup() {
    ib_backup_prefix="ib1000$ib_count"
    ib_backup_name="$ib_backup_prefix.tar"
    if $cb_bool; then
        txt_files=$(find "$home_dir" -type f -name "*.txt" -newer $last_complete_backup)
    else
        txt_files=$(find "$home_dir" -type f -name "*.txt" -newer $last_incremental_backup)
    fi
    cb_bool=false

    

    if [[ -z $txt_files ]]; then
        timestamp=$(date +"%a %d %b %Y %r %Z")
        echo "$timestamp: No new or modified .txt files found" >> "$log_file"    
    else
        timestamp=$(date +"%a %d %b %Y %r %Z")
        tar -cf "$ib_backup_dir/$ib_backup_name" $txt_files
        echo "$timestamp $ib_backup_name was created" >> $log_file
        ((ib_count++))
    fi
    
}

# Initialize variables for first run
last_complete_backup=""
last_incremental_backup=""

# Continuous loop for backups
while true; do
    create_complete_backup

    # Wait for 2 minutes
    sleep 2m

    # Set last complete backup for incremental backups
    last_complete_backup="$cb_backup_dir/$(ls -t $cb_backup_dir | head -n1)"

    create_incremental_backup

    # Wait for 2 minutes
    sleep 2m

    # Set last incremental backup for subsequent incremental backups
    last_incremental_backup="$ib_backup_dir/$(ls -t $ib_backup_dir | head -n1)"

    create_incremental_backup

    # Wait for 2 minutes
    sleep 2m

    last_incremental_backup="$ib_backup_dir/$(ls -t $ib_backup_dir | head -n1)"

    create_incremental_backup

    # Wait for 2 minutes
    sleep 2m
    
done
