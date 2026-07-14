// FFI bindings to the C shim (src/oniguruma_shim.c), resolved against the
// `package:oniguruma/oniguruma_ffi` code asset produced by hook/build.dart.
@DefaultAsset('package:oniguruma/oniguruma_ffi')
library;

import 'dart:ffi';

/// Opaque handle to a compiled multi-pattern scanner (C `ShimScanner*`).
final class ShimScanner extends Opaque {}

@Native<
    Pointer<ShimScanner> Function(
        Pointer<Pointer<Uint8>>, Pointer<Int32>, Int32)>(
  symbol: 'onig_shim_scanner_new',
)
external Pointer<ShimScanner> shimScannerNew(
    Pointer<Pointer<Uint8>> patterns, Pointer<Int32> patLens, int count);

@Native<Void Function(Pointer<ShimScanner>)>(symbol: 'onig_shim_scanner_free')
external void shimScannerFree(Pointer<ShimScanner> sc);

@Native<
    Int32 Function(Pointer<ShimScanner>, Pointer<Uint8>, Int32, Int32,
        Pointer<Int32>, Pointer<Int32>, Pointer<Int32>, Int32)>(
  symbol: 'onig_shim_find',
)
external int shimFind(
  Pointer<ShimScanner> sc,
  Pointer<Uint8> str,
  int endByte,
  int startByte,
  Pointer<Int32> outNumRegs,
  Pointer<Int32> beg,
  Pointer<Int32> end,
  int capacity,
);

@Native<Pointer<Char> Function()>(symbol: 'onig_shim_version')
external Pointer<Char> shimVersion();
