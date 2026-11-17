#!/usr/bin/env bash
# 由 GitHub Actions 调用：把 flutter build linux 的 bundle 装成 x64 deb
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
BUNDLE="build/linux/x64/release/bundle"
BIN="$BUNDLE/moumou"
[ -f "$BIN" ] || { echo "✗ 找不到 $BIN，先跑 flutter build linux --release"; exit 1; }

VER=$(grep '^version:' pubspec.yaml | head -1 | sed 's/.*version: *//; s/+.*//; s/[[:space:]]*$//')
REV="${VER}-linux2"
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
