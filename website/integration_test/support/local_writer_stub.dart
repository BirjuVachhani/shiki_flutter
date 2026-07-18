// Web stub for the local result writer.
library;

/// No-op on web: there is no local filesystem to write to. The frame metrics
/// still reach the caller through the binding's reportData (collected by the
/// driver) and the `[frame-bench]` console prints.
void writeLocalJson(String path, String json) {}
