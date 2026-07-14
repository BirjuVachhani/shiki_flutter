// Driver for the device-level frame benchmark.
//
// `integrationDriver()` enables VM timeline collection on the device and, when
// the test completes, writes the binding's reportData (the per-case build /
// raster / jank metrics assembled in frame_benchmark_test.dart) to
// build/integration_response_data.json.
//
// Run from website/:
//   flutter drive \
//     --driver=test_driver/perf_driver.dart \
//     --target=integration_test/frame_benchmark_test.dart \
//     -d macos --profile

import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver();
