#!/usr/bin/env bash
set -euo pipefail
: "${ANDROID_NDK_HOME:?Android NDK is required}"
: "${GITHUB_WORKSPACE:?workspace is required}"
: "${RUNNER_TEMP:?runner temp is required}"
kit="$GITHUB_WORKSPACE"
cd "$kit/upstream"
[ "$(git rev-parse HEAD)" = 8534b401898ed17b62f69bdc3d5eb186bffb0d60 ] || { echo 'Unexpected upstream revision' >&2; exit 1; }
ndk="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64"
cc="$ndk/bin/aarch64-linux-android28-clang"
[ -x "$cc" ] || { echo 'NDK cross compiler missing' >&2; exit 1; }
mkdir -p "$RUNNER_TEMP/v8-mirror/v150.4.0"
mirror="$RUNNER_TEMP/v8-mirror/v150.4.0"
android=librusty_v8_simdutf_release_aarch64-linux-android.a.gz
host=librusty_v8_simdutf_release_x86_64-unknown-linux-gnu.a.gz
binding=src_binding_simdutf_release_aarch64-linux-android.rs
curl -fsSL --retry 3 "https://github.com/aidant/rusty_v8/releases/download/v150.4.0/$android" -o "$mirror/$android"
curl -fsSL --retry 3 "https://github.com/denoland/rusty_v8/releases/download/v150.4.0/$host" -o "$mirror/$host"
curl -fsSL --retry 3 "https://github.com/aidant/rusty_v8/releases/download/v150.4.0/$binding" -o "$mirror/$binding"
printf '%s  %s\n' 0e2d1d8c4101cc6ff7242dd7252835e63884d2bba7e9c8c6463443ee6625fee8 "$mirror/$android" | sha256sum -c -
printf '%s  %s\n' f48762ca10d1f1fc605a441c5ae430ec8ce1e9e80f14d78fbc42cb878c30b476 "$mirror/$host" | sha256sum -c -
printf '%s  %s\n' 7727826ae479bdb645e807239fb12d1f8e2e23de7a6cf16f5ee592690d1d8506 "$mirror/$binding" | sha256sum -c -
export RUSTY_V8_MIRROR="$RUNNER_TEMP/v8-mirror"
export RUSTY_V8_SRC_BINDING_PATH="$mirror/$binding"
export OBSCURA_ANDROID_SNAPSHOT="$RUNNER_TEMP/obscura-android-snapshot.bin"
gzip -dc "$kit/snapshots/obscura-v0.2.6-v8-150.4.0-android-arm64.bin.gz" > "$OBSCURA_ANDROID_SNAPSHOT"
"$cc" -c "$kit/termux/android-tls-align.S" -o "$RUNNER_TEMP/android-tls-align.o"
builtins=$(find "$ndk/lib/clang" -name libclang_rt.builtins-aarch64-android.a -type f | sort -V | tail -n 1)
[ -n "$builtins" ] || { echo 'Android compiler-rt builtins missing' >&2; exit 1; }
export CARGO_TARGET_AARCH64_LINUX_ANDROID_LINKER="$cc"
export CC_aarch64_linux_android="$cc" AR_aarch64_linux_android="$ndk/bin/llvm-ar"
export CARGO_TARGET_AARCH64_LINUX_ANDROID_RUSTFLAGS="-C link-arg=$RUNNER_TEMP/android-tls-align.o -C link-arg=-Wl,-u,__obscura_android_tls_align -C link-arg=$builtins -C link-arg=-Wl,-z,max-page-size=16384"
export CARGO_BUILD_JOBS=2 CARGO_INCREMENTAL=0
cargo fetch --locked
python3 "$kit/termux/patch-deno-core.py"
python3 "$kit/ci/patch-snapshot.py"
cargo metadata --offline --format-version 1 >/dev/null
cargo build --locked --release --target aarch64-linux-android -p obscura-cli --bins --features render
bin=target/aarch64-linux-android/release
"$ndk/bin/llvm-readelf" -lW "$bin/obscura" | tee "$RUNNER_TEMP/elf.txt"
grep -q '/system/bin/linker64' "$RUNNER_TEMP/elf.txt"
grep -Eq 'TLS +.*0x40$' "$RUNNER_TEMP/elf.txt"
mkdir -p "$kit/dist/package"
cp "$bin/obscura" "$bin/obscura-worker" "$kit/dist/package/"
tar -czf "$kit/dist/obscura-termux-aarch64-experimental.tar.gz" -C "$kit/dist/package" .
(cd "$kit/dist" && sha256sum obscura-termux-aarch64-experimental.tar.gz > SHA256SUMS)
