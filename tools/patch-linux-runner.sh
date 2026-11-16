#!/usr/bin/env bash
# 由 apply.sh 调用：调整 flutter create 生成的 GTK runner（平板用）
set -euo pipefail
P=linux/runner/my_application.cc
[ -f "$P" ] || { echo "✗ 找不到 $P"; exit 1; }
python3 - <<'PY'
from pathlib import Path
p = Path('linux/runner/my_application.cc')
s = p.read_text()
# 平板：不用 GNOME header bar，直接全屏
if 'gboolean use_header_bar = TRUE;' in s:
    s = s.replace('gboolean use_header_bar = TRUE;', 'gboolean use_header_bar = FALSE;')
    print('✓ 已关闭 header bar')
else:
    print('⚠ 未找到 use_header_bar，Flutter runner 模板可能变了（不影响构建）')
if 'gtk_window_fullscreen' not in s:
    s = s.replace('gtk_window_set_default_size(window, 1280, 720);',
                  'gtk_window_set_default_size(window, 1280, 720);\n'
                  '  // Linux port: 平板默认全屏；桌面调试可注释掉下一行\n'
                  '  gtk_window_fullscreen(GTK_WINDOW(window));')
p.write_text(s)
print('✓ GTK runner: 无标题栏 + 全屏')
PY
