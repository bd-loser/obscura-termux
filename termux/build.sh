#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
# Experimental native aarch64 Android build. Run in a disposable Termux environment.
[ "$(rustc -vV | sed -n 's/^host: //p')" = aarch64-linux-android ] || { echo 'Requires native aarch64 Termux Rust' >&2; exit 1; }
# Upstream v8 150.4.0 has no Android archive. This third-party build must
# match Cargo.lock and the simdutf feature enabled by deno_core.
v8_dir="${HOME}/.cache/obscura-termux/v8-150.4.0"
mkdir -p "$v8_dir"
base=https://github.com/aidant/rusty_v8/releases/download/v150.4.0
archive=librusty_v8_simdutf_release_aarch64-linux-android.a.gz
binding=src_binding_simdutf_release_aarch64-linux-android.rs
curl -fsSL "$base/$archive" -o "$v8_dir/$archive"
curl -fsSL "$base/$binding" -o "$v8_dir/$binding"
printf '%s  %s\n' 0e2d1d8c4101cc6ff7242dd7252835e63884d2bba7e9c8c6463443ee6625fee8 "$v8_dir/$archive" | sha256sum -c -
printf '%s  %s\n' 7727826ae479bdb645e807239fb12d1f8e2e23de7a6cf16f5ee592690d1d8506 "$v8_dir/$binding" | sha256sum -c -
export RUSTY_V8_ARCHIVE="$v8_dir/$archive"
export RUSTY_V8_SRC_BINDING_PATH="$v8_dir/$binding"
export CARGO_INCREMENTAL=0
export CARGO_BUILD_JOBS="${CARGO_BUILD_JOBS:-2}"
cargo build --locked --release -p obscura-cli --bins --features render
