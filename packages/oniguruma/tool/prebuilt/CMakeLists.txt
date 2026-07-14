# CI-only glue that builds the prebuilt `oniguruma_ffi` shared library:
# Oniguruma + our shim (src/oniguruma_shim.c) folded into ONE self-contained
# dynamic library that exports the `onig_shim_*` symbols. Used by
# .github/workflows/prebuild-oniguruma.yml; not part of the published package.
#
# Invoke with the extracted upstream source tree:
#   cmake -S tool/prebuilt -B build -DONIG_SRC_DIR=/path/to/onig-6.9.10 \
#         <platform/arch toolchain flags>
#   cmake --build build --config Release
#
# We reuse upstream's own CMakeLists so its per-platform config.h detection is
# authoritative; we only force it to a static, position-independent build so it
# can be linked into our single shared library.

cmake_minimum_required(VERSION 3.15)
project(oniguruma_ffi C)

if(NOT DEFINED ONIG_SRC_DIR)
  message(FATAL_ERROR
    "Set -DONIG_SRC_DIR to the extracted upstream source (e.g. onig-6.9.10).")
endif()

set(SHIM_C "${CMAKE_CURRENT_SOURCE_DIR}/../../src/oniguruma_shim.c")
if(NOT EXISTS "${SHIM_C}")
  message(FATAL_ERROR "Shim not found at ${SHIM_C}")
endif()

# Build Oniguruma static + PIC, and skip its tests/docs/install extras.
set(BUILD_SHARED_LIBS OFF CACHE BOOL "" FORCE)
set(BUILD_TEST OFF CACHE BOOL "" FORCE)
set(INSTALL_DOCUMENTATION OFF CACHE BOOL "" FORCE)
set(INSTALL_EXAMPLES OFF CACHE BOOL "" FORCE)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

add_subdirectory("${ONIG_SRC_DIR}" onig EXCLUDE_FROM_ALL)

add_library(oniguruma_ffi SHARED "${SHIM_C}")
target_include_directories(oniguruma_ffi PRIVATE "${ONIG_SRC_DIR}/src")
target_link_libraries(oniguruma_ffi PRIVATE onig)

# The statically-linked onig must not be treated as a DLL import on Windows.
target_compile_definitions(oniguruma_ffi PRIVATE ONIG_STATIC)

# CMake already emits lib<name>.dylib / lib<name>.so / <name>.dll per platform,
# which is exactly what OS.dylibFileName('oniguruma_ffi') expects in the hook.
set_target_properties(oniguruma_ffi PROPERTIES OUTPUT_NAME oniguruma_ffi)
