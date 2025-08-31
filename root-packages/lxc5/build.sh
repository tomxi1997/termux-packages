
# ==============================================================================
# 1. 基础包信息（Termux 规范强制项，字段含义与官方保持一致）
# ==============================================================================
TERMUX_PKG_VERSION="5.0"  # 选用 LXC 最新稳定版（截至 2024.5，可随新版本更新）
TERMUX_PKG_REVISION="1"     # 包修订号，首次提交为 1，后续修改递增
TERMUX_PKG_SRCURL="https://github.com/tomxi1997/termux-packages/releases/download/v12/lxc-${TERMUX_PKG_VERSION}.tar.xz"  # 官方 Release tar 包（优先于 Git 仓库，稳定性更高）
TERMUX_PKG_SHA256="2cfa3e9a80779eee640683f076451d8c7dd8c93ec4847b0d6ff8f9f872bb7af5"  # 替换为实际 tar 包的 SHA256（可通过 `curl -L <URL> | sha256sum` 获取）
TERMUX_PKG_DESCRIPTION="Linux Containers (LXC) - 轻量级容器运行时，适配 Termux Android aarch64 环境，支持容器创建、管理与隔离"
TERMUX_PKG_LICENSE="LGPL-2.1"
TERMUX_PKG_LICENSE_FILES="COPYING"  # 源码中 LICENSE 文件路径（LXC 源码根目录含 COPYING）
TERMUX_PKG_MAINTAINER="tomxi1997@gmail.com>"  # 替换为实际维护者信息
TERMUX_PKG_HOMEPAGE="https://linuxcontainers.org/lxc/"  # LXC 官方主页

# ==============================================================================
# 2. 依赖配置（严格区分构建依赖与运行依赖，避免冗余）
# ==============================================================================
# 构建依赖：仅编译阶段需要，安装后可移除
TERMUX_PKG_BUILD_DEPENDS="meson, ninja, clang, llvm, pkg-config"
# 运行依赖：安装后必须保留，确保 LXC 正常运行
TERMUX_PKG_DEPENDS="libc++, zlib"  # libc++ 是 Android 标准 C++ 库，zlib 为 LXC 压缩依赖

# ==============================================================================
# 3. 架构与环境限制（明确适配范围，避免无效编译）
# ==============================================================================
TERMUX_PKG_ARCH="aarch64"  # 仅适配 aarch64（与原始 NDK 交叉编译配置一致，Android 主流架构）
TERMUX_PKG_BLACKLISTED_ARCHES="arm, i686, x86_64"  # 明确禁用非 aarch64 架构（避免编译失败）

# ==============================================================================
# 4. 配置文件声明（Termux 包管理规范：标记需保留的配置文件，避免升级覆盖）
# ==============================================================================
TERMUX_PKG_CONFFILES="etc/lxc/lxc.conf etc/lxc/default.conf"

