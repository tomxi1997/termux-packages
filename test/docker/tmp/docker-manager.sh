#!/bin/sh
# Docker 服务管理脚本（支持启动/停止）
# 版本：1.0

# ==============================================
# 配置区域 - 根据实际环境调整
# ==============================================
DOCKER_DIR="/data/docker"
LOG_FILE="/sdcard/docker-daemon.log"
DOCKER_BIN="${DOCKER_DIR}/bin/dockerd"
CONTAINERD_DIR="${DOCKER_DIR}/lib/docker/containerd/daemon/io.containerd.runtime.v2.task/moby"
RUN_DIR="${DOCKER_DIR}/var/run"
BUSYBOX_BIN="${DOCKER_DIR}/bin/busybox"  
# ==============================================

# 日志输出函数（带时间戳）
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# 检查命令是否存在
check_command() {
    if ! command -v "$1" &> /dev/null; then
        log "错误：未找到命令 $1，请检查路径配置"
        exit 1
    fi
}

# 停止Docker相关进程
stop_docker() {
    log "开始停止Docker服务..."
    
    # 停止dockerd进程
    local pids=$(pgrep dockerd)
    if [ -n "$pids" ]; then
        for pid in $pids; do
            log "停止dockerd进程（PID: $pid）"
            kill "$pid" &> /dev/null
            # 等待进程终止
            sleep 2
            if ps -p "$pid" &> /dev/null; then
                log "强制终止未退出的dockerd进程（PID: $pid）"
                kill -9 "$pid" &> /dev/null
            fi
        done
    else
        log "未检测到运行中的dockerd进程"
    fi

    # 停止containerd进程
    pids=$(pgrep containerd)
    if [ -n "$pids" ]; then
        for pid in $pids; do
            log "停止containerd进程（PID: $pid）"
            kill "$pid" &> /dev/null
            sleep 2
            if ps -p "$pid" &> /dev/null; then
                log "强制终止未退出的containerd进程（PID: $pid）"
                kill -9 "$pid" &> /dev/null
            fi
        done
    else
        log "未检测到运行中的containerd进程"
    fi

    log "Docker服务停止完成"
}

# 启动Docker服务
start_docker() {
    log "开始启动Docker服务..."

    # 前置检查
    if [ ! -f "$DOCKER_BIN" ]; then
        log "错误：Docker二进制文件不存在（$DOCKER_BIN）"
        exit 1
    fi

    # 创建必要目录
    log "初始化工作目录..."
    mkdir -p "$CONTAINERD_DIR" "$RUN_DIR"
    if [ $? -ne 0 ]; then
        log "错误：创建目录失败，请检查权限"
        exit 1
    fi

    # 清理旧文件
    log "清理残留文件..."
    rm -f "$LOG_FILE"  # 移除旧日志（避免累积过大）
    rm -f "${RUN_DIR}/docker.pid"  # 清理残留PID文件

    # 设置目录权限
    chmod -R 755 "$RUN_DIR"
    if [ $? -ne 0 ]; then
        log "警告：无法设置目录权限（$RUN_DIR），可能影响运行"
    fi

    # 启动Docker daemon
    log "启动dockerd守护进程..."
    nohup "$DOCKER_BIN" > "$LOG_FILE" 2>&1 &
    local daemon_pid=$!

    # 等待启动（最多10秒）
    log "等待服务启动..."
    for i in $(seq 1 10); do
        if ps -p "$daemon_pid" &> /dev/null; then
            sleep 1
        else
            break
        fi
    done

    # 验证启动结果
    if ps -p "$daemon_pid" &> /dev/null; then
        log "Docker服务启动成功！日志路径：$LOG_FILE"
        log "dockerd进程PID: $daemon_pid"
    else
        log "错误：Docker服务启动失败！请查看日志：$LOG_FILE"
        exit 1
    fi
}

# 主逻辑 - 根据参数执行对应操作
case "$1" in
    start)
        # 启动前先停止残留进程
        stop_docker
        start_docker
        ;;
    stop)
        stop_docker
        ;;
    restart)
        stop_docker
        start_docker
        ;;
    *)
        echo "用法：$0 [start|stop|restart]"
        echo "  start   - 启动Docker服务"
        echo "  stop    - 停止Docker服务"
        echo "  restart - 重启Docker服务"
        exit 1
        ;;
esac

exit 0
