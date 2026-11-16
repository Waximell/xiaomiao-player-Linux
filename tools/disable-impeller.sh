#!/usr/bin/env bash
# 可选：Flutter 3.47+ 在 Wayland/GTK3 下 Impeller 与 GDK 的 EGL context 冲突会崩。
# 若你在 GNOME Wayland 上一启动就 SIGSEGV，跑这个脚本回退 Skia，然后重新 build。
set -euo pipefail
python3 - <<'PY'
from pathlib import Path
p = Path('linux/runner/my_application.cc')
s = p.read_text()
if 'fl_dart_project_set_enable_impeller' in s:
    print('已关闭，无需改动'); raise SystemExit
needle = 'fl_dart_project_new();'
assert needle in s, '未找到 fl_dart_project_new()，Flutter runner 结构可能已变化'
s = s.replace(needle, needle + '\n  fl_dart_project_set_enable_impeller(project, FALSE);')
p.write_text(s)
print('✓ 已关闭 Impeller（回退 Skia）')
PY
