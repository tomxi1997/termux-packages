#
# Magisk模块安装脚本
#
# 使用说明:
#
# 1. 将文件放入系统文件夹(删除placeholder文件)
# 2. 在module.prop中填写您的模块信息
# 3. 在此文件中配置和调整
# 4. 如果需要开机执行脚本，请将其添加到post-fs-data.sh或service.sh
# 5. 将其他或修改的系统属性添加到system.prop
#
######################################
#
# 安装框架将导出一些变量和函数。
# 您应该使用这些变量和函数来进行安装。
#
# !请不要使用任何Magisk的内部路径，因为它们不是公共API。
# !请不要在util_functions.sh中使用其他函数，因为它们也不是公共API。
# !不能保证非公共API在版本之间保持兼容性。
#
# 可用变量:
#
# MAGISK_VER (string):当前已安装Magisk的版本的字符串(字符串形式的Magisk版本)
# MAGISK_VER_CODE (int):当前已安装Magisk的版本的代码(整型变量形式的Magisk版本)
# BOOTMODE (bool):如果模块当前安装在Magisk Manager中，则为true。
# MODPATH (path):你的模块应该被安装到的路径
# TMPDIR (path):一个你可以临时存储文件的路径
# ZIPFILE (path):模块的安装包（zip）的路径
# ARCH (string): 设备的体系结构。其值为arm、arm64、x86、x64之一
# IS64BIT (bool):如果$ARCH(上方的ARCH变量)为arm64或x64，则为true。
# API (int):设备的API级别（Android版本）
#
# 可用函数:
#
# ui_print <msg>
#     打印(print)<msg>到控制台
#     避免使用'echo'，因为它不会显示在第三方recovery的控制台中。
#
# abort <msg>
#     打印错误信息<msg>到控制台并终止安装
#     避免使用'exit'，因为它会跳过终止的清理步骤
#
##################################
#
# 如果您需要更多的自定义，并且希望自己做所有事情
# 请在custom.sh中标注SKIPUNZIP=1
# 以跳过提取操作并应用默认权限/上下文上下文步骤。
# 请注意，这样做后，您的custom.sh将负责自行安装所有内容。
SKIPUNZIP=0

# 如果您需要调用Magisk内部的busybox
# 请在custom.sh中标注ASH_STANDALONE=1
ASH_STANDALONE=1

######################################
# 安装设置
#
# 如果SKIPUNZIP=1你将可能会需要使用以下代码
# 当然，你也可以自定义安装脚本，需要时请删除#
# 将 $ZIPFILE 提取到 $MODPATH
#  ui_print "- 解压模块文件"
#  unzip -o "$ZIPFILE" -x 'META-INF/*' -d $MODPATH >&2
# 删除多余文件
# rm -rf \
# $MODPATH/system/placeholder $MODPATH/customize.sh \
# $MODPATH/*.md $MODPATH/.git* $MODPATH/LICENSE 2>/dev/null
#chmod a+x $MODPATH/bin/wget
#echo "Download lxc"
#mkdir -p /data/lxc
#$MODPATH/bin/wget -O - https://qiuqiu233.top/d/linux-deploy/lxc/lxcnew.tar.gz | tar -C /data/lxc -zx


ui_print " ";
ui_print " ";
ui_print " 此Magisk/kernelsu/apatch模块需要内核支持";
ui_print " 需重新编译内核开启运行lxc,docker的必要依赖，并对内核进行补丁操作";
ui_print " 可参考如下
https://gist.github.com/FreddieOliveira/efe850df7ff3951cb62d74bd770dce27

或我写的githubaction自动化构建
https://github.com/tomxi1997/LXC_KernelSU_Action
或wu17481748的https://github.com/wu17481748/LXC-DOCKER-KernelSU_Action
或手动
https://github.com/tomxi1997/lxc-docker-support-for-android

对于gki内核除上述配置/补丁外还需要如下补丁，不然会导致无限重启。
https://github.com/tomxi1997/Enable-LXC-Dockers-for-Android-GKI-kernel


";


