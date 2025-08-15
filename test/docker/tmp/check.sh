#!/bin/sh
#该脚本会在每次打开nethunter terminal新会话时执行(已禁用，详细见/data/docker/kali.sh，用于每次快速启动docker-demon/docker容器


#容器名字
NAME=systemd-ubuntu22

#检查docker是否已经启动，如果没启动则执行busybox sh /data/docker/start-docker-deamon.sh，如果docker启动则检查systemd-ubuntu22是否启动，没启动则docker start systemd-ubuntu22，并启动桥接模式修复脚本
export PATH="/data/docker/bin:$PATH"
export LD_LIBRARY_PATH="/data/docker/lib:$LD_LIBRARY_PATH"

# Function to check if dockerd is running
check_dockerd() {
    pgrep -x "dockerd" > /dev/null
    return $?  # Return the exit status of pgrep
}

# Function to check if the container is running
check_container() {
    if [ "$(docker ps -q -f name=$NAME)" ]; then
        echo "$(date): Container '$NAME' is already running."
        return 0
    else
        echo "$(date): Container '$NAME' is not running. Starting it now..."
        docker start $NAME
        echo "$(date): Docker bridge net, Starting it now..."
        busybox sh /data/docker/bridge.sh
        return 1
    fi
}

# Main loop
while true; do
    if ! check_dockerd; then
        echo "$(date): dockerd is not running. Executing /data/docker/start-docker-deamon.sh..."
        busybox sh /data/docker/start-docker-deamon.sh
        sleep 5  # Wait for the daemon to start
        check_container
    else
        echo "$(date): dockerd is running. Checking container status..."
        check_container
        break  # Exit the loop if dockerd is running
    fi
    sleep 5 # Sleep for 60 seconds before checking again
done