#!/bin/sh
# Version: 1.0.2

# export path for android bins/tools
export PATH=/data/docker/bin:/data/data/com.termux/files/usr/bin:/data/data/com.offsec.nhterm/files/home/.nhterm/script:/data/data/com.offsec.nhterm/files/usr/bin:/data/data/com.offsec.nhterm/files/usr/sbin:/sbin:/system/bin:/system/xbin:/apex/com.android.runtime/bin:/apex/com.android.art/bin:/odm/bin:/vendor/bin:.

export DOCKER_HOST="unix:///data/docker/var/run/docker.sock"

export LD_LIBRARY_PATH=/data/docker/lib:/data/data/com.termux/files/usr/lib:$LD_LIBRARY_PATH


# Get the path to the 'su' command
SU1=$(which su)

# Construct the command to run as another user
SU2="$SU1 -c"

# Clear out old view
clear
$SU2 mkdir -p /data/docker/tmp
# Change to the desired directory and execute the command
# Ensure that the command is properly quoted
$SU2 "/data/data/com.offsec.nhterm/files/usr/bin/bash -c 'cd /data/docker/tmp; exec bash'"

#$SU2 /data/docker/check.sh