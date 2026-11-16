# 第二阶段：可以物理删除的模块（首版故意没删）

首版采用「功能级禁用 + 最小 diff」，目的是先让 CI 编译通过、deb 能跑起来。
这些文件在 Linux 上要么 `MissingPluginException` 被吞，要么点了没反应，
不影响播放。等首跑稳定后，按下面顺序逐个摘**路由/入口**，不要逐方法删内部实现，
这样跟上游 merge 的冲突面最小。

## 可直接整块删

- `lib/services/download/`（含 `download_task.dart` / `mergeM4s` 调用）
- `lib/services/update/`（应用内检查更新）
- `lib/services/fast_thumbnails.dart` + `lib/pages/player/views/player_thumbnail_preview.dart`
  （先确认所有 import 点）
- `lib/services/super_resolution_service.dart`
- `lib/services/post_process_service.dart`、`lib/utils/post_process_shaders.dart`
- `lib/services/player_shader_pipeline.dart`（当前是短路 stub，可最后删）
- `lib/services/tls_ca_bundle.dart`（当前是 null stub，可最后删）
- `lib/pages/settings/device_info_page.dart`、`decoder_detail_page.dart`
- `lib/models/device_decoder.dart`
- `lib/pages/settings/*` 里的：崩溃日志、缓存管理、隐私门禁、设备信息入口
- `lib/widgets/dolby_vision_hint.dart`（依赖 gpuNext 判断，已失效）
- `lib/pages/player/views/player_super_resolution_panel.dart`
- `lib/pages/player/views/player_post_process_panel.dart`
- `lib/pages/player/views/player_decode_panel.dart`（解码档位 UI）
- WebDAV / FTP 相关入口与 `network_client_factory.dart` 分支
- 本地媒体库：`MediaStore` 扫描、`video_scanner.dart`、文件管理页
- 投屏：`lib/services/cast/`、`lan_media_server.dart`

## 删之前先查

```bash
grep -r "要删的文件名" lib/ --include='*.dart'
```

把 import 和调用点一起清掉，再跑 `flutter analyze`。
`pubspec.yaml` 里 `permission_handler` / `saver_gallery` / `ffi` 等依赖
要等所有 import 清完之后才能删，否则 `pub get` 后编译断裂。

## 不要动

- `lib/l10n/app_localizations*.dart`、`label_maps.dart`：gen_l10n 生成物，
  超分/解码文案占了一大半命中，删了要重新生成，还平白制造冲突。字符串留着无害。
- `android/`：原样保留，删了每次 merge 都是灾难。