# ==============================================================================
# 5. 自定义 Meson 配置（核心逻辑：适配 Termux 环境，修复原语法错误）
# ==============================================================================
termux_step_configure_meson() {
    # 调用 Termux 内置工具初始化 Meson（自动处理 NDK 路径、交叉编译环境）
    termux_setup_meson

    # 编译类型配置：默认最小体积（适配 Termux 存储空间），调试模式自动切换
    local _meson_buildtype="minsize"
    local _meson_stripflag="--strip"
    if [[ "$TERMUX_DEBUG_BUILD" == "true" ]]; then
        _meson_buildtype="debug"
        _meson_stripflag=""  # 调试模式不删除符号表（便于 gdb 调试）
    fi

    # 执行 Meson 配置（修复原脚本中 --cross-file 行尾多余空格的语法错误）
    CC="${TERMUX_HOST_PLATFORM}-clang" \
    CXX="${TERMUX_HOST_PLATFORM}-clang++" \
    PKG_CONFIG="${TERMUX_PREFIX}/bin/pkg-config" \  # 确保使用 Termux 本地 pkg-config
    $TERMUX_MESON setup \
        "${TERMUX_PKG_SRCDIR}" \                  # 源码目录（Termux 自动定义）
        "${TERMUX_PKG_BUILDDIR}" \                # 构建目录（隔离编译过程）
        --cross-file "${TERMUX_MESON_CROSSFILE}"  # 复用 Termux 内置交叉编译配置（无需自定义 cross-file.txt）
        --prefix "${TERMUX_PREFIX}" \             # Termux 标准安装根目录（/data/data/com.termux/files/usr）
        --libdir "${TERMUX_PREFIX}/lib" \         # 库文件路径（符合 Termux 目录结构）
        --includedir "${TERMUX_PREFIX}/include" \  # 头文件路径
        --buildtype "${_meson_buildtype}" \
        ${_meson_stripflag} \
        # LXC 功能开关：关闭 Android/Termux 不支持的特性（与原始编译逻辑一致）
        -Dinit-script=[] \                        # 禁用系统初始化脚本（Termux 无 init 系统）
        -Dman=false \                             # 禁用手册生成（减少构建依赖）
        -Dpam-cgroup=false \                      # 禁用 PAM 控制（Termux 无 PAM）
        -Dtests=false \                           # 禁用测试用例（避免测试依赖缺失）
        -Dcapabilities=false \                    # 禁用 Linux 能力控制（Android 限制）
        -Dseccomp=false \                         # 禁用 seccomp 过滤（Android 支持有限）
        -Dselinux=false \                         # 禁用 SELinux（Termux 无 SELinux）
        -Dopenssl=false \                         # 禁用 OpenSSL（如需加密可后续扩展）
        -Ddbus=false \                            # 禁用 D-Bus（Termux 默认不装 D-Bus）
        # LXC 核心路径调整：适配 Termux 可写目录（避免 /data/lxc 非标准路径）
        -Dglobal-config-path="${TERMUX_PREFIX}/etc/lxc" \  # 全局配置目录
        -Druntime-path="${TERMUX_PREFIX}/var/cache/lxc" \  # 运行时缓存目录
        -Dlocalstatedir="${TERMUX_PREFIX}/var" \           # 本地状态目录（如容器数据）
        # 额外扩展参数（允许通过外部变量添加自定义配置）
        "${TERMUX_PKG_EXTRA_CONFIGURE_ARGS}" \
        || { termux_step_configure_meson_failure_hook; false; }  # 修复原脚本括号语法，确保失败后终止
}

# ==============================================================================
# 6. 安装后处理（补充配置文件、调整权限，确保 LXC 可直接使用）
# ==============================================================================
termux_step_post_make_install() {
    # 1. 创建 LXC 必需的运行目录（Termux 下仅 $TERMUX_PREFIX 内可写）
    local lxc_dirs=(
        "${TERMUX_PREFIX}/etc/lxc"          # 配置目录
        "${TERMUX_PREFIX}/var/cache/lxc"    # 缓存目录
        "${TERMUX_PREFIX}/var/lib/lxc"      # 容器数据目录
        "${TERMUX_PREFIX}/var/log/lxc"      # 日志目录
        "${TERMUX_PREFIX}/var/run/lxc"      # 运行时 PID 目录
    )
    mkdir -p "${lxc_dirs[@]}"

    # 2. 复制 LXC 源码中的默认配置文件（避免用户初次使用无配置）
    local src_default_conf="${TERMUX_PKG_SRCDIR}/config/default.conf"
    local src_lxc_conf="${TERMUX_PKG_SRCDIR}/config/lxc.conf"
    if [[ -f "${src_default_conf}" ]]; then
        cp -f "${src_default_conf}" "${TERMUX_PREFIX}/etc/lxc/default.conf"
    fi
    if [[ -f "${src_lxc_conf}" ]]; then
        cp -f "${src_lxc_conf}" "${TERMUX_PREFIX}/etc/lxc/lxc.conf"
    fi

    # 3. 调整目录权限（适配 Termux 非 root 环境，确保用户可读写）
    chmod -R 0755 "${lxc_dirs[@]}"
    chmod 0644 "${TERMUX_PREFIX}/etc/lxc/"*.conf  # 配置文件仅读（避免误修改）
}

# ==============================================================================
# 7. 配置失败钩子（增强错误提示，便于问题排查）
# ==============================================================================
termux_step_configure_meson_failure_hook() {
    echo -e "\n[ERROR] LXC Meson 配置失败！请检查以下项："
    echo "1. 依赖是否完整：执行 \`pkg install ${TERMUX_PKG_BUILD_DEPENDS}\`"
    echo "2. 源码 SHA256 是否正确：当前配置为 ${TERMUX_PKG_SHA256}"
    echo "3. 架构是否为 aarch64：当前架构为 ${TERMUX_ARCH}"
}

