const std = @import("std");
const Api = @import("../../api/schema.zig").Api;
const JavaScript = @import("../javascript.zig");
const QueryStringMap = @import("../../url.zig").QueryStringMap;
const CombinedScanner = @import("../../url.zig").CombinedScanner;
const bun = @import("root").bun;
const string = bun.string;
const JSC = bun.JSC;
const js = JSC.C;
const WebCore = @import("../webcore/response.zig");
const Bundler = bun.bundler;
const options = @import("../../options.zig");
const VirtualMachine = JavaScript.VirtualMachine;
const ScriptSrcStream = std.io.FixedBufferStream([]u8);
const ZigString = JSC.ZigString;
const Fs = @import("../../fs.zig");
const Base = @import("../base.zig");
const getAllocator = Base.getAllocator;
const JSObject = JSC.JSObject;
const JSError = Base.JSError;
const JSValue = bun.JSC.JSValue;
const JSGlobalObject = JSC.JSGlobalObject;
const strings = bun.strings;

const To = Base.To;
const Request = WebCore.Request;

const FetchEvent = WebCore.FetchEvent;
const MacroMap = @import("../../resolver/package_json.zig").MacroMap;
const TSConfigJSON = @import("../../resolver/tsconfig_json.zig").TSConfigJSON;
const PackageJSON = @import("../../resolver/package_json.zig").PackageJSON;
const logger = bun.logger;
const Loader = options.Loader;
const Target = options.Target;
const JSAst = bun.JSAst;
const Transpiler = @This();
const JSParser = bun.js_parser;
const JSPrinter = bun.js_printer;
const ScanPassResult = JSParser.ScanPassResult;
const Mimalloc = @import("../../mimalloc_arena.zig");
const Runtime = @import("../../runtime.zig").Runtime;
const JSLexer = bun.js_lexer;
const Expr = JSAst.Expr;

pub usingnamespace JSC.Codegen.JSTranspiler;

bundler: Bundler.Bundler,
arena: bun.ArenaAllocator,
transpiler_options: TranspilerOptions,
scan_pass_result: ScanPassResult,
buffer_writer: ?JSPrinter.BufferWriter = null,
log_level: logger.Log.Level = .err,

const default_transform_options: Api.TransformOptions = brk: {
    var opts = std.mem.zeroes(Api.TransformOptions);
    opts.disable_hmr = true;
    opts.target = Api.Target.browser;
    break :brk opts;
};

const TranspilerOptions = struct {
    transform: Api.TransformOptions = default_transform_options,
    default_loader: options.Loader = options.Loader.jsx,
    macro_map: MacroMap = MacroMap{},
    tsconfig: ?*TSConfigJSON = null,
    tsconfig_buf: []const u8 = "",
    macros_buf: []const u8 = "",
    log: logger.Log,
    runtime: Runtime.Features = Runtime.Features{ .top_level_await = true },
    tree_shaking: bool = false,
    trim_unused_imports: ?bool = null,
    inlining: bool = false,

    dead_code_elimination: bool = true,
    minify_whitespace: bool = false,
    minify_identifiers: bool = false,
    minify_syntax: bool = false,
    no_macros: bool = false,
};

// Mimalloc gets unstable if we try to move this to a different thread
// threadlocal var transform_buffer: bun.MutableString = undefined;
// threadlocal var transform_buffer_loaded: bool = false;

