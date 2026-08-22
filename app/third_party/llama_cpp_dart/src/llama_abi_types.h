// llama_abi_types.h - ABI struct layouts for the llama_cpp_dart 0.0.7 shim.
//
// Defines the OLD ABI structs (matching the ffigen output in
// lib/src/llama_cpp.dart, pre-2024 llama.cpp) plus the MODERN structs
// (matching vendored llama.cpp b5113 layouts). The shim translation unit
// (llama_abi_shim.cpp) never includes llama.h; it only sees these types.
//
// All layouts are pinned with static_asserts so that a divergence from either
// the ffigen binding or the llama.cpp header fails the build.

#ifndef LLAMA_ABI_TYPES_H
#define LLAMA_ABI_TYPES_H

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

typedef int32_t llama_token;
typedef int32_t llama_pos;
typedef int32_t llama_seq_id;

// ---------------------------------------------------------------------------
// OLD ABI (ffigen binding surface, llama_cpp.dart)
// ---------------------------------------------------------------------------

struct llama_token_data {
    int32_t id;
    float   logit;
    float   p;
};

struct llama_token_data_array {
    struct llama_token_data * data;
    size_t                     size;
    bool                       sorted;
};

struct llama_batch {
    int32_t            n_tokens;
    llama_token *      token;
    float *            embd;
    llama_pos *        pos;
    int32_t *          n_seq_id;
    llama_seq_id **    seq_id;
    int8_t *           logits;
    llama_pos          all_pos_0;
    llama_pos          all_pos_1;
    llama_seq_id       all_seq_id;
};

struct llama_model_params {
    int32_t n_gpu_layers;
    int32_t split_mode;
    int32_t main_gpu;
    const float * tensor_split;
    void (*progress_callback)(void);
    void * progress_callback_user_data;
    void * kv_overrides;
    bool vocab_only;
    bool use_mmap;
    bool use_mlock;
};

struct llama_context_params {
    uint32_t seed;
    uint32_t n_ctx;
    uint32_t n_batch;
    uint32_t n_threads;
    uint32_t n_threads_batch;
    int8_t   rope_scaling_type;
    float    rope_freq_base;
    float    rope_freq_scale;
    float    yarn_ext_factor;
    float    yarn_attn_factor;
    float    yarn_beta_fast;
    float    yarn_beta_slow;
    uint32_t yarn_orig_ctx;
    void (*cb_eval)(void);
    void * cb_eval_user_data;
    int32_t type_k;
    int32_t type_v;
    bool mul_mat_q;
    bool logits_all;
    bool embedding;
    bool offload_kqv;
};

// ---------------------------------------------------------------------------
// MODERN ABI (upstream llama.cpp snapshot b21e4de; struct name preserved by
// the rename header, layouts verified against include/llama.h)
// ---------------------------------------------------------------------------

struct shim_llama_model_params {
    void *  devices;
    void *  tensor_buft_overrides;
    int32_t n_gpu_layers;
    int32_t split_mode;
    int32_t load_mode;
    int32_t main_gpu;
    const float * tensor_split;
    void (*progress_callback)(void);
    void * progress_callback_user_data;
    void * kv_overrides;
    bool vocab_only;
    bool check_tensors;
    bool use_extra_bufts;
    bool no_host;
    bool no_alloc;
    bool load_mtp;
};

struct shim_llama_context_params {
    uint32_t n_ctx;
    uint32_t n_batch;
    uint32_t n_ubatch;
    uint32_t n_seq_max;
    uint32_t n_rs_seq;
    uint32_t n_outputs_max;
    uint32_t n_outputs_max_per_seq;
    int32_t  n_threads;
    int32_t  n_threads_batch;
    int32_t  ctx_type;
    int32_t  rope_scaling_type;
    int32_t  pooling_type;
    int32_t  attention_type;
    int32_t  flash_attn_type;
    float    rope_freq_base;
    float    rope_freq_scale;
    float    yarn_ext_factor;
    float    yarn_attn_factor;
    float    yarn_beta_fast;
    float    yarn_beta_slow;
    uint32_t yarn_orig_ctx;
    float    defrag_thold;
    void (*cb_eval)(void);
    void * cb_eval_user_data;
    int32_t type_k;
    int32_t type_v;
    void (*abort_callback)(void);
    void * abort_callback_data;
    bool embeddings;
    bool offload_kqv;
    bool no_perf;
    bool op_offload;
    bool swa_full;
    bool kv_unified;
    void * samplers;
    size_t n_samplers;
    struct llama_context * ctx_other;
};

