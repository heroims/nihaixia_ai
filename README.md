# 倪海厦中医离线问答

离线优先的倪海厦经方中医问答 App。知识库来自 [nihaixia](https://github.com/jangviktor-web/nihaixia)（MulanPSL-2.0）。
详见 `docs/superpowers/specs/`。

## 项目结构
- `tools/` 构建期 Python 工具：markdown → SQLite
- `app/` Flutter 应用

## 分层能力
- **纯检索**：任意机型可用。基于内置 SQLite 的「and-only OR LIKE 子串匹配 + Dart 侧部分命中过滤与评分」检索（不走 FTS5，无 jieba 分词），答案可溯源到原文。
- **端侧 LLM 层（已实现，待接线）**：`app/lib/llm/` 的 `LlmService` / `LlmRunner` / `RagSynthesizer` 已实现并通过单元测试，但**尚未接入问答流程**——当前版本问答走纯检索链路，放置模型文件也不会触发 RAG 合成。把 `RagSynthesizer` 注入 `QaService`（`QaTab` 当前仅 `QaService(db)`）并完成模型打包，是剩余的真机收尾项（见「已知限制」）。
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
#    注意：模型经「文件系统路径」加载（LlmService 检查 File(modelPath).existsSync()），
#    且 assets/models/ 尚未注册为 Flutter asset——当前仅供 real 测试用，
#    打包进 App 需额外工作（见「已知限制」）。

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

**打包注意**：`pubspec.yaml` 的 assets 目前只注册 `assets/kb/kb.sqlite3`，`assets/models/` 未注册为 Flutter asset；`LlmService` 按文件系统路径（`File(modelPath).existsSync()`）检查模型。设备上要把模型装进 App 需要额外工作——将模型注册为 asset 并在运行时解压/拷贝到应用文档目录，或直接部署到文档目录。此外模型尚未接线到问答流程（见「分层能力」与「已知限制」）。

### real 测试

`real` 用例需要模型文件已就位：

```bash
cd app
flutter test --run-skipped test/llm_real_test.dart
```

默认 `flutter test` 会跳过带 `real` tag 的用例（见 `app/dart_test.yaml`）。

### 已知限制

- **端侧 LLM 未接线**：`LlmService` / `RagSynthesizer` 已实现并通过单元测试，但 `QaTab` 只构造 `QaService(db)`（无 synthesizer），生产代码中没有任何地方实例化 LLM 层。用户按上文放置模型文件后，问答仍走纯检索链路。接线（把 `RagSynthesizer` 注入 `QaService`）+ 模型打包是剩余的真机收尾项。
- **结构化路径不走合成**：`桂枝汤和麻黄汤的区别` 等 herbFormula 意图查询命中 herbs/formulas/tiao_wen 结构化表后直接返回结构化 dump（原文拼装），不会经过 RAG 合成。暂缓原因：synthesizer 未接线、tiao_wen 命中排序未定、结构化短路会掩盖更优的子串证据；LLM 接线时改动很小（仅需在 `QaService` 结构化分支补合成调用）。
- **llm_runner load 重试守卫缺失**：`LlmRunner.ensureLoaded` 的 load 等待（120s 超时）没有像 `_boot` 超时那样的 kill/reset 守卫——load 超时抛错后 isolate 可能残留。当前不可达（`LlmService.generate` 一次性 dispose + `_failed` 降级覆盖），接线时补上镜像 `_boot` 超时的 reset 即可。
- **Android native libllama vendoring**：`llama_cpp_dart 0.0.7` 的 Android CMake（`src/CMakeLists.txt`）通过 `add_subdirectory(./llama.cpp)` 引用 llama.cpp 源码，但该版本包内不含 `src/llama.cpp` 源码，因此 Android 原生 `libllama.so` 无法自动编译，release 包打不出来：
  - 需 vendoring llama.cpp 源码到插件 `src/llama.cpp`，或自建并预置 `libllama.so`（arm64-v8a / x86_64）；
  - release 构建前还需配置签名（`key.properties` / gradle `signingConfig`）。
- **模型打包方式**：模型当前经文件系统路径加载（非 Flutter asset），`pubspec.yaml` 未注册 `assets/models/`；打包为 App 内资产需要额外工作（注册为资产或部署到应用文档目录）。

## 免责声明

本 App 仅用于中医学习与研究，不构成医疗建议。如有健康问题，请咨询执业医师。