// This is going to be hard to not leak
pub const TransformTask = struct {
    input_code: JSC.Node.StringOrBuffer = JSC.Node.StringOrBuffer{ .buffer = .{} },
    output_code: bun.String = bun.String.empty,
    bundler: Bundler.Bundler = undefined,
    log: logger.Log,
    err: ?anyerror = null,
    macro_map: MacroMap = MacroMap{},
    tsconfig: ?*TSConfigJSON = null,
    loader: Loader,
    global: *JSGlobalObject,
    replace_exports: Runtime.Features.ReplaceableExport.Map = .{},

    pub usingnamespace bun.New(@This());

    pub const AsyncTransformTask = JSC.ConcurrentPromiseTask(TransformTask);
    pub const AsyncTransformEventLoopTask = AsyncTransformTask.EventLoopTask;

    pub fn create(transpiler: *Transpiler, input_code: bun.JSC.Node.StringOrBuffer, globalThis: *JSGlobalObject, loader: Loader) !*AsyncTransformTask {
        var transform_task = TransformTask.new(.{
            .input_code = input_code,
            .bundler = undefined,
            .global = globalThis,
            .macro_map = transpiler.transpiler_options.macro_map,
            .tsconfig = transpiler.transpiler_options.tsconfig,
            .log = logger.Log.init(bun.default_allocator),
            .loader = loader,
            .replace_exports = transpiler.transpiler_options.runtime.replace_exports,
        });
        transform_task.log.level = transpiler.transpiler_options.log.level;
        transform_task.bundler = transpiler.bundler;
        transform_task.bundler.linker.resolver = &transform_task.bundler.resolver;

        transform_task.bundler.setLog(&transform_task.log);
        transform_task.bundler.setAllocator(bun.default_allocator);
        return try AsyncTransformTask.createOnJSThread(bun.default_allocator, globalThis, transform_task);
    }

    pub fn run(this: *TransformTask) void {
        const name = this.loader.stdinName();
        const source = logger.Source.initPathString(name, this.input_code.slice());

        const prev_memory_allocators = .{ JSAst.Stmt.Data.Store.memory_allocator, JSAst.Expr.Data.Store.memory_allocator };
        defer {
            JSAst.Stmt.Data.Store.memory_allocator = prev_memory_allocators[0];
            JSAst.Expr.Data.Store.memory_allocator = prev_memory_allocators[1];
        }

        var arena = Mimalloc.Arena.init() catch unreachable;

        const allocator = arena.allocator();

        var ast_memory_allocator = allocator.create(JSAst.ASTMemoryAllocator) catch bun.outOfMemory();
        ast_memory_allocator.* = .{
            .allocator = allocator,
        };
        ast_memory_allocator.reset();

        JSAst.Stmt.Data.Store.memory_allocator = ast_memory_allocator;
        JSAst.Expr.Data.Store.memory_allocator = ast_memory_allocator;

        defer {
            JSAst.Stmt.Data.Store.reset();
            JSAst.Expr.Data.Store.reset();
            arena.deinit();
        }

        this.bundler.setAllocator(allocator);
        this.bundler.setLog(&this.log);
        this.log.msgs.allocator = bun.default_allocator;

        const jsx = if (this.tsconfig != null)
            this.tsconfig.?.mergeJSX(this.bundler.options.jsx)
        else
            this.bundler.options.jsx;

        const parse_options = Bundler.Bundler.ParseOptions{
            .allocator = allocator,
            .macro_remappings = this.macro_map,
            .dirname_fd = .zero,
            .file_descriptor = null,
            .loader = this.loader,
            .jsx = jsx,
            .path = source.path,
            .virtual_source = &source,
            .replace_exports = this.replace_exports,
            // .allocator = this.
        };

        const parse_result = this.bundler.parse(parse_options, null) orelse {
            this.err = error.ParseError;
            return;
        };

        if (parse_result.empty) {
            this.output_code = bun.String.empty;
            return;
        }

        var buffer_writer = JSPrinter.BufferWriter.init(allocator) catch |err| {
            this.err = err;
            return;
        };
        buffer_writer.buffer.list.ensureTotalCapacity(allocator, 512) catch unreachable;
        buffer_writer.reset();

        // defer {
        //     transform_buffer = buffer_writer.buffer;
        // }

        var printer = JSPrinter.BufferPrinter.init(buffer_writer);
        const printed = this.bundler.print(parse_result, @TypeOf(&printer), &printer, .esm_ascii) catch |err| {
            this.err = err;
            return;
        };

        if (printed > 0) {
            buffer_writer = printer.ctx;
            buffer_writer.buffer.list.items = buffer_writer.written;
            this.output_code = bun.String.createLatin1(buffer_writer.written);
        } else {
            this.output_code = bun.String.empty;
        }
    }

    pub fn then(this: *TransformTask, promise: *JSC.JSPromise) void {
        if (this.log.hasAny() or this.err != null) {
            const error_value: JSValue = brk: {
                if (this.err) |err| {
                    if (!this.log.hasAny()) {
                        break :brk JSC.BuildMessage.create(
                            this.global,
                            bun.default_allocator,
                            logger.Msg{
                                .data = logger.Data{ .text = bun.asByteSlice(@errorName(err)) },
                            },
                        );
                    }
                }

                break :brk this.log.toJS(this.global, bun.default_allocator, "Transform failed");
            };

            promise.reject(this.global, error_value);
            return;
        }

        const global = this.global;
        const code = this.output_code;
        this.output_code = bun.String.empty;
        this.deinit();

        finish(code, global, promise);
    }

    noinline fn finish(code: bun.String, global: *JSGlobalObject, promise: *JSC.JSPromise) void {
        promise.resolve(global, code.toJS(global));
        code.deref();
    }

    pub fn deinit(this: *TransformTask) void {
        this.log.deinit();
        this.input_code.deinitAndUnprotect();
        this.output_code.deref();
        if (this.tsconfig) |tsconfig| {
            tsconfig.destroy();
        }

        this.destroy();
    }
};

fn exportReplacementValue(value: JSValue, globalThis: *JSGlobalObject) ?JSAst.Expr {
    if (value.isBoolean()) {
        return Expr{
            .data = .{
                .e_boolean = .{
                    .value = value.toBoolean(),
                },
            },
            .loc = logger.Loc.Empty,
        };
    }

    if (value.isNumber()) {
        return Expr{
            .data = .{
                .e_number = .{ .value = value.asNumber() },
            },
            .loc = logger.Loc.Empty,
        };
    }

    if (value.isNull()) {
        return Expr{
            .data = .{
                .e_null = .{},
            },
            .loc = logger.Loc.Empty,
        };
    }

    if (value.isUndefined()) {
        return Expr{
            .data = .{
                .e_undefined = .{},
            },
            .loc = logger.Loc.Empty,
        };
    }

    if (value.isString()) {
        const str = JSAst.E.String{
            .data = std.fmt.allocPrint(bun.default_allocator, "{}", .{value.getZigString(globalThis)}) catch unreachable,
        };
        const out = bun.default_allocator.create(JSAst.E.String) catch unreachable;
        out.* = str;
        return Expr{
            .data = .{
                .e_string = out,
            },
            .loc = logger.Loc.Empty,
        };
    }

    return null;
}