struct shim_llama_batch {
    int32_t            n_tokens;
    llama_token *      token;
    float *            embd;
    llama_pos *        pos;
    int32_t *           n_seq_id;
    llama_seq_id **    seq_id;
    int8_t *            logits;
};

// ---------------------------------------------------------------------------
// Layout pins
// ---------------------------------------------------------------------------

static_assert(sizeof(struct llama_token_data)      == 12, "llama_token_data layout mismatch (binding)");
static_assert(sizeof(struct llama_token_data_array) == 24, "llama_token_data_array layout mismatch (binding)");
static_assert(sizeof(struct llama_batch)            == 72, "llama_batch layout mismatch (binding)");
static_assert(sizeof(struct llama_model_params)     == 56, "llama_model_params layout mismatch (binding)");
static_assert(sizeof(struct llama_context_params)   == 88, "llama_context_params layout mismatch (binding)");

static_assert(sizeof(struct shim_llama_model_params)   == 72, "shim_llama_model_params layout mismatch (llama.h)");
static_assert(sizeof(struct shim_llama_context_params) == 160, "shim_llama_context_params layout mismatch (llama.h)");
static_assert(sizeof(struct shim_llama_batch)          == 56, "shim_llama_batch layout mismatch (llama.h)");

static_assert(offsetof(struct shim_llama_model_params, n_gpu_layers)  == 16, "model_params.n_gpu_layers offset");
static_assert(offsetof(struct shim_llama_model_params, tensor_split)  == 32, "model_params.tensor_split offset");
static_assert(offsetof(struct shim_llama_model_params, vocab_only)    == 64, "model_params.vocab_only offset");
static_assert(offsetof(struct shim_llama_model_params, load_mode)     == 24, "model_params.load_mode offset");

static_assert(offsetof(struct shim_llama_context_params, n_ctx)             == 0,  "ctx_params.n_ctx offset");
static_assert(offsetof(struct shim_llama_context_params, n_threads)         == 28, "ctx_params.n_threads offset");
static_assert(offsetof(struct shim_llama_context_params, rope_scaling_type) == 40, "ctx_params.rope_scaling_type offset");
static_assert(offsetof(struct shim_llama_context_params, rope_freq_base)    == 56, "ctx_params.rope_freq_base offset");
static_assert(offsetof(struct shim_llama_context_params, yarn_orig_ctx)     == 80, "ctx_params.yarn_orig_ctx offset");
static_assert(offsetof(struct shim_llama_context_params, cb_eval)           == 88, "ctx_params.cb_eval offset");
static_assert(offsetof(struct shim_llama_context_params, type_k)            == 104, "ctx_params.type_k offset");
static_assert(offsetof(struct shim_llama_context_params, embeddings)        == 128, "ctx_params.embeddings offset");
static_assert(offsetof(struct shim_llama_context_params, abort_callback)    == 112, "ctx_params.abort_callback offset");

static_assert(offsetof(struct shim_llama_batch, n_tokens) == 0,  "batch.n_tokens offset");
static_assert(offsetof(struct shim_llama_batch, token)    == 8,  "batch.token offset");
static_assert(offsetof(struct shim_llama_batch, embd)     == 16, "batch.embd offset");
static_assert(offsetof(struct shim_llama_batch, logits)   == 48, "batch.logits offset");

static_assert(offsetof(struct llama_batch, all_pos_0)     == 56, "old batch.all_pos_0 offset");
static_assert(offsetof(struct llama_batch, all_seq_id)    == 64, "old batch.all_seq_id offset");

static_assert(offsetof(struct llama_context_params, type_v)           == 76, "old ctx_params.type_v offset");
static_assert(offsetof(struct llama_context_params, mul_mat_q)        == 80, "old ctx_params.mul_mat_q offset");
static_assert(offsetof(struct llama_context_params, offload_kqv)      == 83, "old ctx_params.offload_kqv offset");

#endif // LLAMA_ABI_TYPES_H
