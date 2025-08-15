#!/system/bin/sh
MODDIR=${0%/*}
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 1
done
while [ ! -d "/sdcard/Android" ]; do
    sleep 1
done

sleep 20

export PATH=$PATH:/system/xbin:/system/bin:/data/docker/bin:/data/adb/magisk:/data/adb/ksu/bin:/data/adb/ap/bin

#如果可以挂在/分区为可读写，一般来说安卓10一下可以，安卓11以上都不行了
busybox mount -o remount,rw /

#启用binfmt，需要内核启用 CONFIG_BINFMT_MISC=y 对于docker还需加 -v /proc/sys/fs/binfmt_misc:/proc/sys/fs/binfmt_misc参数(或许不需要)，使其支持跨架构容器运行，比如x86容器
busybox mount binfmt_misc -t binfmt_misc /proc/sys/fs/binfmt_misc
echo 1 > /proc/sys/fs/binfmt_misc/status

#可运行如下指令以在Android上跑x64容器
#docker run --rm --privileged aptman/qus -s -- -p x86_64
#docker run --rm -t amd64/ubuntu uname -a

#取消binfmt注册
#docker run --rm --privileged aptman/qus -- -r


#挂载group层次
if ! mountpoint -q /sys/fs/cgroup; then
	busybox mount -t tmpfs -o mode=755,nodev,noexec,nosuid tmpfs /sys/fs/cgroup
fi

for cg in blkio cpu cpuacct cpuset devices freezer memory; do
	if [ ! -d "/sys/fs/cgroup/${cg}" ]; then
		mkdir -p "/sys/fs/cgroup/${cg}"
	fi

	if ! mountpoint -q "/sys/fs/cgroup/${cg}"; then
		busybox mount -t cgroup -o "${cg}" cgroup "/sys/fs/cgroup/${cg}" || true
	fi
done

#使其能运行systemd docker
mkdir -p /sys/fs/cgroup/systemd
busybox mount -t cgroup cgroup -o none,name=systemd /sys/fs/cgroup/systemd



#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
#安卓相关的
sleep 1
#禁用安卓的深浅打盹模式
su -c "dumpsys deviceidle disable"
sleep 1

# 防止系统挂起，即设置Android手机不进入休眠
echo "PowerManagerService.noSuspend" > /sys/power/wake_lock
#保持 cpu 唤醒：
echo lock_me > /sys/power/wake_lock
sleep 1

#Wi-Fi 进入节能模式表现为不能全速传输，延时高。
#关闭节能模式，不是所有安卓设备中都有iw命令，与安卓内核安卓版本有关，没有则该命令不生效
iw wlan0 set power_save off
sleep 1

#开机自动开启usb调试和usb安全模式
#settings put global adb_enabled 1
#setprop persist.security.adbinput 1

#开机自动开启本地和网络usb调试，调试端口为5555，按需启用
#sleep 20
#su -c stop adbd
#sleep 20
#su -c settings put global adb_enabled 1
#sleep 20
#su -c setprop service.adb.tcp.port 5555
#sleep 20
#su -c start adbd

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#





#设置docker运行环境
export PATH="/data/docker/bin:$PATH"
export LD_LIBRARY_PATH=/data/docker/lib:$LD_LIBRARY_PATH

#清理进程
mkdir -p /data/docker/lib/docker/containerd/daemon/io.containerd.runtime.v2.task/moby
rm /sdcard/docker-deamon.log
rm /data/docker/var/run/docker.pid

#kill docker deamon/containerd
PIDA=$(pgrep dockerd)
for i in $PIDA; do
     kill $i 2>/dev/null
done

PIDB=$(pgrep containerd)
for i in $PIDB; do
     kill $i 2>/dev/null
done

sleep 2
#启动docker daemon
#nohup /data/docker/bin/busybox sh /data/docker/bin/dockerd > /sdcard/docker-deamon.log 2>&1 &
/data/docker/bin/busybox sh /data/docker/bin/dockerd > /sdcard/docker-deamon.log 2>&1 &

sleep 15

#启动docker systemd ubuntu容器
#参考https://hub.docker.com/r/jrei/systemd-ubuntu/tags
#我参考我自己😁?
#https://www.coolapk.com/feed/51724792?shareKey=NDhlODI1MjRmYzc4NjdkNjcyODE~&shareUid=25509431&shareFrom=com.coolapk.market_15.1.1

#还可以进行套娃操作docker in docker
#还是我参考我自己😁? https://www.coolapk.com/feed/51844384?shareKey=ZWQ2NTBmOWE0ZDc5NjdkNjcyZWU~&shareUid=25509431&shareFrom=com.coolapk.market_15.1.1

#对于本二进制就加  -v /data/docker/var/run/docker.sock:/var/run/docker.sock 即可



#最终启动docker systemd ubuntu docker容器命令如下，就像lxc嵌套docker一样，总体但这是下dockek---systemd docker-----docker in docker这么个过程，拿它当稍复杂lxc用就可以了😁
#https://www.coolapk.com/feed/51768563?shareKey=YmZhODRhMGVjOWRkNjdkNjcyNGI~&shareUid=25509431&shareFrom=com.coolapk.market_15.1.1
#意思是在后台运行个使用主机网络，并docker启动时自启的，带特权的（直通宿主机root的），并将手机的/mnt映射(挂载）到容器的/mnt目录，
#挂载usb/usb串口的，带 systemd 的ubuntu 22.04容器。就这样解释吧。
#docker run -d --net host --restart=always --privileged -v /sys/fs/cgroup:/sys/fs/cgroup:ro -v /data/docker/var/run/docker.sock:/var/run/docker.sock -v /mnt:/mnt -v /dev/bus/usb:/dev/bus/usb --device=/dev/ttyUSB0 --name systemd-ubuntu jrei/systemd-ubuntu





#此处放要开机自启动的容器，可仿照下面方式写，
##sleep 2 
# /data/docker/bin/docker start xxxx
#echo "$(date '+%F %T') | 已启动xxxx" >> /sdcard/docker.log
rm /sdcard/docker.log


#以下为一键导入模块相关的
################Ubuntu##############
if [ -d "/data/adb/modules/ubuntu24" ]; then
         /data/docker/bin/docker start systemd-ubuntu24
         echo "$(date '+%F %T') | 已启动systemd-ubuntu24" >> /sdcard/docker.log
fi


sleep 2
if [ -d "/data/adb/modules/ubuntu22" ]; then
         /data/docker/bin/docker start systemd-ubuntu22
         echo "$(date '+%F %T') | 已启动systemd-ubuntu22" >> /sdcard/docker.log
fi


#sleep 2 
#/data/docker/bin/docker start systemd-ubuntu228
#echo "$(date '+%F %T') | 已启动systemd-ubuntu228" >> /sdcard/docker.log



sleep 2
if [ -d "/data/adb/modules/ubuntu20" ]; then
         /data/docker/bin/docker start systemd-ubuntu20
         echo "$(date '+%F %T') | 已启动systemd-ubuntu22" >> /sdcard/docker.log
fi



sleep 2
if [ -d "/data/adb/modules/ubuntu18" ]; then
         /data/docker/bin/docker start systemd-ubuntu18
         echo "$(date '+%F %T') | 已启动systemd-ubuntu18" >> /sdcard/docker.log
fi


################Debian##############

sleep 2
if [ -d "/data/adb/modules/debiansid" ]; then
         /data/docker/bin/docker start systemd-debiansid
         echo "$(date '+%F %T') | 已启动systemd-debiansid" >> /sdcard/docker.log
fi


sleep 2
if [ -d "/data/adb/modules/debian12" ]; then
         /data/docker/bin/docker start systemd-debian12
         echo "$(date '+%F %T') | 已启动systemd-debian12" >> /sdcard/docker.log
fi

sleep 2
if [ -d "/data/adb/modules/debian11" ]; then
         /data/docker/bin/docker start systemd-debian11
         echo "$(date '+%F %T') | 已启动systemd-debian11" >> /sdcard/docker.log
fi


sleep 2
if [ -d "/data/adb/modules/debian10" ]; then
         /data/docker/bin/docker start systemd-debian10
         echo "$(date '+%F %T') | 已启动systemd-debian10" >> /sdcard/docker.log
fi





# 这里的GATEWAY_IP即自己当前网络的网关ip或路由器的ip,用于解决lxc中docker桥接模式不可用问题
#docker联网可以不使用--net=host了, 可以直接使用默认的bridge模式的解决，docker直接映射端口
#有两类方法 法一，好像有时正常有时不正常。。默认注释
#export GATEWAY_IP=$(ip route |grep wlan0 |grep default |awk '{print $3}')
#ip route add default via $GATEWAY_IP dev wlan0
#ip rule add from all lookup main pref 30000

#法二,使用定时器，每隔10分钟执行一次，看150行后的内容 
#使docker的桥接模式可用(另一种方法，经测试正常(参考https://gist.github.com/FreddieOliveira/efe850df7ff3951cb62d74bd770dce27
#ndc network interface add local docker0
#ndc network route add local docker0 172.17.0.0/16
#ndc ipfwd enable docker
#ndc ipfwd add docker0 wlan0



#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
#            cron定时器，自动定时执行脚本的，一般的往/data/adb/modules/docker/cron/script/test.sh塞内容就可以，定时规则在/data/adb/modules/docker/cron/root

#36-41行和43-47执行的脚本是一样的，通过crron定时执行多次和只在启动后执行一次，自己依情况去试吧。。。已经将cron定时执行getwayip.sh取消，要启用去掉40行前面的#即可
#定时执行getwayip.sh已保证docker桥接模式可用

(
rm -rf /sdcard/getwayip.log /sdcard/check-container.log
#export PATH="/system/bin:/system/xbin:/vendor/bin:$(magisk --path)/.magisk/busybox:$PATH"
crond -c $MODDIR/cron
chmod -R 755 /data/adb/modules/docker/cron/script
#sh /data/adb/modules/docker/cron/script/getwayip.sh
sh /data/adb/modules/docker/cron/script/check-container.sh
)
