# Qwen3.5 原生推理层升级

## 目标

在独立 worktree 中将 Flutter 应用使用的 llama.cpp 原生库升级到包含 Qwen3.5 架构支持的版本，同时保持现有 Dart FFI/ABI shim 兼容，并重新生成 Android 与 iOS 原生产物。

## 执行步骤

1. 固定并导入包含 `qwen35` 架构实现的 llama.cpp 上游源码，确认 GGUF 架构枚举、模型映射、算子与构建配置完整。
2. 调整项目 ABI shim 与构建配置，解决上游 API/结构变化，先完成宿主机编译检查。
3. 使用项目 Android NDK 构建 arm64-v8a 与 x86_64 的 `libllama.so`，替换插件预编译产物并检查符号、架构和模型加载路径。
4. 构建 iOS 真机与模拟器静态库/xcframework，更新 Runner 引用所需产物。
5. 运行 Flutter 单元测试、原生构建验证和 GGUF 元数据/加载冒烟检查，并在 README 记录版本、构建命令和模型兼容说明。

## 验收标准

- `qwen35` GGUF 不再在原生层因未知架构直接加载失败。
- Android arm64 与 x86_64 原生库成功构建并可被现有 Dart FFI 加载。
- iOS 产物可链接，Flutter 测试通过。
- README 明确说明升级内容、重编译方式和模型文件要求。