fn transformOptionsFromJSC(globalObject: JSC.C.JSContextRef, temp_allocator: std.mem.Allocator, args: *JSC.Node.ArgumentsSlice) (bun.JSError || bun.OOM)!TranspilerOptions {
    const globalThis = globalObject;
    const object = args.next() orelse return TranspilerOptions{ .log = logger.Log.init(temp_allocator) };
    if (object.isUndefinedOrNull()) return TranspilerOptions{ .log = logger.Log.init(temp_allocator) };

    args.eat();
    var allocator = args.arena.allocator();

    var transpiler = TranspilerOptions{
        .default_loader = .jsx,
        .transform = default_transform_options,
        .log = logger.Log.init(allocator),
    };

    if (!object.isObject()) {
        globalObject.throwInvalidArguments("Expected an object", .{});
        return error.JSError;
    }

    if (try object.getTruthy(globalObject, "define")) |define| {
        define: {
            if (define.isUndefinedOrNull()) {
                break :define;
            }

            if (!define.isObject()) {
                globalObject.throwInvalidArguments("define must be an object", .{});
                return error.JSError;
            }

            var define_iter = JSC.JSPropertyIterator(.{
                .skip_empty_name = true,

                .include_value = true,
            }).init(globalThis, define);
            defer define_iter.deinit();

            // cannot be a temporary because it may be loaded on different threads.
            var map_entries = allocator.alloc([]u8, define_iter.len * 2) catch unreachable;
            var names = map_entries[0..define_iter.len];

            var values = map_entries[define_iter.len..];

            while (define_iter.next()) |prop| {
                const property_value = define_iter.value;
                const value_type = property_value.jsType();

                if (!value_type.isStringLike()) {
                    globalObject.throwInvalidArguments("define \"{s}\" must be a JSON string", .{prop});
                    return error.JSError;
                }

                names[define_iter.i] = prop.toOwnedSlice(allocator) catch unreachable;
                var val = JSC.ZigString.init("");
                property_value.toZigString(&val, globalThis);
                if (val.len == 0) {
                    val = JSC.ZigString.init("\"\"");
                }
                values[define_iter.i] = std.fmt.allocPrint(allocator, "{}", .{val}) catch unreachable;
            }

            transpiler.transform.define = Api.StringMap{
                .keys = names,
                .values = values,
            };
        }
    }

    if (object.get(globalThis, "external")) |external| {
        external: {
            if (external.isUndefinedOrNull()) break :external;

            const toplevel_type = external.jsType();
            if (toplevel_type.isStringLike()) {
                var zig_str = JSC.ZigString.init("");
                external.toZigString(&zig_str, globalThis);
                if (zig_str.len == 0) break :external;
                var single_external = allocator.alloc(string, 1) catch unreachable;
                single_external[0] = std.fmt.allocPrint(allocator, "{}", .{external}) catch unreachable;
                transpiler.transform.external = single_external;
            } else if (toplevel_type.isArray()) {
                const count = external.getLength(globalThis);
                if (count == 0) break :external;

                var externals = allocator.alloc(string, count) catch unreachable;
                var iter = external.arrayIterator(globalThis);
                var i: usize = 0;
                while (iter.next()) |entry| {
                    if (!entry.jsType().isStringLike()) {
                        globalObject.throwInvalidArguments("external must be a string or string[]", .{});
                        return error.JSError;
                    }

                    var zig_str = JSC.ZigString.init("");
                    entry.toZigString(&zig_str, globalThis);
                    if (zig_str.len == 0) continue;
                    externals[i] = std.fmt.allocPrint(allocator, "{}", .{external}) catch unreachable;
                    i += 1;
                }

                transpiler.transform.external = externals[0..i];
            } else {
                globalObject.throwInvalidArguments("external must be a string or string[]", .{});
                return error.JSError;
            }
        }
    }

    if (object.get(globalThis, "loader")) |loader| {
        if (try Loader.fromJS(globalThis, loader)) |resolved| {
            if (!resolved.isJavaScriptLike()) {
                globalObject.throwInvalidArguments("only JavaScript-like loaders supported for now", .{});
                return error.JSError;
            }

            transpiler.default_loader = resolved;
        }
    }

    if (object.get(globalThis, "target")) |target| {
        if (try Target.fromJS(globalThis, target)) |resolved| {
            transpiler.transform.target = resolved.toAPI();
        }
    }

    if (object.get(globalThis, "tsconfig")) |tsconfig| {
        tsconfig: {
            if (tsconfig.isUndefinedOrNull()) break :tsconfig;
            const kind = tsconfig.jsType();
            var out = bun.String.empty;
            defer out.deref();

            if (kind.isArray()) {
                globalObject.throwInvalidArguments("tsconfig must be a string or object", .{});
                return error.JSError;
            }

            if (!kind.isStringLike()) {
                tsconfig.jsonStringify(globalThis, 0, &out);
            } else {
                out = tsconfig.toBunString(globalThis);
            }

            if (out.isEmpty()) break :tsconfig;
            transpiler.tsconfig_buf = out.toOwnedSlice(allocator) catch bun.outOfMemory();

            // TODO: JSC -> Ast conversion
            if (TSConfigJSON.parse(
                allocator,
                &transpiler.log,
                logger.Source.initPathString("tsconfig.json", transpiler.tsconfig_buf),
                &VirtualMachine.get().bundler.resolver.caches.json,
            ) catch null) |parsed_tsconfig| {
                transpiler.tsconfig = parsed_tsconfig;
            }
        }
    }

    transpiler.runtime.allow_runtime = false;
    transpiler.runtime.use_import_meta_require = switch (transpiler.transform.target orelse .browser) {
        .bun, .bun_macro => true,
        else => false,
    };

    if (try object.getTruthy(globalThis, "macro")) |macros| {
        macros: {
            if (macros.isUndefinedOrNull()) break :macros;
            if (macros.isBoolean()) {
                transpiler.no_macros = !macros.asBoolean();
                break :macros;
            }
            const kind = macros.jsType();
            const is_object = kind.isObject();
            if (!(kind.isStringLike() or is_object)) {
                globalObject.throwInvalidArguments("macro must be an object", .{});
                return error.JSError;
            }

            var out = bun.String.empty;
            defer out.deref();
            // TODO: write a converter between JSC types and Bun AST types
            if (is_object) {
                macros.jsonStringify(globalThis, 0, &out);
            } else {
                out = macros.toBunString(globalThis);
            }

            if (out.isEmpty()) break :macros;
            transpiler.macros_buf = out.toOwnedSlice(allocator) catch bun.outOfMemory();
            const source = logger.Source.initPathString("macros.json", transpiler.macros_buf);
            const json = (VirtualMachine.get().bundler.resolver.caches.json.parseJSON(
                &transpiler.log,
                source,
                allocator,
            ) catch null) orelse break :macros;
            transpiler.macro_map = PackageJSON.parseMacrosJSON(allocator, json, &transpiler.log, &source);
        }
    }

    if (try object.getBooleanLoose(globalThis, "autoImportJSX")) |flag| {
        transpiler.runtime.auto_import_jsx = flag;
    }

    if (try object.getBooleanLoose(globalThis, "allowBunRuntime")) |flag| {
        transpiler.runtime.allow_runtime = flag;
    }

    if (try object.getBooleanLoose(globalThis, "inline")) |flag| {
        transpiler.runtime.inlining = flag;
    }

    if (try object.getBooleanLoose(globalThis, "minifyWhitespace")) |flag| {
        transpiler.minify_whitespace = flag;
    }

    if (try object.getBooleanLoose(globalThis, "deadCodeElimination")) |flag| {
        transpiler.dead_code_elimination = flag;
    }

    if (try object.getTruthy(globalThis, "minify")) |minify| {
        if (minify.isBoolean()) {
            transpiler.minify_whitespace = minify.coerce(bool, globalThis);
            transpiler.minify_syntax = transpiler.minify_whitespace;
            transpiler.minify_identifiers = transpiler.minify_syntax;
        } else if (minify.isObject()) {
            if (try minify.getBooleanLoose(globalThis, "whitespace")) |whitespace| {
                transpiler.minify_whitespace = whitespace;
            }
            if (try minify.getBooleanLoose(globalThis, "syntax")) |syntax| {
                transpiler.minify_syntax = syntax;
            }
            if (try minify.getBooleanLoose(globalThis, "identifiers")) |syntax| {
                transpiler.minify_identifiers = syntax;
            }
        } else {
            globalObject.throwInvalidArguments("Expected minify to be a boolean or an object", .{});
            return error.JSError;
        }
    }

    if (object.get(globalThis, "sourcemap")) |flag| {
        if (flag.isBoolean() or flag.isUndefinedOrNull()) {
            if (flag.toBoolean()) {
                transpiler.transform.source_map = .@"inline";
            } else {
                transpiler.transform.source_map = .none;
            }
        } else {
            if (options.SourceMapOption.Map.fromJS(globalObject, flag)) |source| {
                transpiler.transform.source_map = source.toAPI();
            } else {
                globalObject.throwInvalidArguments("sourcemap must be one of \"inline\", \"linked\", \"external\", or \"none\"", .{});
                return error.JSError;
            }
        }
    }

    if (try object.getOptionalEnum(globalThis, "packages", options.PackagesOption)) |packages| {
        transpiler.transform.packages = packages.toAPI();
    }

    var tree_shaking: ?bool = null;
    if (try object.getBooleanLoose(globalThis, "treeShaking")) |treeShaking| {
        tree_shaking = treeShaking;
    }

    var trim_unused_imports: ?bool = null;
    if (try object.getBooleanLoose(globalThis, "trimUnusedImports")) |trimUnusedImports| {
        trim_unused_imports = trimUnusedImports;
    }

    if (try object.getTruthy(globalThis, "exports")) |exports| {
        if (!exports.isObject()) {
            globalObject.throwInvalidArguments("exports must be an object", .{});
            return error.JSError;
        }

        var replacements = Runtime.Features.ReplaceableExport.Map{};
        errdefer replacements.clearAndFree(bun.default_allocator);

        if (try exports.getTruthy(globalThis, "eliminate")) |eliminate| {
            if (!eliminate.jsType().isArray()) {
                globalObject.throwInvalidArguments("exports.eliminate must be an array", .{});
                return error.JSError;
            }

            var total_name_buf_len: u32 = 0;
            var string_count: u32 = 0;
            const iter = JSC.JSArrayIterator.init(eliminate, globalThis);
            {
                var length_iter = iter;
                while (length_iter.next()) |value| {
                    if (value.isString()) {
                        const length = @as(u32, @truncate(value.getLength(globalThis)));
                        string_count += @as(u32, @intFromBool(length > 0));
                        total_name_buf_len += length;
                    }
                }
            }

            if (total_name_buf_len > 0) {
                var buf = try std.ArrayListUnmanaged(u8).initCapacity(bun.default_allocator, total_name_buf_len);
                try replacements.ensureUnusedCapacity(bun.default_allocator, string_count);
                {
                    var length_iter = iter;
                    while (length_iter.next()) |value| {
                        if (!value.isString()) continue;
                        const str = value.getZigString(globalThis);
                        if (str.len == 0) continue;
                        const name = std.fmt.bufPrint(buf.items.ptr[buf.items.len..buf.capacity], "{}", .{str}) catch {
                            globalObject.throwInvalidArguments("Error reading exports.eliminate. TODO: utf-16", .{});
                            return error.JSError;
                        };
                        buf.items.len += name.len;
                        if (name.len > 0) {
                            replacements.putAssumeCapacity(name, .{ .delete = {} });
                        }
                    }
                }
            }
        }

        if (try exports.getTruthy(globalThis, "replace")) |replace| {
            if (!replace.isObject()) {
                globalObject.throwInvalidArguments("replace must be an object", .{});
                return error.JSError;
            }

            var iter = JSC.JSPropertyIterator(.{
                .skip_empty_name = true,
                .include_value = true,
            }).init(globalThis, replace);

            if (iter.len > 0) {
                errdefer iter.deinit();
                try replacements.ensureUnusedCapacity(bun.default_allocator, iter.len);

                // We cannot set the exception before `try` because it could be
                // a double free with the `errdefer`.
                defer if (globalThis.hasException()) {
                    iter.deinit();
                    for (replacements.keys()) |key| {
                        bun.default_allocator.free(@constCast(key));
                    }
                    replacements.clearAndFree(bun.default_allocator);
                };

                while (iter.next()) |key_| {
                    const value = iter.value;
                    if (value == .zero) continue;

                    const key = try key_.toOwnedSlice(bun.default_allocator);

                    if (!JSLexer.isIdentifier(key)) {
                        globalObject.throwInvalidArguments("\"{s}\" is not a valid ECMAScript identifier", .{key});
                        bun.default_allocator.free(key);
                        return error.JSError;
                    }

                    const entry = replacements.getOrPutAssumeCapacity(key);

                    if (exportReplacementValue(value, globalThis)) |expr| {
                        entry.value_ptr.* = .{ .replace = expr };
                        continue;
                    }

                    if (value.isObject() and value.getLength(globalObject) == 2) {
                        const replacementValue = JSC.JSObject.getIndex(value, globalThis, 1);
                        if (exportReplacementValue(replacementValue, globalThis)) |to_replace| {
                            const replacementKey = JSC.JSObject.getIndex(value, globalThis, 0);
                            var slice = (try replacementKey.toSlice(globalThis, bun.default_allocator).cloneIfNeeded(bun.default_allocator));
                            const replacement_name = slice.slice();

                            if (!JSLexer.isIdentifier(replacement_name)) {
                                globalObject.throwInvalidArguments("\"{s}\" is not a valid ECMAScript identifier", .{replacement_name});
                                slice.deinit();
                                return error.JSError;
                            }

                            entry.value_ptr.* = .{
                                .inject = .{
                                    .name = replacement_name,
                                    .value = to_replace,
                                },
                            };
                            continue;
                        }
                    }

                    globalObject.throwInvalidArguments("exports.replace values can only be string, null, undefined, number or boolean", .{});
                    return error.JSError;
                }
            }
        }

        tree_shaking = tree_shaking orelse (replacements.count() > 0);
        transpiler.runtime.replace_exports = replacements;
    }

    if (try object.getTruthy(globalThis, "logLevel")) |logLevel| {
        if (logger.Log.Level.Map.fromJS(globalObject, logLevel)) |level| {
            transpiler.log.level = level;
        } else {
            globalObject.throwInvalidArguments("logLevel must be one of \"verbose\", \"debug\", \"info\", \"warn\", or \"error\"", .{});
            return error.JSError;
        }
    }

    transpiler.tree_shaking = tree_shaking orelse false;
    transpiler.trim_unused_imports = trim_unused_imports orelse transpiler.tree_shaking;

    return transpiler;
}

