#!/bin/sh
# 保证从任意工作目录启动都能找到 bundle 内的 .so 与 flutter_assets
DIR=/usr/lib/xiaomiao-player
export LD_LIBRARY_PATH="$DIR/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
# GTK 会按会话自动选 X11 / Wayland；如需强制 Wayland，取消下一行注释：
# export GDK_BACKEND=wayland
cd "$DIR" || exit 1
exec "$DIR/moumou" "$@"
