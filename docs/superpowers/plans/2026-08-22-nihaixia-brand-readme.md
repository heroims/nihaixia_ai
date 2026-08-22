# 倪海厦 README 与品牌资源 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 完善项目文档，并用一套可复生成的“经方印章”视觉资源替换 Android/iOS App 图标与启动页占位。

**Architecture:** 以 `app/assets/branding/` 保存 SVG 设计源和生成脚本；脚本用系统 `rsvg-convert` 输出固定尺寸 PNG，平台目录只保存运行时所需的副本。README 分为产品、AI 工程、运行验证和面试展示四层；Flutter 业务逻辑不改，只更新原生静态资源引用。

**Tech Stack:** Flutter 3.x, Android XML resources, iOS asset catalogs/Storyboard, SVG, Python 3 standard library, `rsvg-convert`, `sips`。

---

### Task 1: 建立品牌源文件与可复生成器

**Files:**
- Create: `app/assets/branding/icon.svg`
- Create: `app/assets/branding/launch.svg`
- Create: `app/assets/branding/generate_assets.py`
- Create: `app/assets/branding/README.md`

- [ ] **Step 1: 写入图标 SVG 源文件**

  在 `icon.svg` 中创建 1024×1024 画布：`#9E3D32` 圆角方形底，内缩双线印章框，居中“经方”二字，使用 `STHeiti`/`Hiragino Sans GB` 字体回退；所有内容距边缘至少 128px，不使用阴影、渐变或透明背景。

- [ ] **Step 2: 写入启动页 SVG 源文件**

  在 `launch.svg` 中创建 1024×1024 透明画布，只绘制约 560px 宽的图标组和“倪海厦 · 离线中医问答”文字组，保持中心对齐；背景由各平台启动页提供 `#F3EAD8`，避免把背景烘焙进图片。

- [ ] **Step 3: 实现生成脚本**

  `generate_assets.py` 使用 `argparse` 接受 `--root`（默认为仓库根目录），检查 `rsvg-convert` 和输入 SVG 存在，然后执行以下固定输出：

  ```text
  Android icon: 48, 72, 96, 144, 192 -> app/android/app/src/main/res/mipmap-{density}/ic_launcher.png
  iOS icon: 20, 29, 40, 60, 76, 83.5, 1024 points/pixels -> app/ios/Runner/Assets.xcassets/AppIcon.appiconset/
  iOS launch: 200, 400, 600 -> app/ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage{,@2x,@3x}.png
  Android launch: 512 -> app/android/app/src/main/res/drawable/launch_logo.png
  ```

  每个尺寸通过 `subprocess.run([...], check=True)` 调用 `rsvg-convert -w N -h N -o output input.svg`；iOS 需要的 167px 图标由 83.5pt×2 生成。脚本只覆盖上述明确目标文件，不扫描或删除其他资源。

- [ ] **Step 4: 写资源说明**

  `app/assets/branding/README.md` 记录调色板、设计安全区、系统依赖安装命令（`brew install librsvg`）、生成命令和平台文件映射，并明确生成脚本不会生成/触碰 `.gguf` 模型。

- [ ] **Step 5: 静态检查源文件**

  运行 `python3 app/assets/branding/generate_assets.py --help`，确认帮助可用；运行 `git diff --check`，确认 SVG/脚本无尾随空格。

- [ ] **Step 6: Commit**

  ```bash
  git add app/assets/branding
  git commit -m "feat: add reproducible jing-fang brand assets"
  ```

### Task 2: 生成并接入 Android 图标与启动页

**Files:**
- Modify: `app/android/app/src/main/res/mipmap-mdpi/ic_launcher.png`
- Modify: `app/android/app/src/main/res/mipmap-hdpi/ic_launcher.png`
- Modify: `app/android/app/src/main/res/mipmap-xhdpi/ic_launcher.png`
- Modify: `app/android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png`
- Modify: `app/android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png`
- Create: `app/android/app/src/main/res/drawable/launch_logo.png`
- Modify: `app/android/app/src/main/res/drawable/launch_background.xml`
- Modify: `app/android/app/src/main/res/drawable-v21/launch_background.xml`
- Modify: `app/android/app/src/main/res/values/styles.xml`
- Modify: `app/android/app/src/main/res/values-night/styles.xml`

- [ ] **Step 1: 运行生成器**

  ```bash
  python3 app/assets/branding/generate_assets.py --root .
  ```

  预期生成五个密度目录下的 `ic_launcher.png` 和 `drawable/launch_logo.png`，所有文件为 RGBA PNG。

- [ ] **Step 2: 更新 Android 启动背景**

  将两个 `launch_background.xml` 改为同一份 layer-list：底层 `@color/launch_paper`，上层 bitmap `@drawable/launch_logo`，`android:gravity="center"`，不使用 `tileMode`。在 `values/styles.xml` 和 `values-night/styles.xml` 增加 `launch_paper` 颜色 `#F3EAD8`，夜间也使用该静态启动背景，避免暗色主题产生白闪。

- [ ] **Step 3: 核对应用标签**

  将 `AndroidManifest.xml` 的 `android:label` 从包名改为 `倪海厦中医问答`，保留 `@mipmap/ic_launcher` 和现有网络安全配置不变。

- [ ] **Step 4: 验证 Android 资源**

  ```bash
  file app/android/app/src/main/res/mipmap-*/ic_launcher.png app/android/app/src/main/res/drawable/launch_logo.png
  cd app && flutter build apk --debug
  ```

  预期各图标尺寸分别为 48/72/96/144/192，debug APK 构建成功且无资源链接错误。

- [ ] **Step 5: Commit**

  ```bash
  git add app/android
  git commit -m "feat: apply jing-fang Android icon and splash"
  ```

### Task 3: 生成并接入 iOS 图标与启动页

