from pathlib import Path


SHIM = (
    Path(__file__).resolve().parents[2]
    / "app/third_party/llama_cpp_dart/src/llama_abi_shim.cpp"
)


def test_modern_context_uses_bounded_physical_batch():
    source = SHIM.read_text()

    # n_batch is the logical submission limit; n_ubatch controls the Metal
    # compute graph's peak allocation and must remain bounded on iOS devices.
    assert "c.n_ubatch            = std::min<uint32_t>(params.n_batch, 512u)" in source
    assert "c.n_ubatch            = params.n_batch" not in source