pub fn constructor(globalThis: *JSC.JSGlobalObject, callframe: *JSC.CallFrame) bun.JSError!*Transpiler {
    var temp = bun.ArenaAllocator.init(getAllocator(globalThis));
    const arguments = callframe.arguments(3);
    var args = JSC.Node.ArgumentsSlice.init(
        globalThis.bunVM(),
        arguments.slice(),
    );

    defer temp.deinit();
    const transpiler_options: TranspilerOptions = if (arguments.len > 0)
        try transformOptionsFromJSC(globalThis, temp.allocator(), &args)
    else
        TranspilerOptions{ .log = logger.Log.init(getAllocator(globalThis)) };

    if (globalThis.hasException()) {
        return error.JSError;
    }

    const allocator = getAllocator(globalThis);

    if ((transpiler_options.log.warnings + transpiler_options.log.errors) > 0) {
        return globalThis.throwValue2(transpiler_options.log.toJS(globalThis, allocator, "Failed to create transpiler"));
    }

    var log = try allocator.create(logger.Log);
    log.* = transpiler_options.log;
    var bundler = Bundler.Bundler.init(
        allocator,
        log,
        transpiler_options.transform,
        JavaScript.VirtualMachine.get().bundler.env,
    ) catch |err| {
        if ((log.warnings + log.errors) > 0) {
            return globalThis.throwValue2(log.toJS(globalThis, allocator, "Failed to create transpiler"));
        }

        return globalThis.throwError(err, "Error creating transpiler");
    };
    bundler.options.no_macros = transpiler_options.no_macros;
    bundler.configureLinkerWithAutoJSX(false);
    bundler.options.env.behavior = .disable;
    bundler.configureDefines() catch |err| {
        if ((log.warnings + log.errors) > 0) {
            return globalThis.throwValue2(log.toJS(globalThis, allocator, "Failed to load define"));
        }
        return globalThis.throwError(err, "Failed to load define");
    };

    if (transpiler_options.macro_map.count() > 0) {
        bundler.options.macro_remap = transpiler_options.macro_map;
    }

    bundler.options.dead_code_elimination = transpiler_options.dead_code_elimination;
    bundler.options.minify_whitespace = transpiler_options.minify_whitespace;

    // Keep defaults for these
    if (transpiler_options.minify_syntax)
        bundler.options.minify_syntax = true;

    if (transpiler_options.minify_identifiers)
        bundler.options.minify_identifiers = true;

    bundler.options.transform_only = !bundler.options.allow_runtime;

    bundler.options.tree_shaking = transpiler_options.tree_shaking;
    bundler.options.trim_unused_imports = transpiler_options.trim_unused_imports;
    bundler.options.allow_runtime = transpiler_options.runtime.allow_runtime;
    bundler.options.auto_import_jsx = transpiler_options.runtime.auto_import_jsx;
    bundler.options.inlining = transpiler_options.runtime.inlining;
    bundler.options.hot_module_reloading = transpiler_options.runtime.hot_module_reloading;
    bundler.options.react_fast_refresh = false;

    const transpiler = try allocator.create(Transpiler);
    transpiler.* = Transpiler{
        .transpiler_options = transpiler_options,
        .bundler = bundler,
        .arena = args.arena,
        .scan_pass_result = ScanPassResult.init(allocator),
    };

    return transpiler;
}

