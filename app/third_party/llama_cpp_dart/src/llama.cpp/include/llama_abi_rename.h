// llama_abi_rename.h — ABI compatibility layer for llama_cpp_dart 0.0.7
//
// The vendored llama.cpp (b5113) exports the "classic" llama.cpp symbols with
// signatures that differ from what the llama_cpp_dart 0.0.7 ffigen binding
// expects (the binding targets a pre-2024 llama.cpp). The ABI shim in
// ../llama_abi_shim.cpp re-exports the old binding surface and translates
// between old and modern struct layouts.
//
// To avoid duplicate-symbol conflicts inside the final shared library, every
// symbol that both the shim and modern llama.cpp define is renamed to a
// "llama_modern_*" variant for the llama.cpp build. This header is included
// from the vendored llama.h so every llama.cpp translation unit sees the same
// renaming. The shim translation unit does NOT include llama.h and therefore
// defines the old names itself.
//
// Only symbols that collide with the old binding surface (or that the shim
// calls internally) are renamed. Everything else is left untouched.

#ifndef LLAMA_ABI_RENAME_H
#define LLAMA_ABI_RENAME_H

#define llama_backend_init               llama_modern_backend_init
#define llama_backend_free               llama_modern_backend_free
#define llama_free                       llama_modern_free
#define llama_free_model                 llama_modern_free_model
#define llama_model_free                 llama_modern_model_free
#define llama_n_ctx                      llama_modern_n_ctx
#define llama_n_vocab                    llama_modern_n_vocab
#define llama_get_logits                 llama_modern_get_logits
#define llama_get_logits_ith             llama_modern_get_logits_ith
#define llama_decode                     llama_modern_decode
#define llama_encode                     llama_modern_encode
#define llama_batch_init                 llama_modern_batch_init
#define llama_batch_free                 llama_modern_batch_free
#define llama_tokenize                   llama_modern_tokenize
#define llama_token_to_piece             llama_modern_token_to_piece
#define llama_token_bos                  llama_modern_token_bos
#define llama_token_eos                  llama_modern_token_eos
#define llama_vocab_bos                  llama_modern_vocab_bos
#define llama_vocab_eos                  llama_modern_vocab_eos
#define llama_vocab_n_tokens             llama_modern_vocab_n_tokens
#define llama_new_context_with_model     llama_modern_new_context_with_model
#define llama_init_from_model            llama_modern_init_from_model
#define llama_kv_cache_clear             llama_modern_kv_cache_clear
#define llama_kv_cache_seq_rm            llama_modern_kv_cache_seq_rm
#define llama_model_load_from_file       llama_modern_model_load_from_file
#define llama_load_model_from_file       llama_modern_load_model_from_file
#define llama_model_default_params       llama_modern_model_default_params
#define llama_context_default_params     llama_modern_context_default_params
#define llama_model_get_vocab            llama_modern_model_get_vocab
#define llama_model_get_model            llama_modern_model_get_model
#define llama_get_model                  llama_modern_get_model
#define llama_set_n_threads              llama_modern_set_n_threads
#define llama_set_rng_seed               llama_modern_set_rng_seed
#define llama_model_apply_lora_from_file llama_modern_model_apply_lora_from_file

#endif // LLAMA_ABI_RENAME_H