# 倪海厦中医离线问答

离线优先的倪海厦经方中医问答 App。知识库来自 [nihaixia](https://github.com/jangviktor-web/nihaixia)（MulanPSL-2.0）。
详见 `docs/superpowers/specs/`。

## 项目结构
- `tools/` 构建期 Python 工具：markdown → SQLite
- `app/` Flutter 应用

## 分层能力
- **纯检索**：任意机型可用。基于内置 SQLite 的「and-only OR LIKE 子串匹配 + Dart 侧部分命中过滤与评分」检索（不走 FTS5，无 jieba 分词），答案可溯源到原文。
- **端侧 LLM RAG（已启用）**：`app/lib/llm/` 的 `LlmService` / `LlmRunner` / `RagSynthesizer` 已实现并通过单元测试，并已接入问答流程——`QaTab` 启动时经 `LlmModelResolver` 自动检测模型文件（优先应用文档目录，其次 assets 打包拷贝）→ 有模型文件时问答自动走 RAG 合成（子串与结构化路径共用），无模型文件自动降级纯检索。模型打包是剩余的真机收尾项（见「已知限制」）。
- **云端增强**：设置页填 API Key 后解锁拍照 / Live 增强功能（默认关闭）。

## 构建流程

```bash
# 1. 工具链（Python 3）
cd tools
python3 -m venv .venv
.venv/bin/pip install -r requirements.txt

# 2. 拉取 nihaixia 知识库源码
git clone --depth 1 https://github.com/jangviktor-web/nihaixia.git tools/data/nihaixia

# 3. 构建 SQLite 知识库（输出 tools/out/kb.sqlite3）
.venv/bin/python build_kb.py --repo data/nihaixia --out out

# 4. 拷入 App 资源
cp tools/out/kb.sqlite3 app/assets/kb/kb.sqlite3

# 5. 下载端侧模型（可选，见下节）
#    目标文件名：app/assets/models/qwen3-1.7b-instruct-q4_k_m.gguf
#    注意：模型经「文件系统路径」加载（LlmService 检查 File(modelPath).existsSync()）。
#    若打包进 assets（注册 pubspec 后），首次启动由 LlmModelResolver 自动复制到
#    应用文档目录；当前 assets/models/ 未注册，真机需先完成打包步骤（见「已知限制」）。

# 6. 运行 App
cd app
flutter pub get
flutter run
```

### 端侧模型下载

| 项 | 值 |
|---|---|
| 仓库 | ModelScope `unsloth/Qwen3-1.7B-GGUF`（Apache-2.0） |
| 文件 | `Qwen3-1.7B-Q4_K_M.gguf`（约 1.1GB） |
| 目标路径 | `app/assets/models/qwen3-1.7b-instruct-q4_k_m.gguf`（与代码中传入 `LlmRunner.ensureLoaded` 的 `modelPath` 一致，见 `test/llm_real_test.dart`） |

国内网络可从 [ModelScope unsloth/Qwen3-1.7B-GGUF](https://www.modelscope.cn/models/unsloth/Qwen3-1.7B-GGUF) 下载 `Qwen3-1.7B-Q4_K_M.gguf`，重命名后放入 `app/assets/models/`。模型文件已被 `.gitignore`（`*.gguf`）排除，不会入库。

**打包注意**：`pubspec.yaml` 的 assets 目前只注册 `assets/kb/kb.sqlite3`，`assets/models/` 未注册为 Flutter asset；`LlmService` 按文件系统路径（`File(modelPath).existsSync()`）检查模型。若将模型注册为 asset，首次启动 `LlmModelResolver` 会自动复制到应用文档目录；当前未注册，真机需先完成打包步骤（见「已知限制」）。

### real 测试

`real` 用例需要模型文件已就位：

```bash
cd app
flutter test --run-skipped test/llm_real_test.dart
```

默认 `flutter test` 会跳过带 `real` tag 的用例（见 `app/dart_test.yaml`）。

### 已知限制

- **tiao_wen 结构化命中未排序（噪声）**：`小柴胡汤什么时候用` 等 herbFormula 意图查询命中 tiao_wen 表且无排序（噪声）。合成器可用时由 LLM 归纳缓解（取前 8 条证据），不可用时为原文 dump。
- **llm_runner load 重试守卫缺失**：`LlmRunner.ensureLoaded` 的 load 等待（120s 超时）没有像 `_boot` 超时那样的 kill/reset 守卫——load 超时抛错后 isolate 可能残留。当前不可达（`LlmService.generate` 一次性 dispose + `_failed` 降级覆盖）；补上镜像 `_boot` 超时的 reset 守卫是剩余的真机收尾项（仅真机可复现）。
- **Android native libllama vendoring（已解决）**：`llama_cpp_dart 0.0.7` 已 vendoring 到 `app/third_party/llama_cpp_dart/`，内含 llama.cpp **b5113** 源码与 C++ ABI shim（`src/llama_abi_shim.cpp`，不 include llama.h + rename 宏），产出 ABI 兼容的 `libllama.{dylib,so}`：
  - 原生库经 CMake 手工构建后预置为 `app/third_party/llama_cpp_dart/android/src/main/jniLibs/{arm64-v8a,x86_64}/libllama.so`（无 OpenMP、仅依赖系统库，SONAME 正确），插件已移除 `externalNativeBuild`，`flutter build apk --release` 直接打包；
  - macOS 调试用 `LLAMA_LIBRARY_PATH=.../libllama.dylib flutter test --run-skipped test/llm_real_test.dart`；
  - 构建需 NDK + CMake；本机并行 ninja 会 OOM，用 `ninja -j2`。
  - 注意：`app/android/gradle.properties` 已固定 `org.gradle.java.home` 为 JDK 17（Gradle/AGP 8.7 不支持 JDK 25），`gradle-wrapper.properties` 已升级 gradle 8.9 / AGP 8.7.3（aapt2 才能解析 android-35 资源）。
- **模型打包方式**：模型当前经文件系统路径加载（非 Flutter asset），`pubspec.yaml` 未注册 `assets/models/`；打包为 App 内资产需要额外工作（注册为资产或部署到应用文档目录）。

## 免责声明

本 App 仅用于中医学习与研究，不构成医疗建议。如有健康问题，请咨询执业医师。