pub fn finalize(
    this: *Transpiler,
) callconv(.C) void {
    this.bundler.log.deinit();
    this.scan_pass_result.named_imports.deinit(this.scan_pass_result.import_records.allocator);
    this.scan_pass_result.import_records.deinit();
    this.scan_pass_result.used_symbols.deinit();
    if (this.buffer_writer != null) {
        this.buffer_writer.?.buffer.deinit();
    }

    // bun.default_allocator.free(this.transpiler_options.tsconfig_buf);
    // bun.default_allocator.free(this.transpiler_options.macros_buf);
    this.arena.deinit();
    JSC.VirtualMachine.get().allocator.destroy(this);
}

fn getParseResult(this: *Transpiler, allocator: std.mem.Allocator, code: []const u8, loader: ?Loader, macro_js_ctx: Bundler.MacroJSValueType) ?Bundler.ParseResult {
    const name = this.transpiler_options.default_loader.stdinName();
    const source = logger.Source.initPathString(name, code);

    const jsx = if (this.transpiler_options.tsconfig != null)
        this.transpiler_options.tsconfig.?.mergeJSX(this.bundler.options.jsx)
    else
        this.bundler.options.jsx;

    const parse_options = Bundler.Bundler.ParseOptions{
        .allocator = allocator,
        .macro_remappings = this.transpiler_options.macro_map,
        .dirname_fd = .zero,
        .file_descriptor = null,
        .loader = loader orelse this.transpiler_options.default_loader,
        .jsx = jsx,
        .path = source.path,
        .virtual_source = &source,
        .replace_exports = this.transpiler_options.runtime.replace_exports,
        .macro_js_ctx = macro_js_ctx,
        // .allocator = this.
    };

    return this.bundler.parse(parse_options, null);
}

