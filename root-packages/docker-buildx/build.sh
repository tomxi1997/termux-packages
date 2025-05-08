TERMUX_PKG_HOMEPAGE=https://github.com/docker/buildx
TERMUX_PKG_DESCRIPTION="Docker CLI plugin for extended build capabilities with BuildKit Resources."
TERMUX_PKG_LICENSE="Apache-2.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="0.23.0"
TERMUX_PKG_SRCURL="https://github.com/docker/buildx/archive/v${TERMUX_PKG_VERSION}.tar.gz"
TERMUX_PKG_AUTO_UPDATE=true
TERMUX_PKG_DEPENDS=docker

termux_step_make() {
	termux_setup_golang
	export GOPATH=$TERMUX_PKG_BUILDDIR
	bash ${TERMUX_SCRIPTDIR}/scripts/fix_rutime.sh $TERMUX_PKG_SRCDIR
	cd $TERMUX_PKG_SRCDIR
	mkdir bin/
	if ! [ -z "$GOOS" ];then export GOOS=android;fi
	go build -o bin/docker-buildx -ldflags="-s -w -X github.com/docker/buildx/version.Version=${TERMUX_PKG_VERSION}" ./cmd/buildx
}

termux_step_make_install() {
	install -Dm755 -t "${TERMUX_PREFIX}"/libexec/docker/cli-plugins "${TERMUX_PKG_SRCDIR}"/bin/docker-buildx
}
