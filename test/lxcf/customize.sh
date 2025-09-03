SKIPUNZIP=0
# 如果您需要调用Magisk内部的busybox
# 请在custom.sh中标注ASH_STANDALONE=1
ASH_STANDALONE=1
######################################
ui_print " LXC-5.0.3 for Android (android api_24";
ui_print " ";
ui_print "正在解压lxcf压缩文档,请耐心等待";
tar -C /data/ -xf $MODPATH/lxcf.tar.xz
mv $MODPATH/env.sh /data/lxcf/
mkdir -p /data/lxcf/tmp/

ui_print " ";
ui_print " ";
ui_print "设置cmd权限 ";
set_perm_recursive /data/lxcf 0 0 0755 0755
set_perm_recursive /data/lxcf/tmp 0 0 0755 0755

ui_print " ";
ui_print "正在删除多余文件";
rm $MODPATH/lxcf.tar.xz 

ui_print " ";
ui_print "刷入完成，重启设备使其生效";

# 默认权限请勿删除
set_perm $MODPATH/service.sh 0 0 0755
set_perm $MODPATH/post-fs-data.sh 0 0 0755
set_perm_recursive $MODPATH/system/bin 0 0 0755 0755
set_perm_recursive $MODPATH/system/etc 0 0 0755 0644
set_perm_recursive $MODPATH/system/lib64 0 0 0755 0644
set_perm_recursive $MODPATH/system/lib 0 0 0755 0644

