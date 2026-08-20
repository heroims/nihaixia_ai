cmake_minimum_required(VERSION 3.10)

# Build vendored llama.cpp as a STATIC library with the classic ABI renamed to
# llama_modern_* (see include/llama_abi_rename.h), then compile the ABI shim
# into the shared library that carries the old llama_cpp_dart binding surface.
# Result: libllama.{so,dylib,dll} exposing the pre-2024 API.

set(BUILD_SHARED_LIBS OFF)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

if(ANDROID)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DANDROID_ARM_NEON=TRUE -DANDROID_TOOLCHAIN=clang")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -DANDROID_ARM_NEON=TRUE -DANDROID_TOOLCHAIN=clang")
endif()

# llama.cpp build configuration
set(LLAMA_STATIC ON CACHE BOOL "llama: enable static link libraries" FORCE)
set(LLAMA_NATIVE OFF CACHE BOOL "llama: disable -march=native flag" FORCE)
set(LLAMA_BUILD_COMMON OFF CACHE BOOL "llama: build common utils library" FORCE)
set(LLAMA_BUILD_TESTS OFF CACHE BOOL "llama: build tests" FORCE)
set(LLAMA_BUILD_EXAMPLES OFF CACHE BOOL "llama: build examples" FORCE)
set(LLAMA_BUILD_SERVER OFF CACHE BOOL "llama: build server example" FORCE)
set(LLAMA_BUILD_TOOLS OFF CACHE BOOL "llama: build tools" FORCE)

# Avoid output-name collision with the shim's shared library below.
add_subdirectory(./llama.cpp)

set_target_properties(llama PROPERTIES OUTPUT_NAME llama_static)

add_library(llama_abi_shim SHARED llama_abi_shim.cpp)
set_target_properties(llama_abi_shim PROPERTIES OUTPUT_NAME llama)
set_target_properties(llama_abi_shim PROPERTIES POSITION_INDEPENDENT_CODE ON)

# iOS needs the shim baked into a static archive (DynamicLibrary.process()).
if(LLAMA_ABI_SHIM_STATIC)
    set_target_properties(llama_abi_shim PROPERTIES LINKER_LANGUAGE CXX)
    add_library(llama_abi_shim_static STATIC llama_abi_shim.cpp)
    set_target_properties(llama_abi_shim_static PROPERTIES OUTPUT_NAME llama_abi_shim_static)
    set_target_properties(llama_abi_shim_static PROPERTIES POSITION_INDEPENDENT_CODE ON)
    target_include_directories(llama_abi_shim_static PRIVATE ./llama.cpp/include)
    target_link_libraries(llama_abi_shim_static PRIVATE llama ggml)
    if(ANDROID)
        target_compile_definitions(llama_abi_shim_static PRIVATE ANDROID)
    endif()
endif()
