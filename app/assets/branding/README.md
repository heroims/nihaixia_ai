# 经方印章品牌资源

这里保存 App 图标和启动页的单一设计源。平台 PNG 不手工绘制，统一由 `generate_assets.py` 从 SVG 导出，避免 Android 密度图、iOS AppIcon 和启动页在迭代时出现视觉漂移。

## 视觉规范

| 角色 | 色值 | 用途 |
|---|---|---|
| 朱砂红 | `#9E3D32` | 图标底色、核心标记 |
| 宣纸米色 | `#F3EAD8` | 启动页背景、印章线条 |
| 墨色 | `#3F2B25` | 启动页标题文字 |
| 旧金 | `#C9A67E` | 双线印章和分隔线 |

图标安全区为画布四周 128px 以上；启动页图组保持居中并留出系统安全边距。图标不包含阴影、渐变、网络内容或医疗功效文案。

## 生成

macOS 需要安装 `librsvg`：

```bash
brew install librsvg
python3 app/assets/branding/generate_assets.py --root .
```

脚本只写入 Android `mipmap-*`、Android 启动图、iOS `AppIcon.appiconset` 和 `LaunchImage.imageset` 的固定目标文件，不扫描、删除或修改其他文件，也不会生成或触碰 `.gguf` 模型。

## 源文件

- `icon.svg`：1024×1024 App 图标源。
- `launch.svg`：1024×1024 启动页中心图组源，背景由平台启动页提供。
