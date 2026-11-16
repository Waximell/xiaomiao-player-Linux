# 本包生成报告

```
OK   media_kit_libs_linux = ^1.2.1
OK   pubspec: 移除 dependency_overrides（media_kit fork + android 内核）
OK   pubspec: 换 media_kit_libs_linux
OK   pubspec: 移除 assets/shaders/
OK   pubspec: 移除 assets/certs/（按行兜底）
OK   decode_settings: hwCopy -> vaapi-copy
OK   decode_settings: hwPlus -> vaapi 直通链
OK   decode_settings: gpuNext 恒 false
OK   decode_settings: useVulkan 恒 false
OK   decode_policy: 直通链 -> vaapi
OK   decode_policy: 拷贝链 -> vaapi-copy
OK   tls_ca_bundle: 整体换成 null stub（无 dart:io / path_provider 依赖）
OK   player_shader_pipeline: 短路整套超分/后处理 shader 链
OK   player_orientation: 新增 apply() 并在 Linux no-op
OK   player_page.dart: 10 处方向调用改为 apply()
OK   player_portrait_page.dart: 1 处方向调用改为 apply()
OK   audio_player_page.dart: 1 处方向调用改为 apply()
OK   player_session_state: 音量回调改接 mpv
OK   player_session_state: 取消左右半屏亮度分支
OK   player_gesture_layer: 删除 14 行死区常量/判定
OK   player_gesture_layer: 垂直手势不再分左右
OK   import 顺序整理: player_orientation.dart
OK   import 顺序整理: player_session_state.dart
OK   import 顺序整理: audio_player_page.dart
OK   patch: 由 git diff 生成
OK   patches/linux.patch: 11 个文件有 diff
```

MISS 行表示某个精确替换未命中（上游该处代码可能已变化），需要人工核对对应文件；其余改动均已落地。
