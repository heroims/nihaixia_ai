# 倪海厦中医离线问答

离线优先的倪海厦经方中医问答 App。知识库来自 [nihaixia](https://github.com/jangviktor-web/nihaixia)（MulanPSL-2.0）。
详见 `docs/superpowers/specs/`。

## 项目结构
- `tools/` 构建期 Python 工具：markdown → SQLite
- `app/` Flutter 应用

## 分层能力
- **纯检索**：任意机型可用。基于内置 SQLite（FTS5 + jieba 分词），答案可溯源到原文。
- **端侧 LLM RAG**：`app/assets/models/` 下有模型文件时自动启用，离线生成综合回答；模型缺失时自动降级为纯检索。
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

### real 测试

`real` 用例需要模型文件已就位：

```bash
cd app
flutter test --run-skipped test/llm_real_test.dart
```

默认 `flutter test` 会跳过带 `real` tag 的用例（见 `app/dart_test.yaml`）。

### Android release 构建注意（已知限制）

`llama_cpp_dart 0.0.7` 的 Android CMake（`src/CMakeLists.txt`）通过 `add_subdirectory(./llama.cpp)` 引用 llama.cpp 源码，但该版本包内不含 `src/llama.cpp` 源码，因此 Android 原生 `libllama.so` 无法自动编译，release 包打不出来。当前已知限制（Task 26 收尾项）：
- 需 vendoring llama.cpp 源码到插件 `src/llama.cpp`，或自建并预置 `libllama.so`（arm64-v8a / x86_64）；
- release 构建前还需配置签名（`key.properties` / gradle `signingConfig`）。

## 免责声明

本 App 仅用于中医学习与研究，不构成医疗建议。如有健康问题，请咨询执业医师。