**Files:**
- Modify: `app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json`
- Modify/Create: `app/ios/Runner/Assets.xcassets/AppIcon.appiconset/*.png`
- Modify: `app/ios/Runner/Assets.xcassets/LaunchImage.imageset/Contents.json`
- Modify/Create: `app/ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage*.png`
- Modify: `app/ios/Runner/Base.lproj/LaunchScreen.storyboard`
- Modify: `app/ios/Runner/Info.plist`

- [ ] **Step 1: 运行生成器并检查 AppIcon 引用**

  运行 `python3 app/assets/branding/generate_assets.py --root .`，然后用 Python 标准库解析 `AppIcon.appiconset/Contents.json`，逐项确认 `filename` 文件存在且像素尺寸匹配 `size × scale`；不手工删除 Xcode 需要的 idiom 条目。

- [ ] **Step 2: 更新启动图片集**

  将 `LaunchImage.imageset/Contents.json` 改为引用 `LaunchImage.png`、`LaunchImage@2x.png`、`LaunchImage@3x.png`，保留通用 universal idiom；删除 1×1 占位内容后由生成器写入 200/400/600px 图片。

- [ ] **Step 3: 更新 LaunchScreen storyboard**

  将根视图背景颜色改为 RGB `0.953, 0.918, 0.847`（`#F3EAD8`），保留居中 imageView，补充宽高约束使中心图组在 iPhone/iPad 和横竖屏下保持安全边距；图片仍使用 `LaunchImage`，不添加动态或网络内容。

- [ ] **Step 4: 更新显示名称**

  将 `Info.plist` 的 `CFBundleDisplayName` 改为 `倪海厦中医问答`，保持 bundle identifier 和场景配置不变。

- [ ] **Step 5: 验证 iOS 资源**

  ```bash
  python3 - <<'PY'
  import json
  from pathlib import Path
  root = Path('app/ios/Runner/Assets.xcassets')
  for name in ('AppIcon.appiconset', 'LaunchImage.imageset'):
      d = root / name
      data = json.loads((d / 'Contents.json').read_text())
      for image in data['images']:
          if image.get('filename'):
              assert (d / image['filename']).is_file(), image['filename']
  print('asset catalog references: OK')
  PY
  cd app && flutter build ios --no-codesign --simulator
  ```

  预期资源引用检查通过，模拟器 iOS 构建成功。

- [ ] **Step 6: Commit**

  ```bash
  git add app/ios
  git commit -m "feat: apply jing-fang iOS icon and launch screen"
  ```

### Task 4: 重写根 README 与 Flutter 子项目 README

**Files:**
- Modify: `README.md`
- Modify: `app/README.md`

- [ ] **Step 1: 写产品层 README**

  根 README 开头用一句话定位，随后列出问答、诊断、知识库来源追溯、端侧/云端边界和免责声明；加入截图/资源说明但不引用不存在的图片 URL。

- [ ] **Step 2: 写 AI 工程亮点**

  使用当前代码事实描述：纯检索 fallback、结构化查询路由、端侧 Qwen3 GGUF + llama.cpp RAG、模型自动解析与首次复制、云端 API Key 解锁拍照/Live、SQLite 可追溯证据；对每项写清“输入—处理—输出—降级”。

- [ ] **Step 3: 写架构与数据流**

  用 Mermaid 或 ASCII 图描述 `UI → QAService/IntentRouter → Searcher/StructuredQueries → RagSynthesizer → 来源列表`，并注明模型不可用时回退到检索结果；补充 `tools/` 构建 SQLite 的离线流程。

- [ ] **Step 4: 写运行、测试和面试展示章节**

  保留并校正现有 Python/Flutter/模型命令；增加 `flutter analyze`、默认测试、real 测试前置条件、Android/iOS 构建；新增“面试演示建议”按 5 分钟顺序展示检索、RAG、降级、证据和测试；保留已知限制和医疗免责声明。

- [ ] **Step 5: 更新 app/README.md**

  改为 Flutter 子项目说明：进入 `app/` 后的运行、调试、平台资源生成命令和常见排查；链接到根 README，删除 Flutter 模板文案。

- [ ] **Step 6: 文档一致性检查**

  ```bash
  rg -n "assets/branding|flutter analyze|RagSynthesizer|LlmModelResolver|DISCLAIMER|免责声明" README.md app/README.md
  git diff --check
  ```

  预期关键章节、路径和当前实现符号都能被检索到，无错误路径和占位文案。

- [ ] **Step 7: Commit**

  ```bash
  git add README.md app/README.md
  git commit -m "docs: rewrite project and app README"
  ```

### Task 5: 全量验证与交付检查

**Files:**
- Modify: `.gitignore` only if needed to ignore `.superpowers/` visual companion output

- [ ] **Step 1: 运行静态与单元测试**

  ```bash
  cd app && flutter analyze
  flutter test
  ```

  预期分析无 error，默认测试通过；真实模型测试仍按 README 的 `--run-skipped` 前置条件执行，不因缺少模型而阻塞默认验证。

- [ ] **Step 2: 检查资源与工作区**

  ```bash
  cd ..
  git diff --check
  git status --short
  git ls-files '*.gguf'
  ```

  预期无 `.gguf` 被跟踪；`.superpowers/` 若用于视觉 companion 则加入 `.gitignore`，不提交其临时 HTML/事件文件。

- [ ] **Step 3: 最终汇总**

  记录 README、SVG 源文件、生成脚本、Android/iOS 资源的绝对路径；说明已执行的验证命令及任何因本机 SDK/模型缺失而跳过的命令，不声称未运行的构建成功。

- [ ] **Step 4: Commit**

  ```bash
  git add .gitignore
  git commit -m "chore: ignore brainstorm companion output"
  ```
