#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
apt update -y
apt install -y rust rust-std-aarch64-linux-android clang lld make cmake pkg-config python git curl
mkdir -p "$HOME/obscura"
cp -R /workspace/upstream/. "$HOME/obscura/"
cp -R /workspace/termux "$HOME/obscura/termux"
cd "$HOME/obscura"
bash termux/build.sh
bash termux/smoke.sh
mkdir -p /out/package
cp target/release/obscura target/release/obscura-worker /out/package/
tar -czf /out/obscura-termux-aarch64-experimental.tar.gz -C /out/package .