pub fn scan(
    this: *Transpiler,
    globalThis: *JSC.JSGlobalObject,
    callframe: *JSC.CallFrame,
) bun.JSError!JSC.JSValue {
    JSC.markBinding(@src());
    const arguments = callframe.arguments(3);
    var args = JSC.Node.ArgumentsSlice.init(globalThis.bunVM(), arguments.slice());
    defer args.deinit();
    const code_arg = args.next() orelse {
        globalThis.throwInvalidArgumentType("scan", "code", "string or Uint8Array");
        return .zero;
    };

    const code_holder = JSC.Node.StringOrBuffer.fromJS(globalThis, args.arena.allocator(), code_arg) orelse {
        globalThis.throwInvalidArgumentType("scan", "code", "string or Uint8Array");
        return .zero;
    };
    defer code_holder.deinit();
    const code = code_holder.slice();
    args.eat();

    const loader: ?Loader = brk: {
        if (args.next()) |arg| {
            args.eat();
            break :brk try Loader.fromJS(globalThis, arg);
        }

        break :brk null;
    };

    if (globalThis.hasException()) {
        return .zero;
    }

    var arena = Mimalloc.Arena.init() catch unreachable;
    const prev_allocator = this.bundler.allocator;
    this.bundler.setAllocator(arena.allocator());
    var log = logger.Log.init(arena.backingAllocator());
    defer log.deinit();
    this.bundler.setLog(&log);
    defer {
        this.bundler.setLog(&this.transpiler_options.log);
        this.bundler.setAllocator(prev_allocator);
        arena.deinit();
    }

    defer {
        JSAst.Stmt.Data.Store.reset();
        JSAst.Expr.Data.Store.reset();
    }

    var parse_result = getParseResult(this, arena.allocator(), code, loader, Bundler.MacroJSValueType.zero) orelse {
        if ((this.bundler.log.warnings + this.bundler.log.errors) > 0) {
            globalThis.throwValue(this.bundler.log.toJS(globalThis, globalThis.allocator(), "Parse error"));
            return .zero;
        }

        globalThis.throw("Failed to parse", .{});
        return .zero;
    };

    if ((this.bundler.log.warnings + this.bundler.log.errors) > 0) {
        globalThis.throwValue(this.bundler.log.toJS(globalThis, globalThis.allocator(), "Parse error"));
        return .zero;
    }

    const exports_label = JSC.ZigString.static("exports");
    const imports_label = JSC.ZigString.static("imports");
    const named_imports_value = namedImportsToJS(
        globalThis,
        parse_result.ast.import_records.slice(),
    );

    const named_exports_value = namedExportsToJS(
        globalThis,
        &parse_result.ast.named_exports,
    );
    return JSC.JSValue.createObject2(globalThis, imports_label, exports_label, named_imports_value, named_exports_value);
}

