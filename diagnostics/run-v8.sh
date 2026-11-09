#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
apt update -y
apt install -y rust rust-std-aarch64-linux-android clang lld make python curl gdb
mkdir -p "$HOME/v8-diagnostic" "$HOME/v8-assets"
cp -R /workspace/diagnostics/v8/. "$HOME/v8-diagnostic/"
cd "$HOME/v8-assets"
base=https://github.com/aidant/rusty_v8/releases/download/v150.4.0
archive=librusty_v8_simdutf_release_aarch64-linux-android.a.gz
binding=src_binding_simdutf_release_aarch64-linux-android.rs
curl -fsSL "$base/$archive" -o "$archive"
curl -fsSL "$base/$binding" -o "$binding"
printf '%s  %s\n' 0e2d1d8c4101cc6ff7242dd7252835e63884d2bba7e9c8c6463443ee6625fee8 "$archive" | sha256sum -c -
printf '%s  %s\n' 7727826ae479bdb645e807239fb12d1f8e2e23de7a6cf16f5ee592690d1d8506 "$binding" | sha256sum -c -
export RUSTY_V8_ARCHIVE="$PWD/$archive" RUSTY_V8_SRC_BINDING_PATH="$PWD/$binding"
builtins=$(find "$PREFIX/lib/clang" -name libclang_rt.builtins-aarch64-android.a -type f | sort -V | tail -n 1)
[ -n "$builtins" ]
tls_object="$HOME/v8-assets/android-tls-align.o"
clang -c /workspace/termux/android-tls-align.S -o "$tls_object"
export RUSTFLAGS="-C link-arg=$tls_object -C link-arg=-Wl,-u,__obscura_android_tls_align -C link-arg=$builtins"
export CARGO_BUILD_JOBS=2
cd "$HOME/v8-diagnostic"
cargo fetch
python3 /workspace/termux/patch-deno-core.py
cargo build --release
tar -czf /out/v8-diagnostics.tar.gz -C target/release obscura-v8-diagnostic snapshot raw_snapshot
printf '\n=== V8 standalone under gdb ===\n'
gdb -q -batch -ex 'set disable-randomization off' -ex run -ex 'thread apply all bt' --args target/release/obscura-v8-diagnostic
printf '\n=== Empty deno_core snapshot under gdb ===\n'
gdb -q -batch -ex 'set disable-randomization off' -ex run -ex 'thread apply all bt' --args target/release/snapshot
printf '\n=== Snapshot with incremental marking disabled ===\n'
gdb -q -batch -ex 'set disable-randomization off' -ex run -ex 'thread apply all bt' --args target/release/snapshot --no-incremental-marking
printf '\n=== Direct V8 snapshot ===\n'
gdb -q -batch -ex 'set disable-randomization off' -ex run -ex 'thread apply all bt' --args target/release/raw_snapshot
