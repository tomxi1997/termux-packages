#!/bin/bash

# 定义解压目录（原脚本中的A目录）
EXTRACT_DIR="./A"
# 定义脚本生成目录（原脚本中的B目录）
SCRIPT_DIR="./A/system/bin"

# 第一部分：解压所有.deb文件到指定目录
for FILE in *.deb; do
    if [ -f "$FILE" ]; then
        # 创建解压目录
        mkdir -p "$EXTRACT_DIR"
        # 解压.deb文件
        dpkg -x "$FILE" "$EXTRACT_DIR"
        echo "已解压: $FILE 到目录: $EXTRACT_DIR"
        cd "$EXTRACT_DIR"/data
        echo "android lxcf二进制压缩包，并解压到$EXTRACT_DIR"
        wget https://github.com/tomxi1997/lxcf/releases/download/test1/lxcf-ndk-api26-release.tar.xz
        tar -xvf lxcf-ndk-api26-release.tar.xz
        rm *.xz 
        cd ../..
        echo "---------------------------------------"
    fi
done


# 第二部分：处理解压后的数据，生成脚本文件
for FILES in "$EXTRACT_DIR/data/lxcf/bin/"*; do
    if [ -f "$FILES" ]; then
        # 获取原始bin文件的基础名
        B_FILENAME=$(basename "$FILES")
	    B_FILENAME2=$(basename "$FILES")-bin
        # 创建脚本存放目录
        mkdir -p "$SCRIPT_DIR"
        # 生成脚本内容（首次创建用>，后续追加用>>）
        
        echo "#!/system/bin/sh" > "$SCRIPT_DIR/$B_FILENAME2"
        echo 'export PATH="/data/lxcf/bin:/data/lxcf/libexec:$PATH"' >> "$SCRIPT_DIR/$B_FILENAME2"
        echo 'export LD_LIBRARY_PATH="/data/lxcf/lib:$LD_LIBRARY_PATH"' >> "$SCRIPT_DIR/$B_FILENAME2"
        #echo "cd /data/lxcf" >> "$SCRIPT_DIR/$B_FILENAME"
        echo "/data/lxcf/bin/$B_FILENAME \$@" >> "$SCRIPT_DIR/$B_FILENAME2"
        
        echo "已生成脚本: $B_FILENAME 到目录: $SCRIPT_DIR"
        echo "---------------------------------------"
    fi
done

cd ./A/data
XZ_OPT="-9" tar -cJf lxcf.tar.xz lxcf
cd ../..


