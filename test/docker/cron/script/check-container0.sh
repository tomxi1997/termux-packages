#!/bin/sh
#保持唤醒
echo lock_me > /sys/power/wake_lock

#该脚本会在每次打开nethunter terminal新会话时执行(已禁用，详细见/data/docker/kali.sh，用于每次快速启动docker-demon/docker容器
LOG=/sdcard/check-container.log
echo "------------------------------------------------------------"  >> $LOG

sleep 150
#添加延时，当有外接usb设备（比如机械硬盘时，让其有充足时间被安卓系统识别到，以便docker容器使用-v参数挂入时能被容器正确识别读取）


#容器名字
NAME=systemd-ubuntu24
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
        echo "$(date): Container '$NAME' is already running." >> $LOG
        echo "$(date): Docker bridge net, Starting it now..."  >> $LOG
        busybox sh /data/docker/bridge.sh
        return 0
    else
        echo "$(date): Container '$NAME' is not running. Starting it now..."  >> $LOG
        docker start $NAME
        sleep 2
        echo "$(date): Docker bridge net, Starting it now..."  >> $LOG
        busybox sh /data/docker/bridge.sh
        return 1
    fi
}

# Main loop
while true; do
    if ! check_dockerd; then
        echo "$(date): dockerd is not running. Executing /data/docker/restart-docker-deamon.sh..."  >> $LOG
        busybox sh /data/docker/restart-docker-deamon.sh
        sleep 5  # Wait for the daemon to start
        check_container
    else
        echo "$(date): dockerd is running. Checking container status..."  >> $LOG
        check_container
        break  # Exit the loop if dockerd is running
    fi
    sleep 60 # Sleep for 60 seconds before checking again
done