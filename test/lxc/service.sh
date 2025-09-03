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

export PATH="/data/lxc/bin:/data/adb/magisk:/data/adb/ksu/bin:/data/adb/ap/bin:/system/xbin:/system/bin:$PATH"
export LD_LIBRARY_PATH="/data/lxc/lib:$LD_LIBRARY_PATH"

#如果可以挂在/分区为可读写，一般来说安卓10一下可以，安卓11以上都不行了
busybox mount -o remount,rw /



#此处写自定义的脚本。。。。。。





#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
#            cron定时器，自动定时执行脚本的，一般的往/data/adb/modules/docker/cron/script/test.sh塞内容就可以，定时规则在/data/adb/modules/docker/cron/root

#36-41行和43-47执行的脚本是一样的，通过crron定时执行多次和只在启动后执行一次，自己依情况去试吧。。。已经将cron定时执行getwayip.sh取消，要启用去掉40行前面的#即可
#定时执行getwayip.sh已保证docker桥接模式可用

(
rm -rf /sdcard/getwayip.log /sdcard/check-container.log
#export PATH="/system/bin:/system/xbin:/vendor/bin:$(magisk --path)/.magisk/busybox:$PATH"
crond -c $MODDIR/cron
chmod -R 755 /data/adb/modules/cmd/cron/script
#sh /data/adb/modules/docker/cron/script/getwayip.sh
sh /data/adb/modules/cmd/cron/script/check-container.sh
)
