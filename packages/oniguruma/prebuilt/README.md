# Prebuilt Oniguruma libraries

The build hook ([`../hook/build.dart`](../hook/build.dart)) bundles a library
from this directory as the `package:oniguruma/oniguruma_ffi` code asset when one
exists for the target platform/architecture. No compiler and no network are
needed on the consumer's machine in that case. When a target isn't covered here,
the hook falls back to downloading the pinned Oniguruma source release,
verifying its SHA-256, and compiling it locally.

Each library is a single dynamic library containing **both** Oniguruma and our
shim (`src/oniguruma_shim.c`), exporting the `onig_shim_*` symbols. Because
Oniguruma is archived at v6.9.10, these blobs never change.

## Layout (exactly what the hook looks for)

The hook resolves `prebuilt/<platform>/<arch>/<library>`:

```
prebuilt/
  macos/arm64/liboniguruma_ffi.dylib
  macos/x64/liboniguruma_ffi.dylib
  linux/arm64/liboniguruma_ffi.so
  linux/x64/liboniguruma_ffi.so
  windows/arm64/oniguruma_ffi.dll
  windows/x64/oniguruma_ffi.dll
  android/arm64/liboniguruma_ffi.so     # arm64-v8a
  android/arm/liboniguruma_ffi.so       # armeabi-v7a
  android/x64/liboniguruma_ffi.so       # x86_64
  android/ia32/liboniguruma_ffi.so      # x86
  ios/device/arm64/liboniguruma_ffi.dylib
  ios/simulator/arm64/liboniguruma_ffi.dylib
  ios/simulator/x64/liboniguruma_ffi.dylib
```

Architecture directory names map to Dart's `Architecture`:
`arm64`, `x64`, `arm` (32-bit ARM), `ia32` (32-bit x86), `riscv64`.
Filenames follow the platform convention (`lib<name>.dylib` / `lib<name>.so` /
`<name>.dll`) — this is what `OS.dylibFileName('oniguruma_ffi')` produces, so
keep them exact.

Any missing entry simply triggers the source-build fallback for that target;
partial coverage is fine.

## Populating this directory

These binaries are produced by the
[`prebuild-oniguruma`](../../../.github/workflows/prebuild-oniguruma.yml)
GitHub Actions workflow (manual `workflow_dispatch`; it builds every platform
including arm64 and uploads them as artifacts). To refresh:

1. Trigger the workflow from the Actions tab.
2. Download the combined **`oniguruma-prebuilt`** artifact zip from the run.
3. Unzip it here so the tree above is reproduced, then commit the blobs:

   ```sh
   unzip ~/Downloads/oniguruma-prebuilt.zip -d packages/oniguruma/prebuilt/
   git add packages/oniguruma/prebuilt
   ```

The artifact's root already contains the `<platform>/<arch>/<library>` tree
(e.g. `macos/arm64/liboniguruma_ffi.dylib`), so unzipping into `prebuilt/` drops
each file exactly where the hook looks for it.

## Forcing a source build

Consumers who prefer to compile from source (e.g. to avoid trusting these
blobs, or on an unlisted architecture) can opt out in their app's — or the
workspace root's — `pubspec.yaml`:

```yaml
hooks:
  user_defines:
    oniguruma:
      from_source: true
```
