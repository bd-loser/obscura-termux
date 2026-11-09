# Obscura Termux (experimental)

Native Android/Bionic aarch64 port of Obscura v0.2.6. This is work in progress, not a verified release. No PRoot or glibc is intended.

The build uses Termux Rust and an **unofficial third-party** Android V8 archive from aidant/rusty_v8 v150.4.0, matching Obscura's locked `v8` version and `simdutf` feature. This is a binary dependency, not a source build of V8; its provenance and runtime compatibility need independent review. The rest builds from the pinned upstream source checkout. A local patch adds Android Bionic errno support to deno_core 0.412.0. There is no guarantee of Android support or upstream endorsement.

Check out Obscura v0.2.6 (commit `8534b401898ed17b62f69bdc3d5eb186bffb0d60`), copy this repository’s `termux` directory into the checkout, and run `bash termux/build.sh` in a Termux environment with matching Rust and development tools. `bash termux/smoke.sh` exercises JavaScript and screenshot output. The manual GitHub Actions workflow tries the same in termux-docker and uploads an artifact only after those smoke checks pass. Further checks are needed for networking, TLS, CDP, MCP, workers, PDF and stealth; the current build does not enable stealth.

Known local blocker: the installed Rust 1.98.1 and rust-std-aarch64-linux-android 1.95.0 do not match. Use matching Termux repository versions. No successful Android build or device test has been confirmed yet.
