#!/usr/bin/env python3
"""Patch the pinned deno_core crate in a disposable upstream checkout."""
import glob
import os
from pathlib import Path
import shutil

root = Path.cwd()
paths = glob.glob(os.path.expanduser('~/.cargo/registry/src/*/deno_core-0.412.0'))
if len(paths) != 1:
    raise SystemExit(f'Expected one deno_core 0.412.0 registry source, found {paths}')
dest = root / 'termux-vendor' / 'deno_core'
if dest.exists():
    raise SystemExit(f'{dest} already exists; use a clean upstream checkout')
shutil.copytree(paths[0], dest)
source = dest / 'uv_compat' / 'tty.rs'
text = source.read_text()
old = '  #[cfg(not(any(target_os = "macos", target_os = "linux")))]\n  fn errno_location()'
new = '''  // Android Bionic exposes errno via __errno, not __errno_location.
  #[cfg(target_os = "android")]
  fn errno_location() -> *mut c_int {
    unsafe { libc::__errno() }
  }

  #[cfg(not(any(target_os = "macos", target_os = "linux", target_os = "android")))]
  fn errno_location()'''
if text.count(old) != 1:
    raise SystemExit('deno_core source differs from expected version; refusing to patch')
source.write_text(text.replace(old, new))
manifest = root / 'Cargo.toml'
text = manifest.read_text()
if '[patch.crates-io]' in text:
    raise SystemExit('Workspace already has a crates.io patch section; update this patch script')
manifest.write_text(text + '\n[patch.crates-io]\ndeno_core = { path = "termux-vendor/deno_core" }\n')