ui_print " ";
ui_print " ";
ui_print "正在解压docker压缩文档,请耐心等待";
tar -C /data/ -xf $MODPATH/docker.tar.xz
mkdir -p /data/docker/tmp/
mv $MODPATH/*.zip /data/docker/tmp/
cp $MODPATH/load-*.sh /data/docker/tmp/

ui_print " ";
ui_print " ";
ui_print "设置docker权限 ";
set_perm_recursive /data/docker 0 0 0755 0755
set_perm_recursive /data/docker/tmp 0 0 0755 0755

ui_print " ";
ui_print " ";
ui_print "正在删除多余文件";
rm $MODPATH/docker.tar.xz 


ui_print "首先重启开机后查看 /sdcard/docker-deamon.log.确保已经启动。 推荐直接用nethunter terminal.否则请按如下方式使用";
ui_print " ";
ui_print "Docker使用方法,打开终端termux";
ui_print "在终端执行su然后即可执行docker命令"
ui_print "或在终端依次执行 su  然后执行 cd /data/docker 再然后执行source env.sh ";
ui_print "继而就可以执行各种docker命令，创建各种docker容器并管理 ";

ui_print "首先要刷入Docker core for android模块重启开机后查看/sdcard/docker-deamon.log.确保docker deamon已经启动，并能正常,拉取运行hello-world，如果这不行的话，参考docker corefor Android的编译内核说明
然后在刷此模块该包为额外导入包，需开机后确保docker deamon启动后打开nethunter terminal kali shell执行 busybox sh load-*.sh (load-*.sh换为具体的名称) 即可完成导入，执行一次即可在下次开机时会自动启动systemd容器。如果要其他终端则，比如termux，(load-*.sh换为具体的名称) 执行如下
su -c 'source /data/docker/env.sh && /data/docker/bin/busybox sh /data/docker/tmp/load-*.sh'
如需自定义请查看/data/docker/tmp/load-*.sh内容，按需修改";

ui_print "
此模块用法总结，内核支持docker/lxc，root管理器刷入并重启，
nethunter terminal授权，root shell执行(load-*.sh换为具体的名称)  '/data/docker/bin/busybox sh /data/docker/tmp/load-*.sh' ,,然后在重启一次手机，确保cron定时器工作
，ssh连接容ssh root@localhost -p xxxx 密码root ";


ui_print "
此模块的卸载，该模块只是复制导入作用，关于删除容器/镜像，使用docker cli执行操作，在nethunter-terminal中执行 docker -rm -f $容器名 ，docker -rmi $镜像名";



ui_print " ";
ui_print " ";
ui_print "刷入完成，重启设备使其生效";


#
# 权限设置
#

# 请注意，magisk模块目录中的所有文件/文件夹都有$MODPATH前缀-在所有文件/文件夹中保留此前缀
# 一些例子:
  
# 对于目录(包括文件):
# set_perm_recursive  <目录>                <所有者> <用户组> <目录权限> <文件权限> <上下文> (默认值是: u:object_r:system_file:s0)
  
# set_perm_recursive $MODPATH/system/lib 0 0 0755 0644
# set_perm_recursive $MODPATH/system/vendor/lib/soundfx 0 0 0755 0644

# 对于文件(不包括文件所在目录)
# set_perm  <文件名>                         <所有者> <用户组> <文件权限> <上下文> (默认值是: u:object_r:system_file:s0)
  
# set_perm $MODPATH/system/lib/libart.so 0 0 0644
# set_perm /data/local/tmp/file.txt 0 0 644



# 默认权限请勿删除
set_perm $MODPATH/service.sh 0 0 0755
set_perm $MODPATH/post-fs-data.sh 0 0 0755
set_perm_recursive /data/docker/tmp 0 0 0755 0755
set_perm_recursive $MODPATH/system/bin 0 0 0755 0755
set_perm_recursive $MODPATH/system/etc 0 0 0755 0644
set_perm_recursive $MODPATH/system/lib64 0 0 0755 0644
set_perm_recursive $MODPATH/system/lib 0 0 0755 0644

set_perm $MODPATH/system/bin/docker 0 0 0755 
