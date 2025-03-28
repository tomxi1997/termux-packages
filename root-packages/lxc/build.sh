TERMUX_PKG_HOMEPAGE=https://linuxcontainers.org/
TERMUX_PKG_DESCRIPTION="Linux Containers"
TERMUX_PKG_LICENSE="LGPL-2.1"
TERMUX_PKG_MAINTAINER="@termux"
# v3.1.0 is the last version confirmed to work.
# Do not update it unless you tested it on your device.
TERMUX_PKG_VERSION=1:3.1.0
TERMUX_PKG_REVISION=2
TERMUX_PKG_SRCURL=https://linuxcontainers.org/downloads/lxc/lxc-${TERMUX_PKG_VERSION:2}.tar.gz
TERMUX_PKG_SHA256=4d8772c25baeaea2c37a954902b88c05d1454c91c887cb6a0997258cfac3fdc5
TERMUX_PKG_AUTO_UPDATE=false
TERMUX_PKG_DEPENDS="gnupg, libcap, libseccomp, rsync, wget"
TERMUX_PKG_BREAKS="lxc-dev"
TERMUX_PKG_REPLACES="lxc-dev"

TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
--with-distro=termux
--with-init-script=sysvinit
--enable-static
--disable-shared
--with-runtime-path=/data/lxc3/var/run
--disable-apparmor
--disable-selinux
--disable-seccomp
--disable-capabilities
--disable-examples
--disable-gnutls
--with-pic
--with-log-path=/data/lxc3/log
--disable-werror
"

mkdir -p /data/data/com.termux/files/usr/lib/ && wget https://github.com/tomxi1997/termux-packages/releases/download/v1/liblxc.so && cp liblxc.so /data/data/com.termux/files/usr/lib/

termux_step_post_make_install() {
	# Simple helper script for mounting cgroups.
	install -Dm755 "$TERMUX_PKG_BUILDER_DIR"/lxc-setup-cgroups.sh \
		"$TERMUX_PREFIX"/bin/lxc-setup-cgroups
	sed -i "s|@TERMUX_PREFIX@|$TERMUX_PREFIX|" "$TERMUX_PREFIX"/bin/lxc-setup-cgroups
}