pub fn transform(
    this: *Transpiler,
    globalThis: *JSC.JSGlobalObject,
    callframe: *JSC.CallFrame,
) bun.JSError!JSC.JSValue {
    JSC.markBinding(@src());
    const arguments = callframe.arguments(3);
    var args = JSC.Node.ArgumentsSlice.init(globalThis.bunVM(), arguments.slice());
    defer args.arena.deinit();
    const code_arg = args.next() orelse {
        globalThis.throwInvalidArgumentType("transform", "code", "string or Uint8Array");
        return error.JSError;
    };

    var code = try JSC.Node.StringOrBuffer.fromJSWithEncodingMaybeAsync(globalThis, bun.default_allocator, code_arg, .utf8, true) orelse {
        globalThis.throwInvalidArgumentType("transform", "code", "string or Uint8Array");
        return error.JSError;
    };
    errdefer code.deinit();

    args.eat();
    const loader: ?Loader = brk: {
        if (args.next()) |arg| {
            args.eat();
            break :brk try Loader.fromJS(globalThis, arg);
        }

        break :brk null;
    };

    if (code == .buffer) {
        code_arg.protect();
    }
    var task = TransformTask.create(
        this,
        code,
        globalThis,
        loader orelse this.transpiler_options.default_loader,
    ) catch {
        if (code == .buffer) {
            code_arg.unprotect();
        }
        globalThis.throwOutOfMemory();
        return error.JSError;
    };
    task.schedule();
    return task.promise.value();
}

pub fn transformSync(
    this: *Transpiler,
    globalThis: *JSC.JSGlobalObject,
    callframe: *JSC.CallFrame,
) bun.JSError!JSC.JSValue {
    JSC.markBinding(@src());
    const arguments = callframe.arguments(3);

    var args = JSC.Node.ArgumentsSlice.init(globalThis.bunVM(), arguments.slice());
    defer args.arena.deinit();
    const code_arg = args.next() orelse {
        globalThis.throwInvalidArgumentType("transformSync", "code", "string or Uint8Array");
        return .zero;
    };

    var arena = Mimalloc.Arena.init() catch unreachable;
    defer arena.deinit();
    const code_holder = JSC.Node.StringOrBuffer.fromJS(globalThis, arena.allocator(), code_arg) orelse {
        globalThis.throwInvalidArgumentType("transformSync", "code", "string or Uint8Array");
        return .zero;
    };
    defer code_holder.deinit();
    const code = code_holder.slice();
    arguments.ptr[0].ensureStillAlive();
    defer arguments.ptr[0].ensureStillAlive();

    args.eat();
    var js_ctx_value: JSC.JSValue = JSC.JSValue.zero;
    const loader: ?Loader = brk: {
        if (args.next()) |arg| {
            args.eat();
            if (arg.isNumber() or arg.isString()) {
                break :brk try Loader.fromJS(globalThis, arg);
            }

            if (arg.isObject()) {
                js_ctx_value = arg;
                break :brk null;
            }
        }

        break :brk null;
    };

    if (args.nextEat()) |arg| {
        if (arg.isObject()) {
            js_ctx_value = arg;
        } else {
            globalThis.throwInvalidArgumentType("transformSync", "context", "object or loader");
            return .zero;
        }
    }
    if (js_ctx_value != .zero) {
        js_ctx_value.ensureStillAlive();
    }

    defer {
        if (js_ctx_value != .zero) {
            js_ctx_value.ensureStillAlive();
        }
    }

    JSAst.Stmt.Data.Store.reset();
    JSAst.Expr.Data.Store.reset();
    defer {
        JSAst.Stmt.Data.Store.reset();
        JSAst.Expr.Data.Store.reset();
    }

    const prev_bundler = this.bundler;
    this.bundler.setAllocator(arena.allocator());
    this.bundler.macro_context = null;
    var log = logger.Log.init(arena.backingAllocator());
    log.level = this.transpiler_options.log.level;
    this.bundler.setLog(&log);

    defer {
        this.bundler = prev_bundler;
    }
    const parse_result = getParseResult(
        this,
        arena.allocator(),
        code,
        loader,
        if (comptime JSC.is_bindgen) Bundler.MacroJSValueType.zero else js_ctx_value,
    ) orelse {
        if ((this.bundler.log.warnings + this.bundler.log.errors) > 0) {
            globalThis.throwValue(this.bundler.log.toJS(globalThis, globalThis.allocator(), "Parse error"));
            return .zero;
        }

        globalThis.throw("Failed to parse code", .{});
        return .zero;
    };

    if ((this.bundler.log.warnings + this.bundler.log.errors) > 0) {
        globalThis.throwValue(this.bundler.log.toJS(globalThis, globalThis.allocator(), "Parse error"));
        return .zero;
    }

    var buffer_writer = this.buffer_writer orelse brk: {
        var writer = JSPrinter.BufferWriter.init(arena.backingAllocator()) catch {
            globalThis.throw("Failed to create BufferWriter", .{});
            return .zero;
        };

        writer.buffer.growIfNeeded(code.len) catch unreachable;
        writer.buffer.list.expandToCapacity();
        break :brk writer;
    };

    defer {
        this.buffer_writer = buffer_writer;
    }

    buffer_writer.reset();
    var printer = JSPrinter.BufferPrinter.init(buffer_writer);
    _ = this.bundler.print(parse_result, @TypeOf(&printer), &printer, .esm_ascii) catch |err| {
        return globalThis.throwError(err, "Failed to print code");
    };

    // TODO: benchmark if pooling this way is faster or moving is faster
    buffer_writer = printer.ctx;
    var out = JSC.ZigString.init(buffer_writer.written);
    out.setOutputEncoding();

    return out.toJS(globalThis);
}

