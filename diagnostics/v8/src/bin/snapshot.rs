fn main() {
    if std::env::args().any(|arg| arg == "--no-incremental-marking") {
        eprintln!("DIAG: disabling incremental marking");
        v8::V8::set_flags_from_string("--no-incremental-marking");
    }
    eprintln!("DIAG: creating empty deno_core snapshot");
    let output = deno_core::snapshot::create_snapshot(
        deno_core::snapshot::CreateSnapshotOptions {
            cargo_manifest_dir: env!("CARGO_MANIFEST_DIR"),
            startup_snapshot: None,
            skip_op_registration: true,
            extensions: vec![],
            extension_transpiler: None,
            with_runtime_cb: None,
        },
        None,
    ).expect("snapshot failed");
    eprintln!("DIAG: snapshot complete: {} bytes", output.output.len());
}
