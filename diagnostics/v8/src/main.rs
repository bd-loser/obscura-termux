fn main() {
    eprintln!("DIAG: create platform");
    let platform = v8::new_default_platform(0, false).make_shared();
    eprintln!("DIAG: initialize platform");
    v8::V8::initialize_platform(platform);
    eprintln!("DIAG: initialize V8");
    v8::V8::initialize();
    eprintln!("DIAG: create isolate");
    {
        let isolate = &mut v8::Isolate::new(v8::CreateParams::default());
        eprintln!("DIAG: create context");
        v8::scope!(let handle_scope, isolate);
        let context = v8::Context::new(handle_scope, Default::default());
        let scope = &v8::ContextScope::new(handle_scope, context);
        let code = v8::String::new(scope, "1+1").unwrap();
        let script = v8::Script::compile(scope, code, None).unwrap();
        let result = script.run(scope).unwrap();
        eprintln!("DIAG: JavaScript result {}", result.to_rust_string_lossy(scope));
    }
    unsafe { v8::V8::dispose() };
    v8::V8::dispose_platform();
}