fn namedExportsToJS(global: *JSGlobalObject, named_exports: *JSAst.Ast.NamedExports) JSC.JSValue {
    if (named_exports.count() == 0)
        return JSValue.createEmptyArray(global, 0);

    var named_exports_iter = named_exports.iterator();
    var stack_fallback = std.heap.stackFallback(@sizeOf(bun.String) * 32, getAllocator(global));
    var allocator = stack_fallback.get();
    var names = allocator.alloc(
        bun.String,
        named_exports.count(),
    ) catch unreachable;
    defer allocator.free(names);
    named_exports.sort(strings.StringArrayByIndexSorter{
        .keys = named_exports.keys(),
    });
    var i: usize = 0;
    while (named_exports_iter.next()) |entry| {
        names[i] = bun.String.createUTF8(entry.key_ptr.*);
        i += 1;
    }
    return bun.String.toJSArray(global, names);
}

const ImportRecord = @import("../../import_record.zig").ImportRecord;

fn namedImportsToJS(
    global: *JSGlobalObject,
    import_records: []const ImportRecord,
) JSC.JSValue {
    const path_label = JSC.ZigString.static("path");
    const kind_label = JSC.ZigString.static("kind");

    const array = JSC.JSValue.createEmptyArray(global, import_records.len);
    array.ensureStillAlive();

    for (import_records, 0..) |record, i| {
        if (record.is_internal) continue;

        array.ensureStillAlive();
        const path = JSC.ZigString.init(record.path.text).toJS(global);
        const kind = JSC.ZigString.init(record.kind.label()).toJS(global);
        array.putIndex(global, @as(u32, @truncate(i)), JSC.JSValue.createObject2(global, path_label, kind_label, path, kind));
    }

    return array;
}

pub fn scanImports(
    this: *Transpiler,
    globalThis: *JSC.JSGlobalObject,
    callframe: *JSC.CallFrame,
) bun.JSError!JSC.JSValue {
    const arguments = callframe.arguments(2);
    var args = JSC.Node.ArgumentsSlice.init(globalThis.bunVM(), arguments.slice());
    defer args.deinit();

    const code_arg = args.next() orelse {
        globalThis.throwInvalidArgumentType("scanImports", "code", "string or Uint8Array");
        return .zero;
    };

    const code_holder = JSC.Node.StringOrBuffer.fromJS(globalThis, args.arena.allocator(), code_arg) orelse {
        if (!globalThis.hasException()) {
            globalThis.throwInvalidArgumentType("scanImports", "code", "string or Uint8Array");
        }
        return .zero;
    };
    args.eat();
    defer code_holder.deinit();
    const code = code_holder.slice();

    var loader: Loader = this.transpiler_options.default_loader;
    if (args.next()) |arg| {
        if (try Loader.fromJS(globalThis, arg)) |_loader| {
            loader = _loader;
        }
        args.eat();
    }

    if (!loader.isJavaScriptLike()) {
        globalThis.throwInvalidArguments("Only JavaScript-like files support this fast path", .{});
        return .zero;
    }

    var arena = Mimalloc.Arena.init() catch unreachable;
    const prev_allocator = this.bundler.allocator;
    this.bundler.setAllocator(arena.allocator());
    var log = logger.Log.init(arena.backingAllocator());
    defer log.deinit();
    this.bundler.setLog(&log);
    defer {
        this.bundler.setLog(&this.transpiler_options.log);
        this.bundler.setAllocator(prev_allocator);
        arena.deinit();
    }

    const source = logger.Source.initPathString(loader.stdinName(), code);
    var bundler = &this.bundler;
    const jsx = if (this.transpiler_options.tsconfig != null)
        this.transpiler_options.tsconfig.?.mergeJSX(this.bundler.options.jsx)
    else
        this.bundler.options.jsx;

    var opts = JSParser.Parser.Options.init(jsx, loader);
    if (this.bundler.macro_context == null) {
        this.bundler.macro_context = JSAst.Macro.MacroContext.init(&this.bundler);
    }
    opts.macro_context = &this.bundler.macro_context.?;

    JSAst.Stmt.Data.Store.reset();
    JSAst.Expr.Data.Store.reset();

    defer {
        JSAst.Stmt.Data.Store.reset();
        JSAst.Expr.Data.Store.reset();
    }

    bundler.resolver.caches.js.scan(
        bundler.allocator,
        &this.scan_pass_result,
        opts,
        bundler.options.define,
        &log,
        &source,
    ) catch |err| {
        defer this.scan_pass_result.reset();
        if ((log.warnings + log.errors) > 0) {
            globalThis.throwValue(log.toJS(globalThis, globalThis.allocator(), "Failed to scan imports"));
            return .zero;
        }

        return globalThis.throwError(err, "Failed to scan imports");
    };

    defer this.scan_pass_result.reset();

    if ((log.warnings + log.errors) > 0) {
        globalThis.throwValue(log.toJS(globalThis, globalThis.allocator(), "Failed to scan imports"));
        return .zero;
    }

    const named_imports_value = namedImportsToJS(
        globalThis,
        this.scan_pass_result.import_records.items,
    );
    return named_imports_value;
}
