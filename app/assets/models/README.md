# 端侧模型

本目录放置 Qwen3-1.7B-Instruct Q4_K_M GGUF（约 1.1GB），
由开发机手动下载，`.gitignore` 已排除 `*.gguf`。

建议来源：HuggingFace `Qwen/Qwen3-1.7B-instruct` 社区 GGUF 量化版，
国内可改用 ModelScope `unsloth/Qwen3-1.7B-GGUF` 的 `Qwen3-1.7B-Q4_K_M.gguf`。

注意：本目录**未注册为 Flutter asset**（`pubspec.yaml` 仅含 `assets/kb/kb.sqlite3`），
`LlmService` 按文件系统路径检查模型。模型放入应用支持目录后真机验证请运行：

```bash
flutter test --run-skipped test/llm_real_test.dart
```

模型打包为 App 内资产（注册 asset 或部署到文档目录）见根 README「已知限制」。
