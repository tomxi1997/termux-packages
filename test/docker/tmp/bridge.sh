#!/bin/sh
#使docker的桥接模式可用，如果桥接模式不正常可执行一下参考https://gist.github.com/FreddieOliveira/efe850df7ff3951cb62d74bd770dce27
ndc network interface add local docker0
ndc network route add local docker0 172.17.0.0/16
ndc ipfwd enable docker
ndc ipfwd add docker0 wlan0