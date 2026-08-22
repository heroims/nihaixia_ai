# Flutter 子项目说明

根目录 [README.md](../README.md) 是项目总览；本文只记录进入 `app/` 后的 Flutter、平台和资源调试事项。

## 常用命令

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

构建平台包：

```bash
flutter build apk --debug
flutter build ios --no-codesign --simulator
```

`pubspec.yaml` 注册了知识库和端侧 GGUF 模型 asset。模型文件约 1.1GB，且被根目录 `*.gguf` 规则忽略；完整下载和首次复制流程见根 README。

## 推理模式

设置页提供三种模式：

- **纯检索**：不加载模型，直接返回 SQLite 知识库原文和来源。
- **端侧模型**：使用 `LlmModelResolver` 找到模型后由 llama.cpp 本地归纳；模型不可用时保持纯检索。
- **云端优先**：优先调用 OpenAI 兼容 API，失败落回端侧，再落回知识库原文。

自由问答和引导式诊断通过 `InferenceSession` 共享同一个 `QaService` 与模型生命周期，避免两个页面重复加载 GGUF 或产生模式不一致。诊断页不会在最后一个选项被点击时自动提交，而是先把症状整合成两份输入：完整自然语言提示词用于 RAG/模型归纳，稳定的短关键词用于知识库召回。`DiagnosticEngine` 只提供可解释的规则基线，最终结果同时展示回答通道、检索来源和规则线索。

API Key 通过 `flutter_secure_storage` 写入 iOS Keychain / Android Keystore。云端配置不会写进源码或测试快照。

## 品牌资源生成

品牌源文件位于 `assets/branding/`。在仓库根目录执行：

```bash
brew install librsvg
python3 app/assets/branding/generate_assets.py --root .
```

生成器会同步更新：

- `android/app/src/main/res/mipmap-*/ic_launcher.png`
- `android/app/src/main/res/drawable/launch_logo.png`
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
- `ios/Runner/Assets.xcassets/LaunchImage.imageset/`

Android 启动窗口由 `res/drawable*/launch_background.xml` 提供宣纸米色背景；iOS 启动窗口由 `Runner/Base.lproj/LaunchScreen.storyboard` 提供同色背景和中心图组。

## 测试说明

- `flutter test` 默认包含检索、结构化查询、RAG 降级、模型解析和 widget 测试；带 `real` tag 的真实模型用例默认跳过。
- 真实模型测试：`flutter test --run-skipped test/llm_real_test.dart`。
- 没有可用模型时，测试/构建前仍需准备 `assets/models/Qwen3.5-0.8B-Q6_K.gguf` 资产路径；该文件不应提交。
- Android/iOS 原生库和构建环境说明见根 README 的“已知限制与取舍”。

诊断相关回归测试覆盖：四步状态机、最后一步多选、返回编辑/重新开始、无症状不请求、完整提示词与短检索词分离，以及规则基线的身体酸痛分支。

## 常见排查

1. **资源找不到**：确认 `assets/kb/kb.sqlite3` 和模型文件路径与 `pubspec.yaml` 一致，重新执行 `flutter pub get`。
2. **端侧模型未加载**：到设置页查看“端侧模型”状态；首次启动需要等待复制/加载，失败时可先切到“纯检索”。
3. **云端不生效**：确认模式为“云端优先”，Base URL 包含 `http://` 或 `https://`，API Key 和模型名已保存。
4. **图标/启动页未更新**：重新运行品牌生成器后清理平台构建缓存，再执行对应的 `flutter build`。
