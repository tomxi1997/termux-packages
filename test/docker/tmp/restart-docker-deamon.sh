#!/bin/sh

# Define variables for paths
DOCKER_DIR="/data/docker"
LOG_FILE="/sdcard/docker-daemon.log"
DOCKER_BIN="$DOCKER_DIR/bin/dockerd"
CONTAINERD_DIR="$DOCKER_DIR/lib/docker/containerd/daemon/io.containerd.runtime.v2.task/moby"
RUN_DIR="$DOCKER_DIR/var/run"

# Create necessary directories
mkdir -p "$CONTAINERD_DIR"

# Remove old log 
rm "$LOG_FILE"


# Set permissions for the run directory
chmod -R 755 "$RUN_DIR"

# Remove stale PID file if it exists
if [ -f "$RUN_DIR/docker.pid" ]; then
    rm "$RUN_DIR/docker.pid"
fi

#stop docker-deamon
/data/docker/bin/busybox sh /data/docker/stop-docker-deamon.sh

# Start Docker daemon and log output
rm $LOG_FILE
nohup "$DOCKER_BIN" > "$LOG_FILE" 2>&1 &

# Check if the Docker daemon started successfully
if [ $? -eq 0 ]; then
    echo "Docker daemon started successfully. Logs are being written to $LOG_FILE."
else
    echo "Failed to start Docker daemon. Check the log file for details: $LOG_FILE."
    
    exit 1
fi