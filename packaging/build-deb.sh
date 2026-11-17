#!/usr/bin/env bash
# 由 GitHub Actions 调用：把 flutter build linux 的 bundle 装成 x64 deb
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
BUNDLE="build/linux/x64/release/bundle"
BIN="$BUNDLE/moumou"
[ -f "$BIN" ] || { echo "✗ 找不到 $BIN，先跑 flutter build linux --release"; exit 1; }

VER=$(grep '^version:' pubspec.yaml | head -1 | sed 's/.*version: *//; s/+.*//; s/[[:space:]]*$//')
REV="${VER}-linux5"
PKG="xiaomiao-player_${REV}_amd64"
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT

mkdir -p "$STAGE/DEBIAN" \
         "$STAGE/usr/lib/xiaomiao-player" \
         "$STAGE/usr/bin" \
         "$STAGE/usr/share/applications" \
         "$STAGE/usr/share/icons/hicolor/256x256/apps" \
         "$STAGE/usr/share/doc/xiaomiao-player"

cp -a "$BUNDLE/." "$STAGE/usr/lib/xiaomiao-player/"
cp packaging/wrapper.sh "$STAGE/usr/bin/xiaomiao-player"
chmod 755 "$STAGE/usr/bin/xiaomiao-player" "$STAGE/usr/lib/xiaomiao-player/moumou"
cp packaging/xiaomiao-player.desktop "$STAGE/usr/share/applications/"
cp packaging/copyright "$STAGE/usr/share/doc/xiaomiao-player/copyright"

# libjsoncpp 随包附带：构建机是 24.04（libjsoncpp.so.25），目标机 26.04 的源里
# 只有 libjsoncpp.so.26。写成 Depends 会在 26.04 上直接「不可满足」装不上；
# 只改包名又会启动时报 "libjsoncpp.so.25: cannot open shared object file"。
# 所以把构建机这份 .so 一起带进 bundle 的 lib/，由 /usr/bin/xiaomiao-player 的
# LD_LIBRARY_PATH 命中（wrapper 已设置），Debian 依赖里则不再列它。
# 它是 flutter_secure_storage_linux 的传递依赖，体积约 300 KB。
jsoncpp_found=0
for f in /usr/lib/x86_64-linux-gnu/libjsoncpp.so.25* /usr/lib64/libjsoncpp.so.25*; do
  [ -e "$f" ] || continue
  cp -a "$f" "$STAGE/usr/lib/xiaomiao-player/lib/"
  jsoncpp_found=1
done
[ "$jsoncpp_found" = 1 ] || { echo "✗ 构建机没有 libjsoncpp.so.25（libjsoncpp-dev 没装？）"; exit 1; }
echo "✓ 已附带 libjsoncpp: $(cd "$STAGE/usr/lib/xiaomiao-player/lib" && ls libjsoncpp.so.25* | tr '\n' ' ')"

# 图标：优先 Flutter 图标，其次 Android 的 xxxhdpi 启动图标
ICON=""
for c in assets/icon/app_icon.png \
         android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png \
         android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png; do
  [ -f "$c" ] && ICON="$c" && break
done
if [ -n "$ICON" ]; then
  cp "$ICON" "$STAGE/usr/share/icons/hicolor/256x256/apps/xiaomiao-player.png"
fi

sed "s/@VERSION@/$REV/" packaging/DEBIAN/control > "$STAGE/DEBIAN/control"
dpkg-deb --build "$STAGE" "$ROOT/${PKG}.deb"
echo "✓ ${PKG}.deb"
