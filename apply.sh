#!/usr/bin/env bash
# Linux 移植一键落地脚本
# 用法：clone 自己的 fork 后，把 linux-port.tar.gz 解压到仓库根目录，然后 bash apply.sh
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

if [ ! -f pubspec.yaml ] || [ ! -d lib ]; then
  echo "✗ 请在 fork 仓库根目录运行（要能看到 pubspec.yaml 和 lib/）"; exit 1
fi
if [ ! -d payload ]; then
  echo "✗ 没找到 payload/。请先：tar -xzf linux-port.tar.gz"; exit 1
fi
command -v flutter >/dev/null 2>&1 || {
  echo "✗ 需要 Flutter SDK（flutter --version 能跑）。装好后再执行本脚本"; exit 1; }

echo "== 1/5 生成 Linux runner =="
flutter create --platforms=linux --project-name moumou --org com.azxcvn . >/dev/null

echo "== 2/5 铺改造文件（会覆盖 flutter create 对 pubspec.yaml 的改动）=="
cp -a payload/. .
chmod +x tools/*.sh packaging/*.sh packaging/wrapper.sh 2>/dev/null || true

echo "== 3/5 调整 GTK runner（平板全屏 / 无标题栏）=="
bash tools/patch-linux-runner.sh

echo "== 4/5 校验关键改动 =="
grep -q "vaapi,vaapi-copy,no" lib/services/decode_settings.dart || { echo "✗ 解码链没生效"; exit 1; }
grep -q "media_kit_libs_linux\|media_kit_libs_video" pubspec.yaml   || { echo "✗ 播放器依赖异常"; exit 1; }
grep -q "=> null;" lib/services/tls_ca_bundle.dart                  || { echo "✗ CA 短路没生效"; exit 1; }
echo "   解码链 / CA / 依赖 OK"

echo "== 5/5 提交并推送 =="
git add -A
if git diff --cached --quiet; then
  echo "   没有新改动（可能已经跑过一次），跳过提交"
else
  git -c user.name="linux-port" -c user.email="linux-port@localhost" \
      commit -q -m "linux: x64 deb port (vaapi, 砍 Android 专属功能) [skip ci]"
fi
if ! git push origin HEAD; then
  echo
  echo "✗ push 没成功。别担心：改动已经 commit 在本地了。"
  echo "  配好 git 登录 GitHub 之后，只要再跑一次："
  echo "      git push origin HEAD"
  echo "  然后去 Actions 启用工作流即可。"
  exit 1
fi

echo
echo "✓ 完成。接下来："
echo "  GitHub → Actions → 启用工作流 → build-x64-deb → Run workflow"
echo "  （想同时出 Release 就勾上 make_release）"
