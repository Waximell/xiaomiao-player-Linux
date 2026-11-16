# 小喵 Player · Linux x64 移植说明

面向一台 Intel 平板：GNOME/KDE Wayland、SMB + 哔哩哔哩在线播放、VA-API 硬解。
基于上游 `azxcvn/xiaomiao-player` @ `6fb52cd`（`1.3.9+7`）做**最小 diff**改造。

## 首次落地（只需三条命令）

```bash
git clone https://github.com/Waximell/xiaomiao-player-Linux.git
cd xiaomiao-player-Linux
# 把 linux-port.tar.gz 放进这个目录
tar -xzf linux-port.tar.gz
bash apply.sh
```

`apply.sh` 会：生成 `linux/` runner → 铺改造文件 → 调整 GTK runner →
`git add / commit / push`（commit 带 `[skip ci]`，不会自触发）。
仓库里会保留 `payload/` 目录（就是这次铺进去的改造文件副本），方便对照查看；
以后重出补丁时直接把新的 `payload/` 覆盖进来再跑一次 `apply.sh` 即可。
脚本里用 `git -c` 临时写了 user.name / email，**不用你配 git 身份**。
git 登录 GitHub 的方式（HTTPS PAT / SSH key）你自己选，脚本不碰凭据。

然后：GitHub → **Actions** → 启用工作流（fork 默认关闭，一次性）→
选 `build-x64-deb` → **Run workflow**。deb 在 Artifacts；勾 `make_release` 会顺手发 Release。

## 以后上游出 release

1. 网页点 **Sync fork**（或本地 `git fetch upstream && git merge upstream/main`）
2. 有冲突就处理；改动都集中在 `patches/linux.patch` 覆盖的那十来个文件
3. 再点一次 **Run workflow**

`linux/`、`packaging/`、`tools/`、`.github/` 上游都没有，同步不会覆盖。
若上游改了补丁碰到的行，CI 会红；把日志贴回来，重出补丁覆盖对应文件即可。

## 改了什么（最小 diff 原则）

| 文件 | 改动 |
|---|---|
| `pubspec.yaml` | 删 `dependency_overrides`（media_kit fork + 自建 Android 内核）；换/保留 Linux libs；摘掉 `assets/shaders/` 与 `assets/certs/` |
| `decode_settings.dart` | `hwdec` 值改为 `vaapi` / `vaapi-copy`；`gpuNext` / `useVulkan` 恒 `false` |
| `decode_policy.dart` | 两条链改为 `vaapi,vaapi-copy,no` / `vaapi-copy,no` |
| `player_renderer_settings.dart` | **未改**：`gpuNext` 恒 false 后，Android 的 `gpu-context/gpu-api` workaround 分支永不执行 |
| `tls_ca_bundle.dart` | `ensurePath()` 恒返回 `null` → 不写 `tls-ca-file`，用系统证书库 |
| `player_shader_pipeline.dart` | 超分 + 后处理的**唯一** `glsl-shaders` 出口短路：只清空链，保证 VA-API 直通 |
| `player_orientation.dart` | 新增 `apply()`，Linux 上 `setPreferredOrientations` 全部 no-op |
| 3 个播放页 | 方向调用改走 `PlayerOrientation.apply()` |
| `player_session_state.dart` | 音量回调改接 `player.setVolume`；取消左右半屏亮度分支 |
| `player_gesture_layer.dart` | 删 8% 死区与左右分类，全屏任意位置上下滑都是音量 |

**没动的文件**：`fast_thumbnails.dart` 已有 `Platform.isAndroid` 保护，Linux 上恒 no-op，
缩略图自然消失；`playback_tuning.dart` 的 open-before 调参保持不变（B站/SMB 缓存靠它）。

## 已知「入口还在但不可用」

按「先保证编译通过、再按 CI 日志逐个摘」的策略，以下模块**文件仍在、未物理删除**：
下载（`download/`）、应用内更新、设备信息/解码器详情页、截图、WebDAV/FTP、
本地媒体库、投屏、隐私门禁、崩溃日志、整应用重启按钮。
它们在 Linux 上要么走 `MissingPluginException` 被 try/catch 吞掉，要么只是点了没反应，
**不影响播放、不影响编译**。等首跑稳定后再按 `REMOVE_LATER.md` 逐个摘路由。

设置页里 gpu-next / Vulkan 两个开关也还在，但因为 getter 恒 false，永远不生效。

## 硬解与显示栈

- `hwdec = vaapi,vaapi-copy,no`：优先零拷贝直通，失败退拷贝，再失败软解。
  默认档位就是「硬解+」，正好对应直通链。
- 不写 `gpu-context` / `gpu-api` / `opengl-es`；`vo=gpu`，走 media_kit_video 的
  OpenGL/EGL 纹理桥。VA-API 的 dmabuf/EGL interop 由 mpv 自己完成。
- deb 运行时依赖：`libmpv`、`libepoxy`、`libgtk-3`、`libsecret-1`（B站/SMB 凭据要用）。
  `intel-media-va-driver` 放 `Recommends`，不硬依赖。
- Wayland / X11 由 GTK runner 自动选；触摸、多指手势、旋转后的坐标变换由
  compositor + Flutter embedder 处理，**不用自己管显示栈**。
- iio：不需要 App 接 D-Bus。GNOME/KDE Wayland + `iio-sensor-proxy` 由 compositor
  旋屏，App 只看到窗口宽高交换后切横/竖屏页（A 档）。若方向不对，是系统层
  `ACCEL_MOUNT_MATRIX` (udev hwdb) 的问题，别改 App。

## 排障

| 现象 | 处理 |
|---|---|
| 启动就 SIGSEGV（Wayland） | `bash tools/disable-impeller.sh` 后重新 build；Flutter 3.47+ 上 Impeller 与 GTK3 EGL 冲突的已知 workaround |
| 日志 `EGL display or context is invalid` / `Using S/W rendering` | media_kit_video + 新版 Flutter 的回归；把 workflow 里 `flutter-action` 临时加 `flutter-version:` 锁到验证过的版本 |
| `hwdec-current = vaapi-copy` / `no` | 查 `vainfo`、驱动、`intel-media-va-driver`；看 mpv 日志的 interop 失败原因 |
| 装完启动报 `error while loading shared libraries` | `ldd` 输出对照 `packaging/DEBIAN/control` 的 `Depends` |
| 旋转后方向错 / 竖屏弹回横屏 | 系统 hwdb 的 `ACCEL_MOUNT_MATRIX`，用 `monitor-sensor` 校准 |
| 平板不想全屏 | 注释掉 `linux/runner/my_application.cc` 里 `gtk_window_fullscreen(...)` 那行 |
| 强制 Wayland | 编辑 `packaging/wrapper.sh`，取消 `GDK_BACKEND=wayland` 注释 |

## 协议

跟随上游 **GPL-3.0**，`LICENSE` 与 `THIRD_PARTY_NOTICES.md` 原样保留。
deb 内含 `/usr/share/doc/xiaomiao-player/copyright`；fork 公开，完整对应源码即
构建时的 commit（Release 描述里也写了）。不用你额外做什么。
