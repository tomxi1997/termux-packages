#!/bin/sh
#保持唤醒
echo lock_me > /sys/power/wake_lock

#该脚本会在每次打开nethunter terminal新会话时执行(已禁用，详细见/data/docker/kali.sh，用于每次快速启动docker-demon/docker容器
LOG=/sdcard/check-container.log
echo "------------------------------------------------------------"  >> $LOG

sleep 150
export PATH="/data/lxc/bin:$PATH"
export LD_LIBRARY_PATH="/data/lxc/lib:$LD_LIBRARY_PATH"


