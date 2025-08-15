使用方法
1..重新编译安卓内核以支持docker
https://gist.github.com/FreddieOliveira/efe850df7ff3951cb62d74bd770dce27

我搞的
https://github.com/tomxi1997/LXC_KernelSU_Action
或wu17481748的https://github.com/wu17481748/LXC-DOCKER-KernelSU_Action
或手动
https://github.com/tomxi1997/lxc-docker-support-for-android

对于gki内核除上述配置/补丁外还需要如下补丁，不然会导致无限重启。
https://github.com/tomxi1997/Enable-LXC-Dockers-for-Android-GKI-kernel





2..刷入模块，重启授予nethunter terminal root权限
可以装下面板，由于与linux上的unix嵌套字位置不一样 本二进制位置/data/docker/var/run/docker.sock ，标准linux位置 /var/run/docker.sock 。面板中删除命令不起作用，建议使用docker cli.，尽量使用debian类容器，桥接模式正常，而其他的比如青龙面板的alpine容器，端口映射不正常，debian qinglong是正常的。如果桥接模式有问题，请尝试 /data/docker/bin/busybox sh /data/docker/bridge.sh，注意docker的 --restart=always 参数不要加，会导致magisk模块无法启动docker(随机性启动失败。。。，所以不要加 --restart=always，正确做法是要开机自启容器，在在/data/adb/modules/docker/service.sh加入sleep 2 && /data/docker/bin/docker start xxxx

只能说用来查看下，停止重启啥的，很多都是废的(非标准linux环境)，更多通过docker cli来操作。不然出问题，在哪都找不到。。。
面板1
https://github.com/donknap/dpanel
docker run -d --name dpanel \
 -p 80:80 -p 443:443 -p 8807:8080 -e APP_NAME=dpanel \
 -v /data/docker/var/run/docker.sock:/var/run/docker.sock -v /data/docker/tmp/dpanel:/dpanel \
 dpanel/dpanel:latest 
 访问
http://127.0.0.1:8807

面板2
docker run --name fastos -p 8081:8081 -p 8082:8082 -d \
-v /data/docker/var/run/docker.sock:/var/run/docker.sock -v /data/docjer/tmp/etc/docker/:/etc/docker/ \
-v /data/docker/tmp/root/data:/fast/data -e FAST_STORE=http://dockernb.com:8300  wangbinxingkong/fast:latest

然后在/data/adb/modules/docker/service.sh加入sleep 2 && /data/docker/bin/docker start dpanel
然后在/data/adb/modules/docker/service.sh加入sleep 2 && /data/docker/bin/docker start fastos




如需使用systemd容器可参考https://hub.docker.com/u/jrei，建议使用debian系
docker run -d --name systemd-fedora --privileged -v /sys/fs/cgroup:/sys/fs/cgroup:ro jrei/systemd-fedora (在我机子上测试，更新软件导致重启，不建议使用
或
(推荐
docker run -d --name systemd-ubuntu --privileged -v /sys/fs/cgroup:/sys/fs/cgroup:ro jrei/systemd-ubuntu
或
(推荐
docker run -d --name systemd-debian --privileged -v /sys/fs/cgroup:/sys/fs/cgroup:ro jrei/systemd-debian

推荐
docker run -d --net host --privileged -v /sys/fs/cgroup:/sys/fs/cgroup:ro -v /mnt:/mnt -v /dev/bus/usb:/dev/bus/usb --device=/dev/ttyUSB0 --name systemd-ubuntu jrei/systemd-ubuntu

docker exec -it systemd-ubuntu sh

然后就装下openssh-server
配置下，systemd开机自启下 systemctl enable ssh 
在/data/adb/modules/docker/service.sh加入
/data/docker/bin/docker start systemd-ubuntu
开机自启的systemd docker容器就完成了，使用ssh连接即可使用了



2025.5.1
重新添加docker compose,直接su后即可调用
在ubuntu镜像中添加/mnt/目录下加入 a,b,c,d, sdcard,data目录用作挂载安卓的外接硬盘盘符，目录。



2025.4.1
v5版本
修复随机无法启动docker deamon 错误
添加一键启动docker-demon/docker容器脚本/data/docker/check.sh
添加定时器每隔10分钟执行，桥接网络修复脚本
桥接网络日志为/sdcardl/docker-bridge.log
容器启动日志为/sdcarf/docker.log
docker-deamon日志为/sdcard/docker-daemon.log
一些细节修改




2025.3.25
修复xxx.so太小错误
修改桥接模式的修复脚本在docker启动后，确保桥接模式的正常
修复无法/data/docker/kali.sh中的无法创建/data/docker/tmp目录问题


2025 3.17 21.58
v3.1
修复docker的桥接模式不可用问题
添加libblkid
一些细节修改


2025.3.17
重大更新
0.添加termux环境变量，使其能在nethunter terminal中能使用termux的各种命令，前提是已经安装termux，这属于是回归本源了
1.添加nano支持，在nethunter terminal中使用
https://github.com/Magisk-Modules-Repo/nano-ndk
2.添加忘了的docker-init
3.修复/data/docker/lib/docker/containerd/daemon/io.containerd.runtime.v2.task/moby不存在错误









源码
https://github.com/tomxi1997/termux-packages

我构建好的action deb包
runc 
https://github.com/tomxi1997/termux-packages/actions/runs/13882483011

containerd docker docker-compose 
https://github.com/tomxi1997/termux-packages/actions/runs/13882222963


docker依赖的库resolv-conf libandroid-support libaio lvm2 readline
https://github.com/tomxi1997/termux-packages/actions/runs/13882225844


如何编译?
需要构建如下包，直接用termux官方的action构建如下包 ，
containerd docker runc docker-compose 

resolv-conf libandroid-support libaio lvm2 readline

重点说下docker依赖于containerd, libdevmapper, resolv-conf，而libdevmapper（lvm2）依赖于libaio, libandroid-support, libblkid, readline，
将上面的这些现构建出来deb包全部解压到/data/docker，还需要调整有些库路径或已知相关的/data/data/com.termux/files/usr全部换为/data/docker 的.,就可以了Android docker 下面的没构建了，我讲上面这些搞了测试了docker可以跑了。
而libblkid（util-linux）依赖于。。。。。。libcap-ng, libsmartcols, ncurses, zlib, libandroid-glob
搞得头大。。依赖死循环


好有就tini
在termux中编译tini，将静态构建的tini重命名为docker-init，放到/data/docker/bin
https://github.com/tomxi1997/Termux-Docker-android


全部修改打包基本就这样了。写好修改启动脚本。或参考该目录下打包好的。


3。关于nethunter terminal的执行脚本预加载内容为
sh /data/docker/kali.sh

预工作目录在/data/docker/tmp

所以只要修改kali.sh内容即可，修改。。。。


完