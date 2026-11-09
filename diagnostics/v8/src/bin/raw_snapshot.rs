fn main() {
    let platform = v8::new_default_platform(0, false).make_shared();
    v8::V8::initialize_platform(platform);
    v8::V8::initialize();
    eprintln!("DIAG: create raw V8 snapshot");
    let blob = {
        let mut creator = v8::Isolate::snapshot_creator(None, None);
        {
            v8::scope!(let scope, &mut creator);
            let context = v8::Context::new(scope, Default::default());
            let scope = &mut v8::ContextScope::new(scope, context);
            let code = v8::String::new(scope, "1+1").unwrap();
            v8::Script::compile(scope, code, None).unwrap().run(scope).unwrap();
            scope.set_default_context(context);
        }
        creator.create_blob(v8::FunctionCodeHandling::Clear).unwrap()
    };
    eprintln!("DIAG: raw V8 snapshot complete: {} bytes", blob.len());
}
