SKIPUNZIP=0
# 如果您需要调用Magisk内部的busybox
# 请在custom.sh中标注ASH_STANDALONE=1
ASH_STANDALONE=1
######################################
ui_print " The necessary dependencies for running LXC to create containers (android api_24）";
ui_print " ";
ui_print "首先去下载https://github.com/Container-On-Android/lxc/releases模块刷入，在刷此模块即可";
ui_print "正在解压lxcf压缩文档,请耐心等待";
set_perm_recursive $MODPATH 0 0 0755 0755

tar -C /data/ -xf $MODPATH/share.tar.xz

chmod 755 -R /data/share

for i in tar wget getopt; do
      mv /data/share/$i /data/share/$i-bak
done

ui_print " ";
ui_print " ";
ui_print "安装busybox到/data/share/bin ";
export PATH="/data/share/bin:/data/share/libexec:$PATH"
export LD_LIBRARY_PATH="/data/share/lib:$LD_LIBRARY_PATH"

/data/share/bin/busybox --install -s /data/share/bin
for i2 in tar wget getopt; do
      rm /data/share/$i2
done

for i3 in tar wget getopt; do
      mv /data/share/$i3-bak /data/share/$i3
done

ui_print " ";
ui_print "正在删除多余文件";
rm $MODPATH/*.tar.xz 


ui_print " ";
ui_print "刷入完成，重启设备使其生效";

