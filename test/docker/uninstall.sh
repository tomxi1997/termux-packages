#!/system/bin/sh

#kill docker deamon/containerd
PIDA=$(pgrep dockerd)
for i in $PIDA; do
     kill $i 2>/dev/null
done

PIDB=$(pgrep containerd)
for i in $PIDB; do
     kill $i 2>/dev/null
done

rm -rf /data/docker