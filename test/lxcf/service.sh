#!/system/bin/sh
MODDIR=${0%/*}
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 1
done
while [ ! -d "/sdcard/Android" ]; do
    sleep 1
done

# 禁用安卓深浅打盹模式
su -c "dumpsys deviceidle disable"
su -c "dumpsys deviceidle whitelist +com.termux"  # 允许Termux后台运行

# 防止系统休眠（修复权限问题）
su -c "echo 'PowerManagerService.noSuspend' > /sys/power/wake_lock"
sleep 20

export PATH="/data/lxcf/bin:/data/adb/magisk:/data/adb/ksu/bin:/data/adb/ap/bin:/system/xbin:/system/bin:$PATH"
export LD_LIBRARY_PATH="/data/lxcf/lib:$LD_LIBRARY_PATH"

#如果可以挂在/分区为可读写，一般来说安卓10一下可以，安卓11以上都不行了
busybox mount -o remount,rw /


if ! mountpoint -q /sys/fs/cgroup; then
	mount -t tmpfs -o mode=755,nodev,noexec,nosuid tmpfs /sys/fs/cgroup
fi

for cg in blkio cpu cpuacct cpuset devices freezer memory; do
	if [ ! -d "/sys/fs/cgroup/${cg}" ]; then
		mkdir -p "/sys/fs/cgroup/${cg}"
	fi

	if ! mountpoint -q "/sys/fs/cgroup/${cg}"; then
		mount -t cgroup -o "${cg}" cgroup "/sys/fs/cgroup/${cg}" || true
	fi
done
. /data/lxcf/env.sh

/data/lxcf/etc/init.d/lxc-net start > /data/lxc/var/net.log

ip rule add from all iif lxcbr0 lookup $(ip rule list | grep "from all iif lo oif wlan0 lookup" | awk '{print $NF}')

sleep 5
#su -c "cd /data/lxcf && source env.sh && lxc-start -n u22 -d"

