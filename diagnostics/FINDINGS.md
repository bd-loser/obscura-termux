# Android V8 snapshot investigation

Upstream Obscura v0.2.6 pins rusty_v8 150.4.0. Using the matching Android simdutf archive from aidant/rusty_v8:

- In termux-docker, ordinary V8 evaluation worked when the executable had 8-byte ELF TLS alignment. Creating a raw V8 snapshot and creating an empty deno_core snapshot both segfaulted inside V8 heap allocation/incremental marking. Disabling incremental marking resulted in an Abseil mutex abort, not a fix.
- Actual Android ARM64 Bionic refused to start that executable: `executable's TLS segment is underaligned: alignment is 8, needs to be at least 64`.
- Linking `android-tls-align.S` produced PT_TLS alignment 0x40. On an Android 14 ARM64 device, ordinary V8 evaluation, raw V8 snapshot creation, and empty deno_core snapshot creation all completed successfully.
- The same aligned diagnostic binaries hit V8 fatal aborts inside termux-docker while initializing the heap. This establishes a difference between this Docker image/runtime and the tested device, not the exact lower-level container defect.

GDB diagnostic workflows are investigative: GDB may exit successfully after catching a crash, so a green workflow does not imply the probes succeeded. Inspect the logs. Runs: 42691230851 and 42692928531.

The complete Obscura binary and its features are not yet built or tested on device. The V8 archive remains a third-party prebuilt binary; matching version and hashes are checked, but provenance has not been audited.
