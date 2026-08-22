# llama.cpp vendor snapshot

- Upstream: `https://github.com/ggml-org/llama.cpp`
- Snapshot: `b21e4de74567f5eef213765c9476a843c2e43f0d`
- Reason: adds the `qwen35` and `qwen35moe` GGUF architectures and the
  recurrent/linear-attention operators required by Qwen3.5.
- Integration: `llama_abi_shim.cpp` keeps the legacy `llama_cpp_dart` FFI
  surface; `include/llama_abi_rename.h` namespaces modern C symbols to avoid
  collisions.

When updating this snapshot, rebuild both Android ABIs and both iOS slices.
Do not replace the GGUF model without rebuilding the native library when its
GGUF architecture is not already supported by the snapshot.
