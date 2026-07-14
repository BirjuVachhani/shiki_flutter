// Replays the exact findNextMatch query stream captured from shiki_flutter's
// tokenizer (the same /tmp/onig_bench/workload_*.bin used by the standalone C
// benchmark) through this Dart FFI Oniguruma bridge. This measures the REAL
// cost of using Oniguruma from Dart — FFI crossings included — so it can be
// compared directly against our pure-Dart engine and the no-FFI C number.
//
//   dart run benchmark/onig_replay.dart
// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:oniguruma/oniguruma.dart';

const _dir = '/tmp/onig_bench';

class _Reader {
  _Reader(this.bytes);
  final Uint8List bytes;
  int pos = 0;
  late final ByteData _bd = ByteData.sublistView(bytes);

  int i32() {
    final v = _bd.getInt32(pos, Endian.little);
    pos += 4;
    return v;
  }

  String str() {
    final len = i32();
    final s = utf8.decode(bytes.sublist(pos, pos + len));
    pos += len;
    return s;
  }
}

void main() {
  print('Oniguruma ${onigVersion()} (FFI)  vs our final Dart engine\n');
  for (final size in ['m', 'xl']) {
    final file = File('$_dir/workload_$size.bin');
    if (!file.existsSync()) {
      print('[$size] missing ${file.path} — skip');
      continue;
    }
    final r = _Reader(file.readAsBytesSync());

    // Scanners: build from the patterns our engine actually compiled (active),
    // so Oniguruma runs the same effective set.
    final nScanners = r.i32();
    final scanners = <OnigScanner>[];
    for (var s = 0; s < nScanners; s++) {
      final nPat = r.i32();
      final active = <String>[];
      for (var i = 0; i < nPat; i++) {
        final isActive = r.i32() == 1;
        final src = r.str();
        if (isActive) active.add(src);
      }
      scanners.add(OnigScanner(active));
    }

    // Lines -> reusable OnigStrings (encoded once, like vscode-oniguruma).
    final nLines = r.i32();
    final strings = <OnigString>[for (var i = 0; i < nLines; i++) OnigString(r.str())];

    // Ops: [scannerId, lineId, from, recIdx, recStart, recEnd].
    final nOps = r.i32();
    final ops = Int32List(nOps * 6);
    for (var i = 0; i < nOps * 6; i++) {
      ops[i] = r.i32();
    }

    // Warmup + validation pass (count matches for sanity).
    var matched = 0;
    for (var o = 0; o < nOps; o++) {
      final b = o * 6;
      final m = scanners[ops[b]].findNextMatch(strings[ops[b + 1]], ops[b + 2]);
      if (m != null) matched++;
    }

    // Timed passes (median of 5).
    final times = <int>[];
    for (var pass = 0; pass < 5; pass++) {
      final sw = Stopwatch()..start();
      for (var o = 0; o < nOps; o++) {
        final b = o * 6;
        scanners[ops[b]].findNextMatch(strings[ops[b + 1]], ops[b + 2]);
      }
      sw.stop();
      times.add(sw.elapsedMicroseconds);
    }
    times.sort();
    final medMs = times[times.length ~/ 2] / 1000.0;
    final opsPerSec = (nOps / (medMs / 1000)).round();

    print('[$size] ops=$nOps matched=$matched  '
        'oniguruma(FFI)=${medMs.toStringAsFixed(1)}ms  =$opsPerSec ops/s');

    for (final s in scanners) {
      s.dispose();
    }
    for (final s in strings) {
      s.dispose();
    }
  }
}
