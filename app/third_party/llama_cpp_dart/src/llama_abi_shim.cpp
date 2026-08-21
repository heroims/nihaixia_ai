// llama_abi_shim.cpp - ABI compatibility shim for llama_cpp_dart 0.0.7
//
// The ffigen binding in lib/src/llama_cpp.dart targets a pre-2024 llama.cpp:
// struct layouts and function signatures differ from the vendored llama.cpp
// (b5113). This translation unit re-exports the old binding surface and
// translates between the old and modern ABIs. It deliberately does NOT include
// llama.h: structs are defined locally (see llama_abi_types.h) and the modern
// llama.cpp symbols are renamed to llama_modern_* by llama_abi_rename.h, so the
// final shared library contains exactly one copy of each old name.

#include "llama_abi_types.h"

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>

struct llama_model;
struct llama_context;
struct llama_vocab;

extern "C" {

// Per-context RNG registry (implemented at the bottom of this file).
void register_rng(struct llama_context * ctx, uint32_t seed);
void unregister_rng(struct llama_context * ctx);
void reset_rng_registry(void);
static float next_rng_float(struct llama_context * ctx);

// ---------------------------------------------------------------------------
// Modern llama.cpp symbols (renamed by llama_abi_rename.h inside llama.cpp)
// ---------------------------------------------------------------------------

void     llama_modern_backend_init(void);
void     llama_modern_backend_free(void);

// llama.cpp log hook (NOT renamed by llama_abi_rename.h). Used to capture
// native log output while debugging iOS model load failures.
typedef void (*ggml_log_callback_fn)(int level, const char * text, void * user_data);
extern void llama_log_set(ggml_log_callback_fn log_callback, void * user_data);

static void shim_log_callback(int level, const char * text, void * user_data) {
    (void) level;
    (void) user_data;
    if (!text) return;
    const char * tmp = getenv("TMPDIR");
    if (!tmp) tmp = "/tmp";
    static char path[1024];
    snprintf(path, sizeof(path), "%s/llama_native_log.txt", tmp);
    FILE * f = fopen(path, "a");
    if (f) {
        fputs(text, f);
        fclose(f);
    }
}
struct shim_llama_model_params   llama_modern_model_default_params(void);
struct shim_llama_context_params llama_modern_context_default_params(void);
struct llama_model *  llama_modern_model_load_from_file(const char *, struct shim_llama_model_params);
struct llama_context * llama_modern_init_from_model(struct llama_model *, struct shim_llama_context_params);
void     llama_modern_model_free(struct llama_model *);
void     llama_modern_free(struct llama_context *);
uint32_t llama_modern_n_ctx(const struct llama_context *);
float *  llama_modern_get_logits(struct llama_context *);
int32_t  llama_modern_vocab_n_tokens(const struct llama_vocab *);
llama_token llama_modern_vocab_bos(const struct llama_vocab *);
llama_token llama_modern_vocab_eos(const struct llama_vocab *);
const struct llama_vocab * llama_modern_model_get_vocab(const struct llama_model *);
int32_t  llama_modern_tokenize(const struct llama_vocab *, const char *, int32_t, llama_token *, int32_t, bool, bool);
int32_t  llama_modern_token_to_piece(const struct llama_vocab *, llama_token, char *, int32_t, int32_t, bool);
int32_t  llama_modern_decode(struct llama_context *, struct shim_llama_batch);
void     llama_modern_kv_cache_clear(struct llama_context *);
struct shim_llama_batch llama_modern_batch_init(int32_t, int32_t, int32_t);
void     llama_modern_batch_free(struct shim_llama_batch);

// ---------------------------------------------------------------------------
// Old ABI exports (binding surface)
// ---------------------------------------------------------------------------

void llama_backend_init(bool numa) {
    (void) numa;
    llama_log_set(shim_log_callback, nullptr);
    llama_modern_backend_init();
}

void llama_backend_free(void) {
    llama_modern_backend_free();
    reset_rng_registry();
}

struct llama_model_params llama_model_default_params(void) {
    struct llama_model_params p;
    std::memset(&p, 0, sizeof(p));
    p.n_gpu_layers     = 0;
    p.split_mode       = 1; // LLAMA_SPLIT_MODE_LAYER (avoid NONE branch which requires >=1 device)
    p.main_gpu         = 0;
    p.tensor_split     = nullptr;
    p.progress_callback = nullptr;
    p.progress_callback_user_data = nullptr;
    p.kv_overrides     = nullptr;
    p.vocab_only       = false;
    p.use_mmap         = true;
    p.use_mlock        = false;
    return p;
}

struct llama_context_params llama_context_default_params(void) {
    struct llama_context_params p;
    std::memset(&p, 0, sizeof(p));
    p.seed             = 0xFFFFFFFFu; // LLAMA_DEFAULT_SEED
    p.n_ctx            = 512;
    p.n_batch          = 512;
    p.n_threads        = 8;
    p.n_threads_batch  = 8;
    p.rope_scaling_type = 0; // LLAMA_ROPE_SCALING_NONE
    p.rope_freq_base   = 0.0f;
    p.rope_freq_scale  = 0.0f;
    p.yarn_ext_factor  = -1.0f;
    p.yarn_attn_factor = 1.0f;
    p.yarn_beta_fast   = 32.0f;
    p.yarn_beta_slow   = 1.0f;
    p.yarn_orig_ctx    = 0;
    p.cb_eval          = nullptr;
    p.cb_eval_user_data = nullptr;
    p.type_k           = 1; // GGML_TYPE_F16
    p.type_v           = 1; // GGML_TYPE_F16
    p.mul_mat_q        = true;
    p.logits_all       = false;
    p.embedding        = false;
    p.offload_kqv      = false;
    return p;
}

// ---------------------------------------------------------------------------
// Model / context lifecycle
// ---------------------------------------------------------------------------

struct llama_model * llama_load_model_from_file(const char * path_model, struct llama_model_params params) {
    struct shim_llama_model_params m = llama_modern_model_default_params();
    m.devices                    = nullptr;
    m.tensor_buft_overrides      = nullptr;
    m.n_gpu_layers               = params.n_gpu_layers;
    m.split_mode                 = 1; // force LLAMA_SPLIT_MODE_LAYER; NONE requires >=1 device which is false on iOS (dynamic-link env)
    m.main_gpu                   = 0;
    m.tensor_split               = params.tensor_split;
    m.progress_callback          = params.progress_callback;
    m.progress_callback_user_data = params.progress_callback_user_data;
    m.kv_overrides               = params.kv_overrides;
    m.vocab_only                 = params.vocab_only;
    m.use_mmap                   = params.use_mmap;
    m.use_mlock                  = params.use_mlock;
    m.check_tensors              = false;
    return llama_modern_model_load_from_file(path_model, m);
}

void llama_free_model(struct llama_model * model) {
    llama_modern_model_free(model);
}

struct llama_context * llama_new_context_with_model(struct llama_model * model, struct llama_context_params params) {
    struct shim_llama_context_params c = llama_modern_context_default_params();
    c.n_ctx               = params.n_ctx;
    c.n_batch             = params.n_batch;
    c.n_ubatch            = params.n_batch;
    c.n_seq_max           = 1;
    c.n_threads           = (int32_t) params.n_threads;
    c.n_threads_batch     = (int32_t) params.n_threads_batch;
    c.rope_scaling_type   = params.rope_scaling_type;
    c.pooling_type        = 0;  // LLAMA_POOLING_TYPE_NONE
    c.attention_type      = 0;  // LLAMA_ATTENTION_TYPE_CAUSAL
    c.rope_freq_base      = params.rope_freq_base;
    c.rope_freq_scale     = params.rope_freq_scale;
    c.yarn_ext_factor     = params.yarn_ext_factor;
    c.yarn_attn_factor    = params.yarn_attn_factor;
    c.yarn_beta_fast      = params.yarn_beta_fast;
    c.yarn_beta_slow      = params.yarn_beta_slow;
    c.yarn_orig_ctx       = params.yarn_orig_ctx;
    c.defrag_thold        = -1.0f;
    c.cb_eval             = nullptr;
    c.cb_eval_user_data   = nullptr;
    c.type_k              = params.type_k;
    c.type_v              = params.type_v;
    c.logits_all          = params.logits_all;
    c.embeddings          = params.embedding;
    c.offload_kqv         = params.offload_kqv;
    c.flash_attn          = false;
    c.no_perf             = false;
    c.abort_callback      = nullptr;
    c.abort_callback_data = nullptr;

    struct llama_context * ctx = llama_modern_init_from_model(model, c);
    if (ctx != nullptr) {
        register_rng(ctx, params.seed);
    }
    return ctx;
}

void llama_free(struct llama_context * ctx) {
    if (ctx != nullptr) {
        unregister_rng(ctx);
    }
    llama_modern_free(ctx);
}

// ---------------------------------------------------------------------------
// Batch
// ---------------------------------------------------------------------------

struct llama_batch llama_batch_init(int32_t n_tokens, int32_t embd, int32_t n_seq_max) {
    struct shim_llama_batch sb = llama_modern_batch_init(n_tokens, embd, n_seq_max);
    struct llama_batch b;
    b.n_tokens   = sb.n_tokens;
    b.token      = sb.token;
    b.embd       = sb.embd;
    b.pos        = sb.pos;
    b.n_seq_id   = sb.n_seq_id;
    b.seq_id     = sb.seq_id;
    b.logits     = sb.logits;
    b.all_pos_0  = 0;
    b.all_pos_1  = 0;
    b.all_seq_id = 0;
    return b;
}

void llama_batch_free(struct llama_batch batch) {
    struct shim_llama_batch sb;
    sb.n_tokens = batch.n_tokens;
    sb.token    = batch.token;
    sb.embd     = batch.embd;
    sb.pos      = batch.pos;
    sb.n_seq_id = batch.n_seq_id;
    sb.seq_id   = batch.seq_id;
    sb.logits   = batch.logits;
    llama_modern_batch_free(sb);
}

// ---------------------------------------------------------------------------
// Tokenization / decoding
// ---------------------------------------------------------------------------

uint32_t llama_n_ctx(const struct llama_context * ctx) {
    return llama_modern_n_ctx(ctx);
}

int32_t llama_n_vocab(const struct llama_model * model) {
    return llama_modern_vocab_n_tokens(llama_modern_model_get_vocab(model));
}

int32_t llama_tokenize(const struct llama_model * model, const char * text, int32_t text_len,
                       llama_token * tokens, int32_t n_max_tokens, bool add_bos, bool special) {
    return llama_modern_tokenize(llama_modern_model_get_vocab(model), text, text_len, tokens,
                                 n_max_tokens, add_bos, special);
}

int32_t llama_token_to_piece(const struct llama_model * model, llama_token token,
                             char * buf, int32_t length) {
    // The old binding's 4-arg llama_token_to_piece rendered every token
    // unconditionally. b5113 hides CONTROL/UNKNOWN tokens unless special=true,
    // so pass special=true to preserve the classic behavior.
    return llama_modern_token_to_piece(llama_modern_model_get_vocab(model), token, buf,
                                       length, 0, true);
}

llama_token llama_token_bos(const struct llama_model * model) {
    return llama_modern_vocab_bos(llama_modern_model_get_vocab(model));
}

llama_token llama_token_eos(const struct llama_model * model) {
    return llama_modern_vocab_eos(llama_modern_model_get_vocab(model));
}

float * llama_get_logits(const struct llama_context * ctx) {
    return llama_modern_get_logits((struct llama_context *) ctx);
}

int32_t llama_decode(struct llama_context * ctx, struct llama_batch batch) {
    struct shim_llama_batch sb;
    sb.n_tokens = batch.n_tokens;
    sb.token    = batch.token;
    sb.embd     = batch.embd;
    sb.pos      = batch.pos;
    sb.n_seq_id = batch.n_seq_id;
    sb.seq_id   = batch.seq_id;
    sb.logits   = batch.logits;
    return llama_modern_decode(ctx, sb);
}

void llama_kv_cache_clear(struct llama_context * ctx) {
    llama_modern_kv_cache_clear(ctx);
}

// Stub: the binding calls this unconditionally at startup but the vendored
// llama.cpp no longer exposes it. No-op (returns 0 = success).
int32_t llama_model_apply_lora_from_file(struct llama_model * model, const char * path_lora,
                                         float scale, const char * path_base_model, int32_t n_threads) {
    (void) model; (void) path_lora; (void) scale; (void) path_base_model; (void) n_threads;
    return 0;
}

// ---------------------------------------------------------------------------
// Sampling (pure re-implementations of the classic llama.cpp algorithms)
// ---------------------------------------------------------------------------

void llama_sample_repetition_penalties(struct llama_context * ctx, struct llama_token_data_array * candidates,
                                       const llama_token * last_tokens, size_t penalty_last_n,
                                       float penalty_repeat, float penalty_freq, float penalty_present) {
    (void) ctx;
    if (penalty_repeat == 0.0f && penalty_freq == 0.0f && penalty_present == 0.0f) {
        return;
    }
    const int32_t n_vocab = candidates->size;
    int32_t * count = (int32_t *) std::calloc(n_vocab, sizeof(int32_t));
    if (count == nullptr) {
        return;
    }
    for (size_t i = 0; i < penalty_last_n; ++i) {
        const llama_token token = last_tokens[i];
        if (token >= 0 && token < n_vocab) {
            count[token]++;
        }
    }
    for (size_t i = 0; i < candidates->size; ++i) {
        const int32_t token = candidates->data[i].id;
        if (token < 0 || token >= n_vocab) {
            continue;
        }
        const int32_t c = count[token];
        if (c > 0) {
            const float penalty = penalty_repeat +
                                  penalty_freq * (float) c +
                                  penalty_present * (c > 0 ? 1.0f : 0.0f);
            candidates->data[i].logit -= penalty * std::log((float) c);
        }
    }
    std::free(count);
}

void llama_sample_top_k(struct llama_context * ctx, struct llama_token_data_array * candidates,
                        int32_t k, size_t min_keep) {
    (void) ctx;
    if (k <= 0) {
        k = (int32_t) candidates->size;
    }
    k = std::min(k, (int32_t) candidates->size);
    std::partial_sort(candidates->data, candidates->data + k, candidates->data + candidates->size,
                      [](const struct llama_token_data & a, const struct llama_token_data & b) {
                          return a.logit > b.logit;
                      });
    candidates->size = std::min(candidates->size, (size_t) k);
    if (min_keep > (size_t) candidates->size) {
        min_keep = (size_t) candidates->size;
    }
    if (min_keep > 0 && candidates->size > min_keep) {
        const float min_logit = candidates->data[min_keep - 1].logit;
        size_t new_size = 0;
        for (size_t i = 0; i < candidates->size; ++i) {
            if (candidates->data[i].logit >= min_logit) {
                new_size = i + 1;
            } else {
                break;
            }
        }
        candidates->size = new_size;
    }
}

void llama_sample_top_p(struct llama_context * ctx, struct llama_token_data_array * candidates,
                        float p, size_t min_keep) {
    (void) ctx;
    if (p >= 1.0f) {
        return;
    }
    const size_t n = candidates->size;
    if (n == 0) {
        return;
    }
    std::sort(candidates->data, candidates->data + n,
              [](const struct llama_token_data & a, const struct llama_token_data & b) {
                  return a.logit > b.logit;
              });
    float max_logit = candidates->data[0].logit;
    for (size_t i = 1; i < n; ++i) {
        if (candidates->data[i].logit > max_logit) {
            max_logit = candidates->data[i].logit;
        }
    }
    float * probs = (float *) std::malloc(n * sizeof(float));
    if (probs == nullptr) {
        return;
    }
    float sum = 0.0f;
    for (size_t i = 0; i < n; ++i) {
        probs[i] = std::exp(candidates->data[i].logit - max_logit);
        sum += probs[i];
    }
    float cumsum = 0.0f;
    size_t last_idx = n - 1;
    for (size_t i = 0; i < n; ++i) {
        cumsum += probs[i] / sum;
        if (cumsum >= p) {
            last_idx = i;
            break;
        }
    }
    while (last_idx + 1 < n && candidates->data[last_idx + 1].logit == candidates->data[last_idx].logit) {
        last_idx++;
    }
    if (min_keep > 0) {
        last_idx = std::max(last_idx, std::min(min_keep, n) - 1);
    }
    candidates->size = last_idx + 1;
    std::free(probs);
}

void llama_sample_temperature(struct llama_context * ctx, struct llama_token_data_array * candidates,
                              float temp) {
    (void) ctx;
    if (temp <= 0.0f) {
        size_t best = 0;
        for (size_t i = 1; i < candidates->size; ++i) {
            if (candidates->data[i].logit > candidates->data[best].logit) {
                best = i;
            }
        }
        candidates->data[0] = candidates->data[best];
        candidates->size = 1;
        return;
    }
    for (size_t i = 0; i < candidates->size; ++i) {
        candidates->data[i].p = std::exp(candidates->data[i].logit / temp);
    }
}

llama_token llama_sample_token(struct llama_context * ctx, struct llama_token_data_array * candidates) {
    if (candidates->size == 0) {
        return 0;
    }
    if (candidates->size == 1) {
        return candidates->data[0].id;
    }
    std::sort(candidates->data, candidates->data + candidates->size,
              [](const struct llama_token_data & a, const struct llama_token_data & b) {
                  return a.p > b.p;
              });
    float max_logit = candidates->data[0].logit;
    for (size_t i = 1; i < candidates->size; ++i) {
        if (candidates->data[i].logit > max_logit) {
            max_logit = candidates->data[i].logit;
        }
    }
    float sum = 0.0f;
    for (size_t i = 0; i < candidates->size; ++i) {
        candidates->data[i].p = std::exp(candidates->data[i].logit - max_logit);
        sum += candidates->data[i].p;
    }
    const float r = next_rng_float(ctx);
    float cur = 0.0f;
    for (size_t i = 0; i < candidates->size; ++i) {
        cur += candidates->data[i].p / sum;
        if (cur > r) {
            return candidates->data[i].id;
        }
    }
    return candidates->data[candidates->size - 1].id;
}

// ---------------------------------------------------------------------------
// Per-context RNG registry (PCG-style, mirrors the classic mt19937 seeding)
// ---------------------------------------------------------------------------

struct rng_entry {
    struct llama_context * ctx;
    uint64_t state;
};

static struct rng_entry g_rngs[16];
static size_t g_rng_count = 0;

static inline uint64_t rotl(uint64_t x, int k) {
    return (x << k) | (x >> (64 - k));
}

static uint64_t rng_next_raw(struct rng_entry * e) {
    const uint64_t old = e->state;
    e->state = old * 6364136223846793005ULL + 1442695040888963407ULL;
    const uint64_t xorshifted = ((old >> 18u) ^ old) >> 27u;
    const uint64_t rot = old >> 59u;
    return rotl(xorshifted, (int) rot);
}

void register_rng(struct llama_context * ctx, uint32_t seed) {
    for (size_t i = 0; i < g_rng_count; ++i) {
        if (g_rngs[i].ctx == ctx) {
            g_rngs[i].state = 0x853c49e6748fea9bULL ^ (uint64_t) seed;
            g_rngs[i].state = rng_next_raw(&g_rngs[i]);
            return;
        }
    }
    if (g_rng_count < sizeof(g_rngs) / sizeof(g_rngs[0])) {
        g_rngs[g_rng_count].ctx = ctx;
        g_rngs[g_rng_count].state = 0x853c49e6748fea9bULL ^ (uint64_t) seed;
        g_rngs[g_rng_count].state = rng_next_raw(&g_rngs[g_rng_count]);
        g_rng_count++;
    }
}

void unregister_rng(struct llama_context * ctx) {
    for (size_t i = 0; i < g_rng_count; ++i) {
        if (g_rngs[i].ctx == ctx) {
            g_rngs[i] = g_rngs[g_rng_count - 1];
            g_rng_count--;
            return;
        }
    }
}

void reset_rng_registry(void) {
    g_rng_count = 0;
}

static float next_rng_float(struct llama_context * ctx) {
    for (size_t i = 0; i < g_rng_count; ++i) {
        if (g_rngs[i].ctx == ctx) {
            const uint64_t v = rng_next_raw(&g_rngs[i]);
            return (float) (v >> 40) / (float) 0x1000000; // [0, 1)
        }
    }
    return 0.5f;
}

} // extern "C"
