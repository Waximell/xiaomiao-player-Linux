基于小喵 Player 1.3.9 初步修改

保留：本地/在线播放、字幕、弹幕、播放列表、音轨与章节、VA-API 硬解。

移除：画中画、屏幕亮度与半屏手势分区、屏幕旋转锁定、系统音量通道、GPU-next/Vulkan 渲染后端、Anime4K 着色器超分。

修改：内置 CA 证书改用系统证书库，硬解直通改为 vaapi-copy。

安装：`sudo apt install ./xiaomiao-player_1.3.9-linux6_amd64.deb`

GPL-3.0，源码见本仓库对应 tag。
