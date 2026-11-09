#!/usr/bin/env python3
"""Use a verified device-generated snapshot for this pinned cross-build."""
from pathlib import Path
import hashlib
import os

snapshot = Path(os.environ['OBSCURA_ANDROID_SNAPSHOT']).resolve()
if hashlib.sha256(snapshot.read_bytes()).hexdigest() != '9ba0455fa47694886a9af137bfa94098fa11e308207c35eb20d4aa3b7487c4d8':
    raise SystemExit('Android snapshot hash does not match pinned device build')
path = Path('crates/obscura-js/build.rs')
source = path.read_text()
needle = '    // Detect cross-compilation: build script runs on host, target differs.\n'
insertion = '''    // This device-generated snapshot belongs only to the pinned Android build.
    if let Ok(source) = std::env::var("OBSCURA_ANDROID_SNAPSHOT") {
        assert_eq!(std::env::var("TARGET").unwrap(), "aarch64-linux-android");
        std::fs::copy(&source, &snapshot_path).expect("copy Android snapshot");
        println!("cargo:rerun-if-env-changed=OBSCURA_ANDROID_SNAPSHOT");
        println!("cargo:rerun-if-changed={source}");
        println!("cargo:rustc-cfg=obscura_external_bootstrap");
        println!("cargo:rustc-env=OBSCURA_SNAPSHOT_PATH={}", snapshot_path.display());
        return;
    }

'''
if source.count(needle) != 1:
    raise SystemExit('Unexpected upstream snapshot build script; refusing to patch')
path.write_text(source.replace(needle, insertion + needle))
