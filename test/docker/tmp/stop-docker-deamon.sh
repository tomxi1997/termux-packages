#!/bin/sh
#kill docker deamon/containerd
PIDA=$(pgrep dockerd)
for i in $PIDA; do
     echo "已停止dockerd,进程号为$i"
     kill $i 2>/dev/null
done

PIDB=$(pgrep containerd)
for i in $PIDB; do
     echo "已停止containerd,进程号为$i"
     kill $i 2>/dev/null
done