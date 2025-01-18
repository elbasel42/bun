const std = @import("std");
const builtin = @import("builtin");
const bun = @import("root").bun;
const meta = bun.meta;
const windows = bun.windows;
const heap_allocator = bun.default_allocator;
const is_bindgen: bool = false;
const kernel32 = windows.kernel32;
const logger = bun.logger;
const posix = std.posix;
const path_handler = bun.path;
const strings = bun.strings;
const string = bun.string;

const C = bun.C;
const L = strings.literal;
const Environment = bun.Environment;
const Fs = @import("../../fs.zig");
const IdentityContext = @import("../../identity_context.zig").IdentityContext;
const JSC = bun.JSC;
const Mode = bun.Mode;
const Shimmer = @import("../bindings/shimmer.zig").Shimmer;
const Syscall = bun.sys;
const URL = @import("../../url.zig").URL;
const Value = std.json.Value;
pub const validators = @import("./util/validators.zig");

pub const Path = @import("./path.zig");

fn typeBaseNameT(comptime T: type) []const u8 {
    return meta.typeBaseName(@typeName(T));
}

pub const Buffer = JSC.MarkedArrayBuffer;

/// On windows, this is what libuv expects
/// On unix it is what the utimens api expects
pub const TimeLike = if (Environment.isWindows) f64 else std.posix.timespec;

/// Node.js expects the error to include contextual information
/// - "syscall"
/// - "path"
/// - "errno"
pub fn Maybe(comptime ReturnTypeT: type, comptime ErrorTypeT: type) type {
    const has_retry = ErrorTypeT != void and @hasDecl(ErrorTypeT, "retry");
    const has_todo = ErrorTypeT != void and @hasDecl(ErrorTypeT, "todo");

    return union(Tag) {
        pub const ErrorType = ErrorTypeT;
        pub const ReturnType = ReturnTypeT;

        err: ErrorType,
        result: ReturnType,

        /// NOTE: this has to have a well defined layout (e.g. setting to `u8`)
        /// experienced a bug with a Maybe(void, void)
        /// creating the `err` variant of this type
        /// resulted in Zig incorrectly setting the tag, leading to a switch
        /// statement to just not work.
        /// we (Zack, Dylan, Dave, Mason) observed that it was set to 0xFF in ReleaseFast in the debugger
        pub const Tag = enum(u8) { err, result };

        pub const retry: @This() = if (has_retry) .{ .err = ErrorType.retry } else .{ .err = .{} };
        pub const success: @This() = .{
            .result = std.mem.zeroes(ReturnType),
        };
        /// This value is technically garbage, but that is okay as `.aborted` is
        /// only meant to be returned in an operation when there is an aborted
        /// `AbortSignal` object associated with the operation.
        pub const aborted: @This() = .{ .err = .{
            .errno = @intFromEnum(posix.E.INTR),
            .syscall = .access,
        } };

        pub fn assert(this: @This()) ReturnType {
            switch (this) {
                .err => |err| {
                    bun.Output.panic("Unexpected error\n{}", .{err});
                },
                .result => |result| return result,
            }
        }

        pub inline fn todo() @This() {
            if (Environment.allow_assert) {
                if (comptime ReturnType == void) {
                    @panic("TODO called!");
                }
                @panic(comptime "TODO: Maybe(" ++ typeBaseNameT(ReturnType) ++ ")");
            }
            if (has_todo) {
                return .{ .err = ErrorType.todo() };
            }
            return .{ .err = ErrorType{} };
        }

        pub fn isTrue(this: @This()) bool {
            if (comptime ReturnType != bool) @compileError("This function can only be called on bool");
            return switch (this) {
                .result => |r| r,
                else => false,
            };
        }

        pub fn unwrap(this: @This()) !ReturnType {
            return switch (this) {
                .result => |r| r,
                .err => |e| bun.errnoToZigErr(e.errno),
            };
        }

        /// Unwrap the value if it is `result` or use the provided `default_value`
        ///
        /// `default_value` must be comptime known so the optimizer can optimize this branch out
        pub inline fn unwrapOr(this: @This(), comptime default_value: ReturnType) ReturnType {
            return switch (this) {
                .result => |v| v,
                .err => default_value,
            };
        }

        pub inline fn unwrapOrNoOptmizations(this: @This(), default_value: ReturnType) ReturnType {
            return switch (this) {
                .result => |v| v,
                .err => default_value,
            };
        }

        pub inline fn initErr(e: ErrorType) Maybe(ReturnType, ErrorType) {
            return .{ .err = e };
        }

        pub inline fn initErrWithP(e: C.SystemErrno, syscall: Syscall.Tag, path: anytype) Maybe(ReturnType, ErrorType) {
            return .{ .err = .{
                .errno = @intFromEnum(e),
                .syscall = syscall,
                .path = path,
            } };
        }

        pub inline fn asErr(this: *const @This()) ?ErrorType {
            if (this.* == .err) return this.err;
            return null;
        }

        pub inline fn asValue(this: *const @This()) ?ReturnType {
            if (this.* == .result) return this.result;
            return null;
        }

        pub inline fn isOk(this: *const @This()) bool {
            return switch (this.*) {
                .result => true,
                .err => false,
            };
        }

        pub inline fn isErr(this: *const @This()) bool {
            return switch (this.*) {
                .result => false,
                .err => true,
            };
        }

        pub inline fn initResult(result: ReturnType) Maybe(ReturnType, ErrorType) {
            return .{ .result = result };
        }

        pub inline fn mapErr(this: @This(), comptime E: type, err_fn: *const fn (ErrorTypeT) E) Maybe(ReturnType, E) {
            return switch (this) {
                .result => |v| .{ .result = v },
                .err => |e| .{ .err = err_fn(e) },
            };
        }

        pub inline fn toCssResult(this: @This()) Maybe(ReturnType, bun.css.ParseError(bun.css.ParserError)) {
            return switch (ErrorTypeT) {
                bun.css.BasicParseError => {
                    return switch (this) {
                        .result => |v| return .{ .result = v },
                        .err => |e| return .{ .err = e.intoDefaultParseError() },
                    };
                },
                bun.css.ParseError(bun.css.ParserError) => @compileError("Already a ParseError(ParserError)"),
                else => @compileError("Bad!"),
            };
        }

        pub fn toJS(this: @This(), globalObject: *JSC.JSGlobalObject) JSC.JSValue {
            return switch (this) {
                .result => |r| switch (ReturnType) {
                    JSC.JSValue => r,

                    void => .undefined,
                    bool => JSC.JSValue.jsBoolean(r),

                    JSC.ArrayBuffer => r.toJS(globalObject, null),
                    []u8 => JSC.ArrayBuffer.fromBytes(r, .ArrayBuffer).toJS(globalObject, null),

                    else => switch (@typeInfo(ReturnType)) {
                        .Int, .Float, .ComptimeInt, .ComptimeFloat => JSC.JSValue.jsNumber(r),
                        .Struct, .Enum, .Opaque, .Union => r.toJS(globalObject),
                        .Pointer => {
                            if (bun.trait.isZigString(ReturnType))
                                JSC.ZigString.init(bun.asByteSlice(r)).withEncoding().toJS(globalObject);

                            return r.toJS(globalObject);
                        },
                    },
                },
                .err => |e| e.toJSC(globalObject),
            };
        }

        pub fn toArrayBuffer(this: @This(), globalObject: *JSC.JSGlobalObject) JSC.JSValue {
            return switch (this) {
                .result => |r| JSC.ArrayBuffer.fromBytes(r, .ArrayBuffer).toJS(globalObject, null),
                .err => |e| e.toJSC(globalObject),
            };
        }

        pub fn getErrno(this: @This()) posix.E {
            return switch (this) {
                .result => posix.E.SUCCESS,
                .err => |e| @enumFromInt(e.errno),
            };
        }

        pub fn errnoSys(rc: anytype, syscall: Syscall.Tag) ?@This() {
            if (comptime Environment.isWindows) {
                if (comptime @TypeOf(rc) == std.os.windows.NTSTATUS) {} else {
                    if (rc != 0) return null;
                }
            }
            return switch (Syscall.getErrno(rc)) {
                .SUCCESS => null,
                else => |e| @This(){
                    // always truncate
                    .err = .{
                        .errno = translateToErrInt(e),
                        .syscall = syscall,
                    },
                },
            };
        }

        pub fn errno(err: anytype, syscall: Syscall.Tag) @This() {
            return @This(){
                // always truncate
                .err = .{
                    .errno = translateToErrInt(err),
                    .syscall = syscall,
                },
            };
        }

        pub fn errnoSysFd(rc: anytype, syscall: Syscall.Tag, fd: bun.FileDescriptor) ?@This() {
            if (comptime Environment.isWindows) {
                if (comptime @TypeOf(rc) == std.os.windows.NTSTATUS) {} else {
                    if (rc != 0) return null;
                }
            }
            return switch (Syscall.getErrno(rc)) {
                .SUCCESS => null,
                else => |e| @This(){
                    // Always truncate
                    .err = .{
                        .errno = translateToErrInt(e),
                        .syscall = syscall,
                        .fd = fd,
                    },
                },
            };
        }

        pub fn errnoSysP(rc: anytype, syscall: Syscall.Tag, path: anytype) ?@This() {
            if (bun.meta.Item(@TypeOf(path)) == u16) {
                @compileError("Do not pass WString path to errnoSysP, it needs the path encoded as utf8");
            }
            if (comptime Environment.isWindows) {
                if (comptime @TypeOf(rc) == std.os.windows.NTSTATUS) {} else {
                    if (rc != 0) return null;
                }
            }
            return switch (Syscall.getErrno(rc)) {
                .SUCCESS => null,
                else => |e| @This(){
                    // Always truncate
                    .err = .{
                        .errno = translateToErrInt(e),
                        .syscall = syscall,
                        .path = bun.asByteSlice(path),
                    },
                },
            };
        }

        pub fn errnoSysFP(rc: anytype, syscall: Syscall.Tag, fd: bun.FileDescriptor, path: anytype) ?@This() {
            if (comptime Environment.isWindows) {
                if (comptime @TypeOf(rc) == std.os.windows.NTSTATUS) {} else {
                    if (rc != 0) return null;
                }
            }
            return switch (Syscall.getErrno(rc)) {
                .SUCCESS => null,
                else => |e| @This(){
                    // Always truncate
                    .err = .{
                        .errno = translateToErrInt(e),
                        .syscall = syscall,
                        .fd = fd,
                        .path = bun.asByteSlice(path),
                    },
                },
            };
        }

        pub fn errnoSysPD(rc: anytype, syscall: Syscall.Tag, path: anytype, dest: anytype) ?@This() {
            if (bun.meta.Item(@TypeOf(path)) == u16) {
                @compileError("Do not pass WString path to errnoSysPD, it needs the path encoded as utf8");
            }
            if (comptime Environment.isWindows) {
                if (comptime @TypeOf(rc) == std.os.windows.NTSTATUS) {} else {
                    if (rc != 0) return null;
                }
            }
            return switch (Syscall.getErrno(rc)) {
                .SUCCESS => null,
                else => |e| @This(){
                    // Always truncate
                    .err = .{
                        .errno = translateToErrInt(e),
                        .syscall = syscall,
                        .path = bun.asByteSlice(path),
                        .dest = bun.asByteSlice(dest),
                    },
                },
            };
        }
    };
}

fn translateToErrInt(err: anytype) bun.sys.Error.Int {
    return switch (@TypeOf(err)) {
        bun.windows.NTSTATUS => @intFromEnum(bun.windows.translateNTStatusToErrno(err)),
        else => @truncate(@intFromEnum(err)),
    };
}

pub const BlobOrStringOrBuffer = union(enum) {
    blob: JSC.WebCore.Blob,
    string_or_buffer: StringOrBuffer,

    pub fn deinit(this: *const BlobOrStringOrBuffer) void {
        switch (this.*) {
            .blob => |blob| {
                if (blob.store) |store| {
                    store.deref();
                }
            },
            .string_or_buffer => |*str| {
                str.deinit();
            },
        }
    }

    pub fn slice(this: *const BlobOrStringOrBuffer) []const u8 {
        return switch (this.*) {
            .blob => |*blob| blob.sharedView(),
            .string_or_buffer => |*str| str.slice(),
        };
    }

    pub fn protect(this: *const BlobOrStringOrBuffer) void {
        switch (this.*) {
            .string_or_buffer => |sob| {
                sob.protect();
            },
            else => {},
        }
    }

    pub fn deinitAndUnprotect(this: *BlobOrStringOrBuffer) void {
        switch (this.*) {
            .string_or_buffer => |sob| {
                sob.deinitAndUnprotect();
            },
            .blob => |*blob| {
                blob.deinit();
            },
        }
    }

    pub fn fromJS(global: *JSC.JSGlobalObject, allocator: std.mem.Allocator, value: JSC.JSValue) ?BlobOrStringOrBuffer {
        if (value.as(JSC.WebCore.Blob)) |blob| {
            if (blob.store) |store| {
                store.ref();
            }
            return .{ .blob = blob.* };
        }
        return .{ .string_or_buffer = StringOrBuffer.fromJS(global, allocator, value) orelse return null };
    }

    pub fn fromJSWithEncodingValue(global: *JSC.JSGlobalObject, allocator: std.mem.Allocator, value: JSC.JSValue, encoding_value: JSC.JSValue) bun.JSError!?BlobOrStringOrBuffer {
        return fromJSWithEncodingValueMaybeAsync(global, allocator, value, encoding_value, false);
    }

    pub fn fromJSWithEncodingValueMaybeAsync(global: *JSC.JSGlobalObject, allocator: std.mem.Allocator, value: JSC.JSValue, encoding_value: JSC.JSValue, is_async: bool) bun.JSError!?BlobOrStringOrBuffer {
        return fromJSWithEncodingValueMaybeAsyncAllowRequestResponse(global, allocator, value, encoding_value, is_async, false);
    }

    pub fn fromJSWithEncodingValueMaybeAsyncAllowRequestResponse(global: *JSC.JSGlobalObject, allocator: std.mem.Allocator, value: JSC.JSValue, encoding_value: JSC.JSValue, is_async: bool, allow_request_response: bool) bun.JSError!?BlobOrStringOrBuffer {
        switch (value.jsType()) {
            .DOMWrapper => {
                if (value.as(JSC.WebCore.Blob)) |blob| {
                    if (blob.store) |store| {
                        store.ref();
                    }
                    return .{ .blob = blob.* };
                }
                if (allow_request_response) {
                    if (value.as(JSC.WebCore.Request)) |request| {
                        request.body.value.toBlobIfPossible();

                        if (request.body.value.tryUseAsAnyBlob()) |any_blob_| {
                            var any_blob = any_blob_;
                            defer any_blob.detach();
                            return .{ .blob = any_blob.toBlob(global) };
                        }

                        return global.throwInvalidArguments("Only buffered Request/Response bodies are supported for now.", .{});
                    }

                    if (value.as(JSC.WebCore.Response)) |response| {
                        response.body.value.toBlobIfPossible();

                        if (response.body.value.tryUseAsAnyBlob()) |any_blob_| {
                            var any_blob = any_blob_;
                            defer any_blob.detach();
                            return .{ .blob = any_blob.toBlob(global) };
                        }

                        return global.throwInvalidArguments("Only buffered Request/Response bodies are supported for now.", .{});
                    }
                }
            },
            else => {},
        }

        const allow_string_object = true;
        return .{ .string_or_buffer = try StringOrBuffer.fromJSWithEncodingValueMaybeAsync(global, allocator, value, encoding_value, is_async, allow_string_object) orelse return null };
    }
};

pub const StringOrBuffer = union(enum) {
    string: bun.SliceWithUnderlyingString,
    threadsafe_string: bun.SliceWithUnderlyingString,
    encoded_slice: JSC.ZigString.Slice,
    buffer: Buffer,

    pub const empty = StringOrBuffer{ .encoded_slice = JSC.ZigString.Slice.empty };

    pub fn toThreadSafe(this: *@This()) void {
        switch (this.*) {
            .string => {
                this.string.toThreadSafe();
                this.* = .{
                    .threadsafe_string = this.string,
                };
            },
            .threadsafe_string => {},
            .encoded_slice => {},
            .buffer => {},
        }
    }

    pub fn protect(this: *const StringOrBuffer) void {
        switch (this.*) {
            .buffer => |buf| {
                buf.buffer.value.protect();
            },
            else => {},
        }
    }

    pub fn fromJSToOwnedSlice(globalObject: *JSC.JSGlobalObject, value: JSC.JSValue, allocator: std.mem.Allocator) bun.JSError![]u8 {
        if (value.asArrayBuffer(globalObject)) |array_buffer| {
            defer globalObject.vm().reportExtraMemory(array_buffer.len);

            return try allocator.dupe(u8, array_buffer.byteSlice());
        }

        const str = try bun.String.fromJS2(value, globalObject);
        defer str.deref();

        const result = try str.toOwnedSlice(allocator);
        defer globalObject.vm().reportExtraMemory(result.len);
        return result;
    }

    pub fn toJS(this: *StringOrBuffer, ctx: JSC.C.JSContextRef) JSC.JSValue {
        return switch (this.*) {
            inline .threadsafe_string, .string => |*str| {
                return str.transferToJS(ctx);
            },
            .encoded_slice => {
                defer {
                    this.encoded_slice.deinit();
                    this.encoded_slice = .{};
                }

                return bun.String.createUTF8ForJS(ctx, this.encoded_slice.slice());
            },
            .buffer => {
                if (this.buffer.buffer.value != .zero) {
                    return this.buffer.buffer.value;
                }

                return this.buffer.toNodeBuffer(ctx);
            },
        };
    }

    pub fn slice(this: *const StringOrBuffer) []const u8 {
        return switch (this.*) {
            inline else => |*str| str.slice(),
        };
    }

    pub fn deinit(this: *const StringOrBuffer) void {
        switch (this.*) {
            inline .threadsafe_string, .string => |*str| {
                str.deinit();
            },
            .encoded_slice => |*encoded| {
                encoded.deinit();
            },
            else => {},
        }
    }

    pub fn deinitAndUnprotect(this: *const StringOrBuffer) void {
        switch (this.*) {
            inline .threadsafe_string, .string => |*str| {
                str.deinit();
            },
            .buffer => |buffer| {
                buffer.buffer.value.unprotect();
            },
            .encoded_slice => |*encoded| {
                encoded.deinit();
            },
        }
    }

    pub fn fromJSMaybeAsync(global: *JSC.JSGlobalObject, allocator: std.mem.Allocator, value: JSC.JSValue, is_async: bool, allow_string_object: bool) ?StringOrBuffer {
        return switch (value.jsType()) {
            .String,
            .StringObject,
            .DerivedStringObject,
            => |str_type| {
                if (!allow_string_object and str_type != .String) {
                    return null;
                }
                const str = bun.String.fromJS(value, global);

                if (is_async) {
                    defer str.deref();
                    var possible_clone = str;
                    var sliced = possible_clone.toThreadSafeSlice(allocator);
                    sliced.reportExtraMemory(global.vm());

                    if (sliced.underlying.isEmpty()) {
                        return .{ .encoded_slice = sliced.utf8 };
                    }

                    return .{ .threadsafe_string = sliced };
                } else {
                    return .{ .string = str.toSlice(allocator) };
                }
            },

            .ArrayBuffer,
            .Int8Array,
            .Uint8Array,
            .Uint8ClampedArray,
            .Int16Array,
            .Uint16Array,
            .Int32Array,
            .Uint32Array,
            .Float32Array,
            .Float16Array,
            .Float64Array,
            .BigInt64Array,
            .BigUint64Array,
            .DataView,
            => .{ .buffer = Buffer.fromArrayBuffer(global, value) },
            else => null,
        };
    }

    pub fn fromJS(global: *JSC.JSGlobalObject, allocator: std.mem.Allocator, value: JSC.JSValue) ?StringOrBuffer {
        return fromJSMaybeAsync(global, allocator, value, false, true);
    }

    pub fn fromJSWithEncoding(global: *JSC.JSGlobalObject, allocator: std.mem.Allocator, value: JSC.JSValue, encoding: Encoding) bun.JSError!?StringOrBuffer {
        return fromJSWithEncodingMaybeAsync(global, allocator, value, encoding, false, true);
    }

    pub fn fromJSWithEncodingMaybeAsync(global: *JSC.JSGlobalObject, allocator: std.mem.Allocator, value: JSC.JSValue, encoding: Encoding, is_async: bool, allow_string_object: bool) bun.JSError!?StringOrBuffer {
        if (value.isCell() and value.jsType().isArrayBufferLike()) {
            return .{ .buffer = Buffer.fromTypedArray(global, value) };
        }

        if (encoding == .utf8) {
            return fromJSMaybeAsync(global, allocator, value, is_async, allow_string_object);
        }

        if (value.isString()) {
            var str = try bun.String.fromJS2(value, global);
            defer str.deref();
            if (str.isEmpty()) {
                return fromJSMaybeAsync(global, allocator, value, is_async, allow_string_object);
            }

            const out = str.encode(encoding);
            defer global.vm().reportExtraMemory(out.len);

            return .{ .encoded_slice = JSC.ZigString.Slice.init(bun.default_allocator, out) };
        }

        return null;
    }

    pub fn fromJSWithEncodingValue(global: *JSC.JSGlobalObject, allocator: std.mem.Allocator, value: JSC.JSValue, encoding_value: JSC.JSValue) bun.JSError!?StringOrBuffer {
        const encoding: Encoding = brk: {
            if (!encoding_value.isCell())
                break :brk .utf8;
            break :brk Encoding.fromJS(encoding_value, global) orelse .utf8;
        };

        return fromJSWithEncoding(global, allocator, value, encoding);
    }

    pub fn fromJSWithEncodingValueMaybeAsync(global: *JSC.JSGlobalObject, allocator: std.mem.Allocator, value: JSC.JSValue, encoding_value: JSC.JSValue, maybe_async: bool, allow_string_object: bool) bun.JSError!?StringOrBuffer {
        const encoding: Encoding = brk: {
            if (!encoding_value.isCell())
                break :brk .utf8;
            break :brk Encoding.fromJS(encoding_value, global) orelse .utf8;
        };
        return fromJSWithEncodingMaybeAsync(global, allocator, value, encoding, maybe_async, allow_string_object);
    }
};

pub const ErrorCode = @import("./nodejs_error_code.zig").Code;

// We can't really use Zig's error handling for syscalls because Node.js expects the "real" errno to be returned
// and various issues with std.posix that make it too unstable for arbitrary user input (e.g. how .BADF is marked as unreachable)

/// https://github.com/nodejs/node/blob/master/lib/buffer.js#L587
/// See `JSC.WebCore.Encoder` for encoding and decoding functions.
/// must match src/bun.js/bindings/BufferEncodingType.h
pub const Encoding = enum(u8) {
    utf8,
    ucs2,
    utf16le,
    latin1,
    ascii,
    base64,
    base64url,
    hex,

    /// Refer to the buffer's encoding
    buffer,

    pub const map = bun.ComptimeStringMap(Encoding, .{
        .{ "utf-8", Encoding.utf8 },
        .{ "utf8", Encoding.utf8 },
        .{ "ucs-2", Encoding.utf16le },
        .{ "ucs2", Encoding.utf16le },
        .{ "utf16-le", Encoding.utf16le },
        .{ "utf16le", Encoding.utf16le },
        .{ "binary", Encoding.latin1 },
        .{ "latin1", Encoding.latin1 },
        .{ "ascii", Encoding.ascii },
        .{ "base64", Encoding.base64 },
        .{ "hex", Encoding.hex },
        .{ "buffer", Encoding.buffer },
        .{ "base64url", Encoding.base64url },
    });

    pub fn isBinaryToText(this: Encoding) bool {
        return switch (this) {
            .hex, .base64, .base64url => true,
            else => false,
        };
    }

    pub fn fromJS(value: JSC.JSValue, global: *JSC.JSGlobalObject) ?Encoding {
        return map.fromJSCaseInsensitive(global, value);
    }

    /// Caller must verify the value is a string
    pub fn from(slice: []const u8) ?Encoding {
        return strings.inMapCaseInsensitive(slice, map);
    }

    pub fn assert(value: JSC.JSValue, globalObject: *JSC.JSGlobalObject, default: Encoding) bun.JSError!Encoding {
        if (value.isFalsey()) {
            return default;
        }

        if (!value.isString()) {
            return throwEncodingError(globalObject, value);
        }

        return try fromJSWithDefaultOnEmpty(value, globalObject, default) orelse throwEncodingError(globalObject, value);
    }

    pub fn fromJSWithDefaultOnEmpty(value: JSC.JSValue, globalObject: *JSC.JSGlobalObject, default: Encoding) bun.JSError!?Encoding {
        const str = try bun.String.fromJS2(value, globalObject);
        defer str.deref();
        if (str.isEmpty()) {
            return default;
        }
        return str.inMapCaseInsensitive(Encoding.map);
    }

    pub fn throwEncodingError(globalObject: *JSC.JSGlobalObject, value: JSC.JSValue) bun.JSError {
        return globalObject.ERR_INVALID_ARG_VALUE("encoding '{}' is an invalid encoding", .{value.fmtString(globalObject)}).throw();
    }

    pub fn encodeWithSize(encoding: Encoding, globalObject: *JSC.JSGlobalObject, comptime size: usize, input: *const [size]u8) JSC.JSValue {
        switch (encoding) {
            .base64 => {
                var buf: [std.base64.standard.Encoder.calcSize(size)]u8 = undefined;
                const len = bun.base64.encode(&buf, input);
                return JSC.ZigString.init(buf[0..len]).toJS(globalObject);
            },
            .base64url => {
                var buf: [std.base64.url_safe_no_pad.Encoder.calcSize(size)]u8 = undefined;
                const encoded = std.base64.url_safe_no_pad.Encoder.encode(&buf, input);

                return JSC.ZigString.init(buf[0..encoded.len]).toJS(globalObject);
            },
            .hex => {
                var buf: [size * 4]u8 = undefined;
                const out = std.fmt.bufPrint(&buf, "{}", .{std.fmt.fmtSliceHexLower(input)}) catch bun.outOfMemory();
                const result = JSC.ZigString.init(out).toJS(globalObject);
                return result;
            },
            .buffer => {
                return JSC.ArrayBuffer.createBuffer(globalObject, input);
            },
            inline else => |enc| {
                const res = JSC.WebCore.Encoder.toStringComptime(input, globalObject, enc);
                if (res.isError()) {
                    return globalObject.throwValue(res) catch .zero;
                }
                return res;
            },
        }
    }

    pub fn encodeWithMaxSize(encoding: Encoding, globalObject: *JSC.JSGlobalObject, comptime max_size: usize, input: []const u8) JSC.JSValue {
        switch (encoding) {
            .base64 => {
                var base64_buf: [std.base64.standard.Encoder.calcSize(max_size * 4)]u8 = undefined;
                const encoded_len = bun.base64.encode(&base64_buf, input);
                var encoded, const bytes = bun.String.createUninitialized(.latin1, encoded_len);
                @memcpy(@constCast(bytes), base64_buf[0..encoded_len]);
                return encoded.transferToJS(globalObject);
            },
            .base64url => {
                var buf: [std.base64.url_safe_no_pad.Encoder.calcSize(max_size * 4)]u8 = undefined;
                const encoded = std.base64.url_safe_no_pad.Encoder.encode(&buf, input);

                return JSC.ZigString.init(buf[0..encoded.len]).toJS(globalObject);
            },
            .hex => {
                var buf: [max_size * 4]u8 = undefined;
                const out = std.fmt.bufPrint(&buf, "{}", .{std.fmt.fmtSliceHexLower(input)}) catch bun.outOfMemory();
                const result = JSC.ZigString.init(out).toJS(globalObject);
                return result;
            },
            .buffer => {
                return JSC.ArrayBuffer.createBuffer(globalObject, input);
            },
            inline else => |enc| {
                const res = JSC.WebCore.Encoder.toStringComptime(input, globalObject, enc);
                if (res.isError()) {
                    return globalObject.throwValue(res) catch .zero;
                }

                return res;
            },
        }
    }

    extern fn WebCore_BufferEncodingType_toJS(globalObject: *JSC.JSGlobalObject, encoding: Encoding) JSC.JSValue;
    pub fn toJS(encoding: Encoding, globalObject: *JSC.JSGlobalObject) JSC.JSValue {
        return WebCore_BufferEncodingType_toJS(globalObject, encoding);
    }
};

/// This is used on the windows implementation of realpath, which is in javascript
pub fn jsAssertEncodingValid(global: *JSC.JSGlobalObject, call_frame: *JSC.CallFrame) bun.JSError!JSC.JSValue {
    const value = call_frame.argument(0);
    _ = try Encoding.assert(value, global, .utf8);
    return .undefined;
}

const PathOrBuffer = union(Tag) {
    path: bun.PathString,
    buffer: Buffer,

    pub const Tag = enum { path, buffer };

    pub inline fn slice(this: PathOrBuffer) []const u8 {
        return this.path.slice();
    }
};

pub fn CallbackTask(comptime Result: type) type {
    return struct {
        callback: JSC.C.JSObjectRef,
        option: Option,
        success: bool = false,

        pub const Option = union {
            err: JSC.SystemError,
            result: Result,
        };
    };
}

pub const PathLike = union(enum) {
    string: bun.PathString,
    buffer: Buffer,
    slice_with_underlying_string: bun.SliceWithUnderlyingString,
    threadsafe_string: bun.SliceWithUnderlyingString,
    encoded_slice: JSC.ZigString.Slice,

    pub fn estimatedSize(this: *const PathLike) usize {
        return switch (this.*) {
            .string => this.string.estimatedSize(),
            .buffer => this.buffer.slice().len,
            .threadsafe_string, .slice_with_underlying_string => 0,
            .encoded_slice => this.encoded_slice.slice().len,
        };
    }

    pub fn deinit(this: *const PathLike) void {
        switch (this.*) {
            .string, .buffer => {},
            inline else => |*str| {
                str.deinit();
            },
        }
    }

    pub fn toThreadSafe(this: *PathLike) void {
        switch (this.*) {
            .slice_with_underlying_string => {
                this.slice_with_underlying_string.toThreadSafe();
                this.* = .{
                    .threadsafe_string = this.slice_with_underlying_string,
                };
            },
            .buffer => {
                this.buffer.buffer.value.protect();
            },
            else => {},
        }
    }

    pub fn deinitAndUnprotect(this: *const PathLike) void {
        switch (this.*) {
            inline .encoded_slice, .threadsafe_string, .slice_with_underlying_string => |*val| {
                val.deinit();
            },
            .buffer => |val| {
                val.buffer.value.unprotect();
            },
            else => {},
        }
    }

    pub inline fn slice(this: PathLike) string {
        return switch (this) {
            inline else => |*str| str.slice(),
        };
    }

    pub fn sliceZWithForceCopy(this: PathLike, buf: *bun.PathBuffer, comptime force: bool) if (force) [:0]u8 else [:0]const u8 {
        const sliced = this.slice();

        if (Environment.isWindows) {
            if (std.fs.path.isAbsolute(sliced)) {
                if (sliced.len > 2 and bun.path.isDriveLetter(sliced[0]) and sliced[1] == ':' and bun.path.isSepAny(sliced[2])) {
                    // Add the long path syntax. This affects most of node:fs
                    const rest = path_handler.PosixToWinNormalizer.resolveCWDWithExternalBufZ(@ptrCast(buf[4..]), sliced) catch @panic("Error while resolving path.");
                    buf[0..4].* = bun.windows.long_path_prefix_u8;
                    // When long path syntax is used, the slashes must be facing the correct direction.
                    bun.path.dangerouslyConvertPathToWindowsInPlace(u8, buf[4..][0..rest.len]);
                    return buf[0 .. 4 + rest.len :0];
                }
                return path_handler.PosixToWinNormalizer.resolveCWDWithExternalBufZ(buf, sliced) catch @panic("Error while resolving path.");
            }
        }

        if (sliced.len == 0) {
            if (comptime !force) return "";

            buf[0] = 0;
            return buf[0..0 :0];
        }

        if (comptime !force) {
            if (sliced[sliced.len - 1] == 0) {
                return sliced[0 .. sliced.len - 1 :0];
            }
        }

        @memcpy(buf[0..sliced.len], sliced);
        buf[sliced.len] = 0;
        return buf[0..sliced.len :0];
    }

    pub inline fn sliceZ(this: PathLike, buf: *bun.PathBuffer) [:0]const u8 {
        return sliceZWithForceCopy(this, buf, false);
    }

    pub inline fn sliceW(this: PathLike, buf: *bun.WPathBuffer) [:0]const u16 {
        return strings.toWPath(buf, this.slice());
    }

    pub inline fn osPath(this: PathLike, buf: *bun.OSPathBuffer) bun.OSPathSliceZ {
        if (comptime Environment.isWindows) {
            return sliceW(this, buf);
        }

        return sliceZWithForceCopy(this, buf, false);
    }

    pub inline fn osPathKernel32(this: PathLike, buf: *bun.PathBuffer) bun.OSPathSliceZ {
        if (comptime Environment.isWindows) {
            return strings.toKernel32Path(@alignCast(std.mem.bytesAsSlice(u16, buf)), this.slice());
        }

        return sliceZWithForceCopy(this, buf, false);
    }

    pub fn fromJS(ctx: JSC.C.JSContextRef, arguments: *ArgumentsSlice) bun.JSError!?PathLike {
        return fromJSWithAllocator(ctx, arguments, bun.default_allocator);
    }

    pub fn fromJSWithAllocator(ctx: JSC.C.JSContextRef, arguments: *ArgumentsSlice, allocator: std.mem.Allocator) bun.JSError!?PathLike {
        const arg = arguments.next() orelse return null;
        switch (arg.jsType()) {
            .Uint8Array,
            .DataView,
            => {
                const buffer = Buffer.fromTypedArray(ctx, arg);
                try Valid.pathBuffer(buffer, ctx);
                try Valid.pathNullBytes(buffer.slice(), ctx);

                arguments.protectEat();
                return .{ .buffer = buffer };
            },

            .ArrayBuffer => {
                const buffer = Buffer.fromArrayBuffer(ctx, arg);
                try Valid.pathBuffer(buffer, ctx);
                try Valid.pathNullBytes(buffer.slice(), ctx);

                arguments.protectEat();
                return .{ .buffer = buffer };
            },

            .String,
            .StringObject,
            .DerivedStringObject,
            => {
                var str = arg.toBunString(ctx);
                defer str.deref();

                arguments.eat();

                return try fromBunString(ctx, str, arguments.will_be_async, allocator);
            },
            else => {
                if (arg.as(JSC.DOMURL)) |domurl| {
                    var str: bun.String = domurl.fileSystemPath() catch |err| switch (err) {
                        error.NotFileUrl => {
                            return ctx.ERR_INVALID_URL_SCHEME("URL must be a non-empty \"file:\" path", .{}).throw();
                        },
                        error.InvalidPath => {
                            return ctx.ERR_INVALID_FILE_URL_PATH("URL must be a non-empty \"file:\" path", .{}).throw();
                        },
                        error.InvalidHost => {
                            return ctx.ERR_INVALID_FILE_URL_HOST("URL must be a non-empty \"file:\" path", .{}).throw();
                        },
                    };
                    defer str.deref();
                    if (str.isEmpty()) {
                        return ctx.ERR_INVALID_ARG_VALUE("URL must be a non-empty \"file:\" path", .{}).throw();
                    }
                    arguments.eat();

                    return try fromBunString(ctx, str, arguments.will_be_async, allocator);
                }

                return null;
            },
        }
    }

    pub fn fromBunString(global: *JSC.JSGlobalObject, str: bun.String, will_be_async: bool, allocator: std.mem.Allocator) !PathLike {
        try Valid.pathStringLength(str.length(), global);

        if (will_be_async) {
            var sliced = str.toThreadSafeSlice(allocator);
            errdefer sliced.deinit();

            try Valid.pathNullBytes(sliced.slice(), global);

            sliced.reportExtraMemory(global.vm());

            if (sliced.underlying.isEmpty()) {
                return .{ .encoded_slice = sliced.utf8 };
            }
            return .{ .threadsafe_string = sliced };
        } else {
            var sliced = str.toSlice(allocator);
            errdefer if (!sliced.isWTFAllocated()) sliced.deinit();

            try Valid.pathNullBytes(sliced.slice(), global);

            // Costs nothing to keep both around.
            if (sliced.isWTFAllocated()) {
                str.ref();
                return .{ .slice_with_underlying_string = sliced };
            }

            sliced.reportExtraMemory(global.vm());

            // It is expensive to keep both around.
            return .{ .encoded_slice = sliced.utf8 };
        }
    }
};

pub const Valid = struct {
    pub fn pathSlice(zig_str: JSC.ZigString.Slice, ctx: JSC.C.JSContextRef) bun.JSError!void {
        switch (zig_str.len) {
            0...bun.MAX_PATH_BYTES => return,
            else => {
                var system_error = bun.sys.Error.fromCode(.NAMETOOLONG, .open).withPath(zig_str.slice()).toSystemError();
                system_error.syscall = bun.String.dead;
                return ctx.throwValue(system_error.toErrorInstance(ctx));
            },
        }
        comptime unreachable;
    }

    pub fn pathStringLength(len: usize, ctx: JSC.C.JSContextRef) bun.JSError!void {
        switch (len) {
            0...bun.MAX_PATH_BYTES => return,
            else => {
                var system_error = bun.sys.Error.fromCode(.NAMETOOLONG, .open).toSystemError();
                system_error.syscall = bun.String.dead;
                return ctx.throwValue(system_error.toErrorInstance(ctx));
            },
        }
        comptime unreachable;
    }

    pub fn pathString(zig_str: JSC.ZigString, ctx: JSC.C.JSContextRef) bun.JSError!void {
        return pathStringLength(zig_str.len, ctx);
    }

    pub fn pathBuffer(buffer: Buffer, ctx: JSC.C.JSContextRef) bun.JSError!void {
        const slice = buffer.slice();
        switch (slice.len) {
            0 => {
                return ctx.throwInvalidArguments("Invalid path buffer: can't be empty", .{});
            },
            else => {
                var system_error = bun.sys.Error.fromCode(.NAMETOOLONG, .open).toSystemError();
                system_error.syscall = bun.String.dead;
                return ctx.throwValue(system_error.toErrorInstance(ctx));
            },
            1...bun.MAX_PATH_BYTES => return,
        }
        comptime unreachable;
    }

    pub fn pathNullBytes(slice: []const u8, global: *JSC.JSGlobalObject) bun.JSError!void {
        if (bun.strings.indexOfChar(slice, 0) != null) {
            return global.ERR_INVALID_ARG_VALUE("The argument 'path' must be a string, Uint8Array, or URL without null bytes. Received {}", .{bun.fmt.quote(slice)}).throw();
        }
    }
};

pub const VectorArrayBuffer = struct {
    value: JSC.JSValue,
    buffers: std.ArrayList(bun.PlatformIOVec),

    pub fn toJS(this: VectorArrayBuffer, _: *JSC.JSGlobalObject) JSC.JSValue {
        return this.value;
    }

    pub fn fromJS(globalObject: *JSC.JSGlobalObject, val: JSC.JSValue, allocator: std.mem.Allocator) bun.JSError!VectorArrayBuffer {
        if (!val.jsType().isArrayLike()) {
            return globalObject.throwInvalidArguments("Expected ArrayBufferView[]", .{});
        }

        var bufferlist = std.ArrayList(bun.PlatformIOVec).init(allocator);
        var i: usize = 0;
        const len = val.getLength(globalObject);
        bufferlist.ensureTotalCapacityPrecise(len) catch bun.outOfMemory();

        while (i < len) {
            const element = val.getIndex(globalObject, @as(u32, @truncate(i)));

            if (!element.isCell()) {
                return globalObject.throwInvalidArguments("Expected ArrayBufferView[]", .{});
            }

            const array_buffer = element.asArrayBuffer(globalObject) orelse {
                return globalObject.throwInvalidArguments("Expected ArrayBufferView[]", .{});
            };

            const buf = array_buffer.byteSlice();
            bufferlist.append(bun.platformIOVecCreate(buf)) catch bun.outOfMemory();
            i += 1;
        }

        return VectorArrayBuffer{ .value = val, .buffers = bufferlist };
    }
};

pub const ArgumentsSlice = struct {
    remaining: []const JSC.JSValue,
    vm: *JSC.VirtualMachine,
    arena: bun.ArenaAllocator = bun.ArenaAllocator.init(bun.default_allocator),
    all: []const JSC.JSValue,
    threw: bool = false,
    protected: bun.bit_set.IntegerBitSet(32) = bun.bit_set.IntegerBitSet(32).initEmpty(),
    will_be_async: bool = false,

    pub fn unprotect(this: *ArgumentsSlice) void {
        var iter = this.protected.iterator(.{});
        const ctx = this.vm.global;
        while (iter.next()) |i| {
            JSC.C.JSValueUnprotect(ctx, this.all[i].asObjectRef());
        }
        this.protected = bun.bit_set.IntegerBitSet(32).initEmpty();
    }

    pub fn deinit(this: *ArgumentsSlice) void {
        this.unprotect();
        this.arena.deinit();
    }

    pub fn protectEat(this: *ArgumentsSlice) void {
        if (this.remaining.len == 0) return;
        const index = this.all.len - this.remaining.len;
        this.protected.set(index);
        JSC.C.JSValueProtect(this.vm.global, this.all[index].asObjectRef());
        this.eat();
    }

    pub fn protectEatNext(this: *ArgumentsSlice) ?JSC.JSValue {
        if (this.remaining.len == 0) return null;
        return this.nextEat();
    }

    pub fn from(vm: *JSC.VirtualMachine, arguments: []const JSC.JSValueRef) ArgumentsSlice {
        return init(vm, @as([*]const JSC.JSValue, @ptrCast(arguments.ptr))[0..arguments.len]);
    }
    pub fn init(vm: *JSC.VirtualMachine, arguments: []const JSC.JSValue) ArgumentsSlice {
        return ArgumentsSlice{
            .remaining = arguments,
            .vm = vm,
            .all = arguments,
            .arena = bun.ArenaAllocator.init(vm.allocator),
        };
    }

    pub fn initAsync(vm: *JSC.VirtualMachine, arguments: []const JSC.JSValue) ArgumentsSlice {
        return ArgumentsSlice{
            .remaining = bun.default_allocator.dupe(JSC.JSValue, arguments),
            .vm = vm,
            .all = arguments,
            .arena = bun.ArenaAllocator.init(bun.default_allocator),
        };
    }

    pub inline fn len(this: *const ArgumentsSlice) u16 {
        return @as(u16, @truncate(this.remaining.len));
    }
    pub fn eat(this: *ArgumentsSlice) void {
        if (this.remaining.len == 0) {
            return;
        }

        this.remaining = this.remaining[1..];
    }

    pub fn next(this: *ArgumentsSlice) ?JSC.JSValue {
        if (this.remaining.len == 0) {
            return null;
        }

        return this.remaining[0];
    }

    pub fn nextEat(this: *ArgumentsSlice) ?JSC.JSValue {
        if (this.remaining.len == 0) {
            return null;
        }
        defer this.eat();
        return this.remaining[0];
    }
};

pub fn fileDescriptorFromJS(ctx: JSC.C.JSContextRef, value: JSC.JSValue) bun.JSError!?bun.FileDescriptor {
    return if (try bun.FDImpl.fromJSValidated(value, ctx)) |fd|
        fd.encode()
    else
        null;
}

// Equivalent to `toUnixTimestamp`
//
// Node.js docs:
// > Values can be either numbers representing Unix epoch time in seconds, Dates, or a numeric string like '123456789.0'.
// > If the value can not be converted to a number, or is NaN, Infinity, or -Infinity, an Error will be thrown.
pub fn timeLikeFromJS(globalObject: *JSC.JSGlobalObject, value: JSC.JSValue) ?TimeLike {
    // Number is most common case
    if (value.isNumber()) {
        const seconds = value.asNumber();
        if (std.math.isFinite(seconds)) {
            if (seconds < 0) {
                return timeLikeFromNow();
            }
            return timeLikeFromSeconds(seconds);
        }
        return null;
    } else switch (value.jsType()) {
        .JSDate => {
            const milliseconds = value.getUnixTimestamp();
            if (std.math.isFinite(milliseconds)) {
                return timeLikeFromMilliseconds(milliseconds);
            }
        },
        .String => {
            const seconds = value.coerceToDouble(globalObject);
            if (std.math.isFinite(seconds)) {
                return timeLikeFromSeconds(seconds);
            }
        },
        else => {},
    }
    return null;
}

fn timeLikeFromSeconds(seconds: f64) TimeLike {
    if (Environment.isWindows) {
        return seconds;
    }
    return .{
        .tv_sec = @intFromFloat(seconds),
        .tv_nsec = @intFromFloat(@mod(seconds, 1) * std.time.ns_per_s),
    };
}

fn timeLikeFromMilliseconds(milliseconds: f64) TimeLike {
    if (Environment.isWindows) {
        return milliseconds / 1000.0;
    }
    return .{
        .tv_sec = @intFromFloat(@divFloor(milliseconds, std.time.ms_per_s)),
        .tv_nsec = @intFromFloat(@mod(milliseconds, std.time.ms_per_s) * std.time.ns_per_ms),
    };
}

fn timeLikeFromNow() TimeLike {
    const nanos = std.time.nanoTimestamp();
    if (Environment.isWindows) {
        return @as(TimeLike, @floatFromInt(nanos)) / std.time.ns_per_s;
    }
    return .{
        .tv_sec = @truncate(@divFloor(nanos, std.time.ns_per_s)),
        .tv_nsec = @truncate(@mod(nanos, std.time.ns_per_s)),
    };
}

pub fn modeFromJS(ctx: JSC.C.JSContextRef, value: JSC.JSValue) bun.JSError!?Mode {
    const mode_int = if (value.isNumber()) brk: {
        const m = try validators.validateUint32(ctx, value, "mode", .{}, false);
        break :brk @as(Mode, @as(u24, @truncate(m)));
    } else brk: {
        if (value.isUndefinedOrNull()) return null;

        if (!value.isString()) {
            return ctx.throwInvalidArgumentTypeValue("mode", "number", value);
        }

        // An easier method of constructing the mode is to use a sequence of
        // three octal digits (e.g. 765). The left-most digit (7 in the example),
        // specifies the permissions for the file owner. The middle digit (6 in
        // the example), specifies permissions for the group. The right-most
        // digit (5 in the example), specifies the permissions for others.

        var zig_str = JSC.ZigString.Empty;
        value.toZigString(&zig_str, ctx);
        var slice = zig_str.slice();
        if (strings.hasPrefix(slice, "0o")) {
            slice = slice[2..];
        }

        break :brk std.fmt.parseInt(Mode, slice, 8) catch {
            var formatter = bun.JSC.ConsoleObject.Formatter{ .globalThis = ctx };
            return ctx.throwValue(ctx.ERR_INVALID_ARG_VALUE("The argument 'mode' must be a 32-bit unsigned integer or an octal string. Received {}", .{value.toFmt(&formatter)}).toJS());
        };
    };

    return mode_int & 0o777;
}

pub const PathOrFileDescriptor = union(Tag) {
    fd: bun.FileDescriptor,
    path: PathLike,

    pub const Tag = enum { fd, path };
    pub const SerializeTag = enum(u8) { fd, path };

    /// This will unref() the path string if it is a PathLike.
    /// Does nothing for file descriptors, **does not** close file descriptors.
    pub fn deinit(this: PathOrFileDescriptor) void {
        if (this == .path) {
            this.path.deinit();
        }
    }

    pub fn estimatedSize(this: *const PathOrFileDescriptor) usize {
        return switch (this.*) {
            .path => this.path.estimatedSize(),
            .fd => 0,
        };
    }

    pub fn toThreadSafe(this: *PathOrFileDescriptor) void {
        if (this.* == .path) {
            this.path.toThreadSafe();
        }
    }

    pub fn deinitAndUnprotect(this: PathOrFileDescriptor) void {
        if (this == .path) {
            this.path.deinitAndUnprotect();
        }
    }

    pub fn hash(this: JSC.Node.PathOrFileDescriptor) u64 {
        return switch (this) {
            .path => bun.hash(this.path.slice()),
            .fd => bun.hash(std.mem.asBytes(&this.fd)),
        };
    }

    pub fn format(this: JSC.Node.PathOrFileDescriptor, comptime fmt: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        if (fmt.len != 0 and fmt[0] != 's') {
            @compileError("Unsupported format argument: '" ++ fmt ++ "'.");
        }
        switch (this) {
            .path => |p| try writer.writeAll(p.slice()),
            .fd => |fd| try writer.print("{}", .{fd}),
        }
    }

    pub fn fromJS(ctx: JSC.C.JSContextRef, arguments: *ArgumentsSlice, allocator: std.mem.Allocator) bun.JSError!?JSC.Node.PathOrFileDescriptor {
        const first = arguments.next() orelse return null;

        if (try bun.FDImpl.fromJSValidated(first, ctx)) |fd| {
            arguments.eat();
            return JSC.Node.PathOrFileDescriptor{ .fd = fd.encode() };
        }

        return JSC.Node.PathOrFileDescriptor{
            .path = try PathLike.fromJSWithAllocator(ctx, arguments, allocator) orelse return null,
        };
    }
};

pub const FileSystemFlags = enum(if (Environment.isWindows) c_int else c_uint) {
    pub const tag_type = @typeInfo(FileSystemFlags).Enum.tag_type;
    const O = bun.O;

    /// Open file for appending. The file is created if it does not exist.
    a = O.APPEND | O.WRONLY | O.CREAT,
    /// Like 'a' but fails if the path exists.
    // @"ax" = bun.O.APPEND | bun.O.EXCL,
    /// Open file for reading and appending. The file is created if it does not exist.
    // @"a+" = bun.O.APPEND | bun.O.RDWR,
    /// Like 'a+' but fails if the path exists.
    // @"ax+" = bun.O.APPEND | bun.O.RDWR | bun.O.EXCL,
    /// Open file for appending in synchronous mode. The file is created if it does not exist.
    // @"as" = bun.O.APPEND,
    /// Open file for reading and appending in synchronous mode. The file is created if it does not exist.
    // @"as+" = bun.O.APPEND | bun.O.RDWR,
    /// Open file for reading. An exception occurs if the file does not exist.
    r = O.RDONLY,
    /// Open file for reading and writing. An exception occurs if the file does not exist.
    // @"r+" = bun.O.RDWR,
    /// Open file for reading and writing in synchronous mode. Instructs the operating system to bypass the local file system cache.
    /// This is primarily useful for opening files on NFS mounts as it allows skipping the potentially stale local cache. It has a very real impact on I/O performance so using this flag is not recommended unless it is needed.
    /// This doesn't turn fs.open() or fsPromises.open() into a synchronous blocking call. If synchronous operation is desired, something like fs.openSync() should be used.
    // @"rs+" = bun.O.RDWR,
    /// Open file for writing. The file is created (if it does not exist) or truncated (if it exists).
    w = O.WRONLY | O.CREAT,
    /// Like 'w' but fails if the path exists.
    // @"wx" = bun.O.WRONLY | bun.O.TRUNC,
    // ///  Open file for reading and writing. The file is created (if it does not exist) or truncated (if it exists).
    // @"w+" = bun.O.RDWR | bun.O.CREAT,
    // ///  Like 'w+' but fails if the path exists.
    // @"wx+" = bun.O.RDWR | bun.O.EXCL,

    _,

    const map = bun.ComptimeStringMap(Mode, .{
        .{ "r", O.RDONLY },
        .{ "rs", O.RDONLY | O.SYNC },
        .{ "sr", O.RDONLY | O.SYNC },
        .{ "r+", O.RDWR },
        .{ "rs+", O.RDWR | O.SYNC },
        .{ "sr+", O.RDWR | O.SYNC },

        .{ "R", O.RDONLY },
        .{ "RS", O.RDONLY | O.SYNC },
        .{ "SR", O.RDONLY | O.SYNC },
        .{ "R+", O.RDWR },
        .{ "RS+", O.RDWR | O.SYNC },
        .{ "SR+", O.RDWR | O.SYNC },

        .{ "w", O.TRUNC | O.CREAT | O.WRONLY },
        .{ "wx", O.TRUNC | O.CREAT | O.WRONLY | O.EXCL },
        .{ "xw", O.TRUNC | O.CREAT | O.WRONLY | O.EXCL },

        .{ "W", O.TRUNC | O.CREAT | O.WRONLY },
        .{ "WX", O.TRUNC | O.CREAT | O.WRONLY | O.EXCL },
        .{ "XW", O.TRUNC | O.CREAT | O.WRONLY | O.EXCL },

        .{ "w+", O.TRUNC | O.CREAT | O.RDWR },
        .{ "wx+", O.TRUNC | O.CREAT | O.RDWR | O.EXCL },
        .{ "xw+", O.TRUNC | O.CREAT | O.RDWR | O.EXCL },

        .{ "W+", O.TRUNC | O.CREAT | O.RDWR },
        .{ "WX+", O.TRUNC | O.CREAT | O.RDWR | O.EXCL },
        .{ "XW+", O.TRUNC | O.CREAT | O.RDWR | O.EXCL },

        .{ "a", O.APPEND | O.CREAT | O.WRONLY },
        .{ "ax", O.APPEND | O.CREAT | O.WRONLY | O.EXCL },
        .{ "xa", O.APPEND | O.CREAT | O.WRONLY | O.EXCL },
        .{ "as", O.APPEND | O.CREAT | O.WRONLY | O.SYNC },
        .{ "sa", O.APPEND | O.CREAT | O.WRONLY | O.SYNC },

        .{ "A", O.APPEND | O.CREAT | O.WRONLY },
        .{ "AX", O.APPEND | O.CREAT | O.WRONLY | O.EXCL },
        .{ "XA", O.APPEND | O.CREAT | O.WRONLY | O.EXCL },
        .{ "AS", O.APPEND | O.CREAT | O.WRONLY | O.SYNC },
        .{ "SA", O.APPEND | O.CREAT | O.WRONLY | O.SYNC },

        .{ "a+", O.APPEND | O.CREAT | O.RDWR },
        .{ "ax+", O.APPEND | O.CREAT | O.RDWR | O.EXCL },
        .{ "xa+", O.APPEND | O.CREAT | O.RDWR | O.EXCL },
        .{ "as+", O.APPEND | O.CREAT | O.RDWR | O.SYNC },
        .{ "sa+", O.APPEND | O.CREAT | O.RDWR | O.SYNC },

        .{ "A+", O.APPEND | O.CREAT | O.RDWR },
        .{ "AX+", O.APPEND | O.CREAT | O.RDWR | O.EXCL },
        .{ "XA+", O.APPEND | O.CREAT | O.RDWR | O.EXCL },
        .{ "AS+", O.APPEND | O.CREAT | O.RDWR | O.SYNC },
        .{ "SA+", O.APPEND | O.CREAT | O.RDWR | O.SYNC },
    });

    pub fn fromJS(ctx: JSC.C.JSContextRef, val: JSC.JSValue) bun.JSError!?FileSystemFlags {
        if (val.isNumber()) {
            if (!val.isInt32()) {
                return ctx.throwValue(ctx.ERR_OUT_OF_RANGE("The value of \"flags\" is out of range. It must be an integer. Received {d}", .{val.asNumber()}).toJS());
            }
            const number = val.coerce(i32, ctx);
            return @as(FileSystemFlags, @enumFromInt(@as(Mode, @intCast(@max(number, 0)))));
        }

        const jsType = val.jsType();
        if (jsType.isStringLike()) {
            const str = val.getZigString(ctx);
            if (str.isEmpty()) {
                return ctx.throwInvalidArguments("Expected flags to be a non-empty string. Learn more at https://nodejs.org/api/fs.html#fs_file_system_flags", .{});
            }
            // it's definitely wrong when the string is super long
            else if (str.len > 12) {
                return ctx.throwInvalidArguments("Invalid flag '{any}'. Learn more at https://nodejs.org/api/fs.html#fs_file_system_flags", .{str});
            }

            const flags = brk: {
                switch (str.is16Bit()) {
                    inline else => |is_16bit| {
                        const chars = if (is_16bit) str.utf16SliceAligned() else str.slice();

                        if (std.ascii.isDigit(@as(u8, @truncate(chars[0])))) {
                            // node allows "0o644" as a string :(
                            if (is_16bit) {
                                const slice = str.toSlice(bun.default_allocator);
                                defer slice.deinit();

                                break :brk std.fmt.parseInt(Mode, slice.slice(), 10) catch null;
                            } else {
                                break :brk std.fmt.parseInt(Mode, chars, 10) catch null;
                            }
                        }
                    },
                }

                break :brk map.getWithEql(str, JSC.ZigString.eqlComptime);
            } orelse {
                return ctx.throwInvalidArguments("Invalid flag '{any}'. Learn more at https://nodejs.org/api/fs.html#fs_file_system_flags", .{str});
            };

            return @as(FileSystemFlags, @enumFromInt(@as(Mode, @intCast(flags))));
        }

        return null;
    }

    /// Equivalent of GetValidFileMode, which is used to implement fs.access and copyFile
    pub fn fromJSNumberOnly(global: *JSC.JSGlobalObject, value: JSC.JSValue, comptime kind: enum { access, copy_file }) bun.JSError!FileSystemFlags {
        // Allow only int32 or null/undefined values.
        if (!value.isNumber()) {
            if (value.isUndefinedOrNull()) {
                return @enumFromInt(switch (kind) {
                    .access => 0, // F_OK
                    .copy_file => 0, // constexpr int kDefaultCopyMode = 0;
                });
            }
            return global.ERR_INVALID_ARG_TYPE("mode must be int32 or null/undefined", .{}).throw();
        }
        const min, const max = .{ 0, 7 };
        if (value.isInt32()) {
            const int: i32 = value.asInt32();
            if (int < min or int > max) {
                return global.ERR_OUT_OF_RANGE(comptime std.fmt.comptimePrint("mode is out of range: >= {d} and <= {d}", .{ min, max }), .{}).throw();
            }
            return @enumFromInt(int);
        } else {
            const float = value.asNumber();
            if (std.math.isNan(float) or std.math.isInf(float) or float < min or float > max) {
                return global.ERR_OUT_OF_RANGE(comptime std.fmt.comptimePrint("mode is out of range: >= {d} and <= {d}", .{ min, max }), .{}).throw();
            }
            return @enumFromInt(@as(i32, @intFromFloat(float)));
        }
    }

    pub fn asInt(flags: FileSystemFlags) tag_type {
        return @intFromEnum(flags);
    }
};

/// Stats and BigIntStats classes from node:fs
pub fn StatType(comptime big: bool) type {
    const Int = if (big) i64 else i32;
    const Float = if (big) i64 else f64;
    const Timestamp = if (big) u64 else u0;

    const Date = packed struct {
        value: Float,
        pub inline fn toJS(this: @This(), globalObject: *JSC.JSGlobalObject) JSC.JSValue {
            const milliseconds = JSC.JSValue.jsNumber(this.value);
            const array: [1]JSC.C.JSValueRef = .{milliseconds.asObjectRef()};
            return JSC.JSValue.c(JSC.C.JSObjectMakeDate(globalObject, 1, &array, null));
        }
    };

    return extern struct {
        pub usingnamespace if (big) JSC.Codegen.JSBigIntStats else JSC.Codegen.JSStats;
        pub usingnamespace bun.New(@This());

        // Stats stores these as i32, but BigIntStats stores all of these as i64
        // On windows, these two need to be u64 as the numbers are often very large.
        dev: u64,
        ino: u64,
        mode: Int,
        nlink: Int,
        uid: Int,
        gid: Int,
        rdev: Int,
        blksize: Int,
        blocks: Int,

        // Always store size as a 64-bit integer
        size: i64,

        // _ms is either a float if Small, or a 64-bit integer if Big
        atime_ms: Float,
        mtime_ms: Float,
        ctime_ms: Float,
        birthtime_ms: Float,

        // _ns is a u64 storing nanosecond precision. it is a u0 when not BigIntStats
        atime_ns: Timestamp = 0,
        mtime_ns: Timestamp = 0,
        ctime_ns: Timestamp = 0,
        birthtime_ns: Timestamp = 0,

        const This = @This();

        const StatTimespec = if (Environment.isWindows) bun.windows.libuv.uv_timespec_t else std.posix.timespec;

        inline fn toNanoseconds(ts: StatTimespec) Timestamp {
            const tv_sec: i64 = @intCast(ts.tv_sec);
            const tv_nsec: i64 = @intCast(ts.tv_nsec);
            return @as(Timestamp, @intCast(tv_sec * 1_000_000_000)) + @as(Timestamp, @intCast(tv_nsec));
        }

        fn toTimeMS(ts: StatTimespec) Float {
            // On windows, Node.js purposefully mis-interprets time values
            // > On win32, time is stored in uint64_t and starts from 1601-01-01.
            // > libuv calculates tv_sec and tv_nsec from it and converts to signed long,
            // > which causes Y2038 overflow. On the other platforms it is safe to treat
            // > negative values as pre-epoch time.
            const tv_sec = if (Environment.isWindows) @as(u32, @bitCast(ts.tv_sec)) else ts.tv_sec;
            const tv_nsec = if (Environment.isWindows) @as(u32, @bitCast(ts.tv_nsec)) else ts.tv_nsec;
            if (big) {
                const sec: i64 = tv_sec;
                const nsec: i64 = tv_nsec;
                return @as(i64, sec * std.time.ms_per_s) +
                    @as(i64, @divTrunc(nsec, std.time.ns_per_ms));
            } else {
                return (@as(f64, @floatFromInt(tv_sec)) * std.time.ms_per_s) +
                    (@as(f64, @floatFromInt(tv_nsec)) / std.time.ns_per_ms);
            }
        }

        const PropertyGetter = fn (this: *This, globalObject: *JSC.JSGlobalObject) JSC.JSValue;

        fn getter(comptime field: meta.FieldEnum(This)) PropertyGetter {
            return struct {
                pub fn callback(this: *This, globalObject: *JSC.JSGlobalObject) JSC.JSValue {
                    const value = @field(this, @tagName(field));
                    const Type = @TypeOf(value);
                    if (comptime big and @typeInfo(Type) == .Int) {
                        if (Type == u64) {
                            return JSC.JSValue.fromUInt64NoTruncate(globalObject, value);
                        }

                        return JSC.JSValue.fromInt64NoTruncate(globalObject, value);
                    }

                    return JSC.JSValue.jsNumber(value);
                }
            }.callback;
        }

        fn dateGetter(comptime field: meta.FieldEnum(This)) PropertyGetter {
            return struct {
                pub fn callback(this: *This, globalObject: *JSC.JSGlobalObject) JSC.JSValue {
                    const value = @field(this, @tagName(field));
                    // Doing `Date{ ... }` here shouldn't actually change the memory layout of `value`
                    // but it will tell comptime code how to convert the i64/f64 to a JS Date.
                    return globalObject.toJS(Date{ .value = value }, .temporary);
                }
            }.callback;
        }

        pub const isBlockDevice_ = JSC.wrapInstanceMethod(This, "isBlockDevice", false);
        pub const isCharacterDevice_ = JSC.wrapInstanceMethod(This, "isCharacterDevice", false);
        pub const isDirectory_ = JSC.wrapInstanceMethod(This, "isDirectory", false);
        pub const isFIFO_ = JSC.wrapInstanceMethod(This, "isFIFO", false);
        pub const isFile_ = JSC.wrapInstanceMethod(This, "isFile", false);
        pub const isSocket_ = JSC.wrapInstanceMethod(This, "isSocket", false);
        pub const isSymbolicLink_ = JSC.wrapInstanceMethod(This, "isSymbolicLink", false);

        pub const isBlockDevice_WithoutTypeChecks = domCall(.isBlockDevice);
        pub const isCharacterDevice_WithoutTypeChecks = domCall(.isCharacterDevice);
        pub const isDirectory_WithoutTypeChecks = domCall(.isDirectory);
        pub const isFIFO_WithoutTypeChecks = domCall(.isFIFO);
        pub const isFile_WithoutTypeChecks = domCall(.isFile);
        pub const isSocket_WithoutTypeChecks = domCall(.isSocket);
        pub const isSymbolicLink_WithoutTypeChecks = domCall(.isSymbolicLink);

        const DOMCallFn = fn (
            *This,
            *JSC.JSGlobalObject,
        ) bun.JSError!JSC.JSValue;
        fn domCall(comptime decl: meta.DeclEnum(This)) DOMCallFn {
            return struct {
                pub fn run(
                    this: *This,
                    _: *JSC.JSGlobalObject,
                ) bun.JSError!JSC.JSValue {
                    return @field(This, @tagName(decl))(this);
                }
            }.run;
        }

        pub const dev = getter(.dev);
        pub const ino = getter(.ino);
        pub const mode = getter(.mode);
        pub const nlink = getter(.nlink);
        pub const uid = getter(.uid);
        pub const gid = getter(.gid);
        pub const rdev = getter(.rdev);
        pub const size = getter(.size);
        pub const blksize = getter(.blksize);
        pub const blocks = getter(.blocks);
        pub const atime = dateGetter(.atime_ms);
        pub const mtime = dateGetter(.mtime_ms);
        pub const ctime = dateGetter(.ctime_ms);
        pub const birthtime = dateGetter(.birthtime_ms);
        pub const atimeMs = getter(.atime_ms);
        pub const mtimeMs = getter(.mtime_ms);
        pub const ctimeMs = getter(.ctime_ms);
        pub const birthtimeMs = getter(.birthtime_ms);
        pub const atimeNs = getter(.atime_ns);
        pub const mtimeNs = getter(.mtime_ns);
        pub const ctimeNs = getter(.ctime_ns);
        pub const birthtimeNs = getter(.birthtime_ns);

        inline fn modeInternal(this: *This) i32 {
            return @truncate(this.mode);
        }

        const S = if (Environment.isWindows) bun.C.S else posix.system.S;

        pub fn isBlockDevice(this: *This) JSC.JSValue {
            return JSC.JSValue.jsBoolean(S.ISBLK(@intCast(this.modeInternal())));
        }

        pub fn isCharacterDevice(this: *This) JSC.JSValue {
            return JSC.JSValue.jsBoolean(S.ISCHR(@intCast(this.modeInternal())));
        }

        pub fn isDirectory(this: *This) JSC.JSValue {
            return JSC.JSValue.jsBoolean(S.ISDIR(@intCast(this.modeInternal())));
        }

        pub fn isFIFO(this: *This) JSC.JSValue {
            return JSC.JSValue.jsBoolean(S.ISFIFO(@intCast(this.modeInternal())));
        }

        pub fn isFile(this: *This) JSC.JSValue {
            return JSC.JSValue.jsBoolean(bun.isRegularFile(this.modeInternal()));
        }

        pub fn isSocket(this: *This) JSC.JSValue {
            return JSC.JSValue.jsBoolean(S.ISSOCK(@intCast(this.modeInternal())));
        }

        /// Node.js says this method is only valid on the result of lstat()
        /// so it's fine if we just include it on stat() because it would
        /// still just return false.
        ///
        /// See https://nodejs.org/api/fs.html#statsissymboliclink
        pub fn isSymbolicLink(this: *This) JSC.JSValue {
            return JSC.JSValue.jsBoolean(S.ISLNK(@intCast(this.modeInternal())));
        }

        // TODO: BigIntStats includes a `_checkModeProperty` but I dont think anyone actually uses it.

        pub fn finalize(this: *This) callconv(.C) void {
            this.destroy();
        }

        pub fn init(stat_: bun.Stat) This {
            const aTime = stat_.atime();
            const mTime = stat_.mtime();
            const cTime = stat_.ctime();

            return .{
                .dev = @intCast(@max(stat_.dev, 0)),
                .ino = @intCast(@max(stat_.ino, 0)),
                .mode = @truncate(@as(i64, @intCast(stat_.mode))),
                .nlink = @truncate(@as(i64, @intCast(stat_.nlink))),
                .uid = @truncate(@as(i64, @intCast(stat_.uid))),
                .gid = @truncate(@as(i64, @intCast(stat_.gid))),
                .rdev = @truncate(@as(i64, @intCast(stat_.rdev))),
                .size = @truncate(@as(i64, @intCast(stat_.size))),
                .blksize = @truncate(@as(i64, @intCast(stat_.blksize))),
                .blocks = @truncate(@as(i64, @intCast(stat_.blocks))),
                .atime_ms = toTimeMS(aTime),
                .mtime_ms = toTimeMS(mTime),
                .ctime_ms = toTimeMS(cTime),
                .atime_ns = if (big) toNanoseconds(aTime) else 0,
                .mtime_ns = if (big) toNanoseconds(mTime) else 0,
                .ctime_ns = if (big) toNanoseconds(cTime) else 0,

                // Linux doesn't include this info in stat
                // maybe it does in statx, but do you really need birthtime? If you do please file an issue.
                .birthtime_ms = if (Environment.isLinux) 0 else toTimeMS(stat_.birthtime()),
                .birthtime_ns = if (big and !Environment.isLinux) toNanoseconds(stat_.birthtime()) else 0,
            };
        }

        pub fn constructor(globalObject: *JSC.JSGlobalObject, callFrame: *JSC.CallFrame) bun.JSError!*This {
            if (big) {
                return globalObject.throwInvalidArguments("BigIntStats is not a constructor", .{});
            }

            // dev, mode, nlink, uid, gid, rdev, blksize, ino, size, blocks, atimeMs, mtimeMs, ctimeMs, birthtimeMs
            var args = callFrame.arguments();

            const atime_ms: f64 = if (args.len > 10 and args[10].isNumber()) args[10].asNumber() else 0;
            const mtime_ms: f64 = if (args.len > 11 and args[11].isNumber()) args[11].asNumber() else 0;
            const ctime_ms: f64 = if (args.len > 12 and args[12].isNumber()) args[12].asNumber() else 0;
            const birthtime_ms: f64 = if (args.len > 13 and args[13].isNumber()) args[13].asNumber() else 0;

            const this = This.new(.{
                .dev = if (args.len > 0 and args[0].isNumber()) @intCast(args[0].toInt32()) else 0,
                .mode = if (args.len > 1 and args[1].isNumber()) args[1].toInt32() else 0,
                .nlink = if (args.len > 2 and args[2].isNumber()) args[2].toInt32() else 0,
                .uid = if (args.len > 3 and args[3].isNumber()) args[3].toInt32() else 0,
                .gid = if (args.len > 4 and args[4].isNumber()) args[4].toInt32() else 0,
                .rdev = if (args.len > 5 and args[5].isNumber()) args[5].toInt32() else 0,
                .blksize = if (args.len > 6 and args[6].isNumber()) args[6].toInt32() else 0,
                .ino = if (args.len > 7 and args[7].isNumber()) @intCast(args[7].toInt32()) else 0,
                .size = if (args.len > 8 and args[8].isNumber()) args[8].toInt32() else 0,
                .blocks = if (args.len > 9 and args[9].isNumber()) args[9].toInt32() else 0,
                .atime_ms = atime_ms,
                .mtime_ms = mtime_ms,
                .ctime_ms = ctime_ms,
                .birthtime_ms = birthtime_ms,
            });

            return this;
        }

        comptime {
            _ = isBlockDevice_WithoutTypeChecks;
            _ = isCharacterDevice_WithoutTypeChecks;
            _ = isDirectory_WithoutTypeChecks;
            _ = isFIFO_WithoutTypeChecks;
            _ = isFile_WithoutTypeChecks;
            _ = isSocket_WithoutTypeChecks;
            _ = isSymbolicLink_WithoutTypeChecks;
        }
    };
}

pub const StatsSmall = StatType(false);
pub const StatsBig = StatType(true);

/// Union between `Stats` and `BigIntStats` where the type can be decided at runtime
pub const Stats = union(enum) {
    big: StatsBig,
    small: StatsSmall,

    pub inline fn init(stat_: bun.Stat, big: bool) Stats {
        if (big) {
            return .{ .big = StatsBig.init(stat_) };
        } else {
            return .{ .small = StatsSmall.init(stat_) };
        }
    }

    pub fn toJSNewlyCreated(this: *const Stats, globalObject: *JSC.JSGlobalObject) JSC.JSValue {
        return switch (this.*) {
            .big => StatsBig.new(this.big).toJS(globalObject),
            .small => StatsSmall.new(this.small).toJS(globalObject),
        };
    }

    pub inline fn toJS(this: *Stats, globalObject: *JSC.JSGlobalObject) JSC.JSValue {
        _ = this;
        _ = globalObject;

        @compileError("Only use Stats.toJSNewlyCreated() or Stats.toJS() directly on a StatsBig or StatsSmall");
    }
};

/// A class representing a directory stream.
///
/// Created by {@link opendir}, {@link opendirSync}, or `fsPromises.opendir()`.
///
/// ```js
/// import { opendir } from 'fs/promises';
///
/// try {
///   const dir = await opendir('./');
///   for await (const dirent of dir)
///     console.log(dirent.name);
/// } catch (err) {
///   console.error(err);
/// }
/// ```
///
/// When using the async iterator, the `fs.Dir` object will be automatically
/// closed after the iterator exits.
/// @since v12.12.0
pub const Dirent = struct {
    name: bun.String,
    path: bun.String,
    // not publicly exposed
    kind: Kind,

    pub const Kind = std.fs.File.Kind;
    pub usingnamespace JSC.Codegen.JSDirent;
    pub usingnamespace bun.New(@This());

    pub fn constructor(global: *JSC.JSGlobalObject, call_frame: *JSC.CallFrame) bun.JSError!*Dirent {
        const name_js, const type_js, const path_js = call_frame.argumentsAsArray(3);

        const name = try name_js.toBunString2(global);
        errdefer name.deref();

        const path = try path_js.toBunString2(global);
        errdefer path.deref();

        const kind = try type_js.toInt32(global);
        switch (kind) {
            // these correspond to the libuv constants
            else => .unknown,
            1 => .file,
            2 => .directory,
            3 => .sym_link,
            4 => .fifo,
            5 => .unix_domain_socket,
            6 => .character_device,
            7 => .block_device,
        }

        return Dirent.new(.{
            .name = name,
            .path = path,
            .kind = kind,
        });
    }

    pub fn toJS(this: *Dirent, globalObject: *JSC.JSGlobalObject) JSC.JSValue {
        const as_js = Dirent.toJSUnchecked(globalObject, this);

        // Immediately create JSString* objects for the name and path
        // So that the GC is aware of them and can collect them if necessary
        Dirent.nameSetCached(as_js, globalObject, this.name.toJS(globalObject));
        Dirent.pathSetCached(as_js, globalObject, this.path.toJS(globalObject));

        return as_js;
    }

    pub fn toJSNewlyCreated(this: *const Dirent, globalObject: *JSC.JSGlobalObject) JSC.JSValue {
        return toJS(Dirent.new(this.*), globalObject);
    }

    pub fn getName(this: *Dirent, globalObject: *JSC.JSGlobalObject) JSC.JSValue {
        return this.name.toJS(globalObject);
    }

    pub fn getPath(this: *Dirent, globalThis: *JSC.JSGlobalObject) JSC.JSValue {
        return this.path.toJS(globalThis);
    }

    pub fn isBlockDevice(
        this: *Dirent,
        _: *JSC.JSGlobalObject,
        _: *JSC.CallFrame,
    ) bun.JSError!JSC.JSValue {
        return JSC.JSValue.jsBoolean(this.kind == std.fs.File.Kind.block_device);
    }
    pub fn isCharacterDevice(
        this: *Dirent,
        _: *JSC.JSGlobalObject,
        _: *JSC.CallFrame,
    ) bun.JSError!JSC.JSValue {
        return JSC.JSValue.jsBoolean(this.kind == std.fs.File.Kind.character_device);
    }
    pub fn isDirectory(
        this: *Dirent,
        _: *JSC.JSGlobalObject,
        _: *JSC.CallFrame,
    ) bun.JSError!JSC.JSValue {
        return JSC.JSValue.jsBoolean(this.kind == std.fs.File.Kind.directory);
    }
    pub fn isFIFO(
        this: *Dirent,
        _: *JSC.JSGlobalObject,
        _: *JSC.CallFrame,
    ) bun.JSError!JSC.JSValue {
        return JSC.JSValue.jsBoolean(this.kind == std.fs.File.Kind.named_pipe or this.kind == std.fs.File.Kind.event_port);
    }
    pub fn isFile(
        this: *Dirent,
        _: *JSC.JSGlobalObject,
        _: *JSC.CallFrame,
    ) bun.JSError!JSC.JSValue {
        return JSC.JSValue.jsBoolean(this.kind == std.fs.File.Kind.file);
    }
    pub fn isSocket(
        this: *Dirent,
        _: *JSC.JSGlobalObject,
        _: *JSC.CallFrame,
    ) bun.JSError!JSC.JSValue {
        return JSC.JSValue.jsBoolean(this.kind == std.fs.File.Kind.unix_domain_socket);
    }
    pub fn isSymbolicLink(
        this: *Dirent,
        _: *JSC.JSGlobalObject,
        _: *JSC.CallFrame,
    ) bun.JSError!JSC.JSValue {
        return JSC.JSValue.jsBoolean(this.kind == std.fs.File.Kind.sym_link);
    }

    pub fn deref(this: *const Dirent) void {
        this.name.deref();
        this.path.deref();
    }

    pub fn finalize(this: *Dirent) void {
        this.deref();
        this.destroy();
    }
};

pub const Process = struct {
    pub fn getArgv0(globalObject: *JSC.JSGlobalObject) callconv(.C) JSC.JSValue {
        return JSC.ZigString.fromUTF8(bun.argv[0]).toJS(globalObject);
    }

    pub fn getExecPath(globalObject: *JSC.JSGlobalObject) callconv(.C) JSC.JSValue {
        const out = bun.selfExePath() catch {
            // if for any reason we are unable to get the executable path, we just return argv[0]
            return getArgv0(globalObject);
        };

        return JSC.ZigString.fromUTF8(out).toJS(globalObject);
    }

    pub fn getExecArgv(globalObject: *JSC.JSGlobalObject) callconv(.C) JSC.JSValue {
        var sfb = std.heap.stackFallback(4096, globalObject.allocator());
        const temp_alloc = sfb.get();
        const vm = globalObject.bunVM();

        if (vm.worker) |worker| {
            // was explicitly overridden for the worker?
            if (worker.execArgv) |execArgv| {
                const array = JSC.JSValue.createEmptyArray(globalObject, execArgv.len);
                for (0..execArgv.len) |i| {
                    array.putIndex(globalObject, @intCast(i), bun.String.init(execArgv[i]).toJS(globalObject));
                }
                return array;
            }
        }

        var args = std.ArrayList(bun.String).initCapacity(temp_alloc, bun.argv.len - 1) catch bun.outOfMemory();
        defer args.deinit();
        defer for (args.items) |*arg| arg.deref();

        var seen_run = false;
        var prev: ?[]const u8 = null;

        // we re-parse the process argv to extract execArgv, since this is a very uncommon operation
        // it isn't worth doing this as a part of the CLI
        for (bun.argv[@min(1, bun.argv.len)..]) |arg| {
            defer prev = arg;

            if (arg.len >= 1 and arg[0] == '-') {
                args.append(bun.String.createUTF8(arg)) catch bun.outOfMemory();
                continue;
            }

            if (!seen_run and bun.strings.eqlComptime(arg, "run")) {
                seen_run = true;
                continue;
            }

            // A set of execArgv args consume an extra argument, so we do not want to
            // confuse these with script names.
            const map = bun.ComptimeStringMap(void, comptime brk: {
                const auto_params = bun.CLI.Arguments.auto_params;
                const KV = struct { []const u8, void };
                var entries: [auto_params.len]KV = undefined;
                var i = 0;
                for (auto_params) |param| {
                    if (param.takes_value != .none) {
                        if (param.names.long) |name| {
                            entries[i] = .{ "--" ++ name, {} };
                            i += 1;
                        }
                        if (param.names.short) |name| {
                            entries[i] = .{ &[_]u8{ '-', name }, {} };
                            i += 1;
                        }
                    }
                }

                var result: [i]KV = undefined;
                @memcpy(&result, entries[0..i]);
                break :brk result;
            });

            if (prev) |p| if (map.has(p)) {
                args.append(bun.String.createUTF8(arg)) catch @panic("OOM");
                continue;
            };

            // we hit the script name
            break;
        }

        return bun.String.toJSArray(globalObject, args.items);
    }

    pub fn getArgv(globalObject: *JSC.JSGlobalObject) callconv(.C) JSC.JSValue {
        const vm = globalObject.bunVM();

        // Allocate up to 32 strings in stack
        var stack_fallback_allocator = std.heap.stackFallback(
            32 * @sizeOf(JSC.ZigString) + (bun.MAX_PATH_BYTES + 1) + 32,
            heap_allocator,
        );
        const allocator = stack_fallback_allocator.get();

        var args_count: usize = vm.argv.len;
        if (vm.worker) |worker| {
            args_count = if (worker.argv) |argv| argv.len else 0;
        }

        const args = allocator.alloc(
            bun.String,
            // argv omits "bun" because it could be "bun run" or "bun" and it's kind of ambiguous
            // argv also omits the script name
            args_count + 2,
        ) catch bun.outOfMemory();
        var args_list = std.ArrayListUnmanaged(bun.String){ .items = args, .capacity = args.len };
        args_list.items.len = 0;

        if (vm.standalone_module_graph != null) {
            // Don't break user's code because they did process.argv.slice(2)
            // Even if they didn't type "bun", we still want to add it as argv[0]
            args_list.appendAssumeCapacity(
                bun.String.static("bun"),
            );
        } else {
            const exe_path = bun.selfExePath() catch null;
            args_list.appendAssumeCapacity(
                if (exe_path) |str| bun.String.fromUTF8(str) else bun.String.static("bun"),
            );
        }

        if (vm.main.len > 0)
            args_list.appendAssumeCapacity(bun.String.fromUTF8(vm.main));

        defer allocator.free(args);

        if (vm.worker) |worker| {
            if (worker.argv) |argv| {
                for (argv) |arg| {
                    args_list.appendAssumeCapacity(bun.String.init(arg));
                }
            }
        } else {
            for (vm.argv) |arg| {
                const str = bun.String.fromUTF8(arg);
                // https://github.com/yargs/yargs/blob/adb0d11e02c613af3d9427b3028cc192703a3869/lib/utils/process-argv.ts#L1
                args_list.appendAssumeCapacity(str);
            }
        }

        return bun.String.toJSArray(globalObject, args_list.items);
    }

    pub fn getCwd(globalObject: *JSC.JSGlobalObject) callconv(.C) JSC.JSValue {
        return JSC.toJSHostValue(globalObject, getCwd_(globalObject));
    }
    fn getCwd_(globalObject: *JSC.JSGlobalObject) bun.JSError!JSC.JSValue {
        var buf: bun.PathBuffer = undefined;
        switch (Path.getCwd(&buf)) {
            .result => |r| return JSC.ZigString.init(r).withEncoding().toJS(globalObject),
            .err => |e| {
                return globalObject.throwValue(e.toJSC(globalObject));
            },
        }
    }

    pub fn setCwd(globalObject: *JSC.JSGlobalObject, to: *JSC.ZigString) callconv(.C) JSC.JSValue {
        return JSC.toJSHostValue(globalObject, setCwd_(globalObject, to));
    }
    fn setCwd_(globalObject: *JSC.JSGlobalObject, to: *JSC.ZigString) bun.JSError!JSC.JSValue {
        if (to.len == 0) {
            return globalObject.throwInvalidArguments("Expected path to be a non-empty string", .{});
        }
        const vm = globalObject.bunVM();
        const fs = vm.transpiler.fs;

        var buf: bun.PathBuffer = undefined;
        const slice = to.sliceZBuf(&buf) catch return globalObject.throw("Invalid path", .{});

        switch (Syscall.chdir(fs.top_level_dir, slice)) {
            .result => {
                // When we update the cwd from JS, we have to update the bundler's version as well
                // However, this might be called many times in a row, so we use a pre-allocated buffer
                // that way we don't have to worry about garbage collector
                const into_cwd_buf = switch (bun.sys.getcwd(&buf)) {
                    .result => |r| r,
                    .err => |err| {
                        _ = Syscall.chdir(fs.top_level_dir, fs.top_level_dir);
                        return globalObject.throwValue(err.toJSC(globalObject));
                    },
                };
                @memcpy(fs.top_level_dir_buf[0..into_cwd_buf.len], into_cwd_buf);
                fs.top_level_dir_buf[into_cwd_buf.len] = 0;
                fs.top_level_dir = fs.top_level_dir_buf[0..into_cwd_buf.len :0];

                const len = fs.top_level_dir.len;
                // Ensure the path ends with a slash
                if (fs.top_level_dir_buf[len - 1] != std.fs.path.sep) {
                    fs.top_level_dir_buf[len] = std.fs.path.sep;
                    fs.top_level_dir_buf[len + 1] = 0;
                    fs.top_level_dir = fs.top_level_dir_buf[0 .. len + 1 :0];
                }
                const withoutTrailingSlash = if (Environment.isWindows) strings.withoutTrailingSlashWindowsPath else strings.withoutTrailingSlash;
                var str = bun.String.createUTF8(withoutTrailingSlash(fs.top_level_dir));
                return str.transferToJS(globalObject);
            },
            .err => |e| {
                return globalObject.throwValue(e.toJSC(globalObject));
            },
        }
    }

    pub fn exit(globalObject: *JSC.JSGlobalObject, code: u8) callconv(.C) void {
        var vm = globalObject.bunVM();
        if (vm.worker) |worker| {
            vm.exit_handler.exit_code = code;
            worker.requestTerminate();
            return;
        }

        vm.exit_handler.exit_code = code;
        vm.onExit();
        vm.globalExit();
    }

    // TODO: switch this to using *bun.wtf.String when it is added
    pub fn Bun__Process__editWindowsEnvVar(k: bun.String, v: bun.String) callconv(.C) void {
        if (k.tag == .Empty) return;
        const wtf1 = k.value.WTFStringImpl;
        var fixed_stack_allocator = std.heap.stackFallback(1025, bun.default_allocator);
        const allocator = fixed_stack_allocator.get();
        var buf1 = allocator.alloc(u16, k.utf16ByteLength() + 1) catch bun.outOfMemory();
        defer allocator.free(buf1);
        var buf2 = allocator.alloc(u16, v.utf16ByteLength() + 1) catch bun.outOfMemory();
        defer allocator.free(buf2);
        const len1: usize = switch (wtf1.is8Bit()) {
            true => bun.strings.copyLatin1IntoUTF16([]u16, buf1, []const u8, wtf1.latin1Slice()).written,
            false => b: {
                @memcpy(buf1[0..wtf1.length()], wtf1.utf16Slice());
                break :b wtf1.length();
            },
        };
        buf1[len1] = 0;
        const str2: ?[*:0]const u16 = if (v.tag != .Dead) str: {
            if (v.tag == .Empty) break :str (&[_]u16{0})[0..0 :0];
            const wtf2 = v.value.WTFStringImpl;
            const len2: usize = switch (wtf2.is8Bit()) {
                true => bun.strings.copyLatin1IntoUTF16([]u16, buf2, []const u8, wtf2.latin1Slice()).written,
                false => b: {
                    @memcpy(buf2[0..wtf2.length()], wtf2.utf16Slice());
                    break :b wtf2.length();
                },
            };
            buf2[len2] = 0;
            break :str buf2[0..len2 :0].ptr;
        } else null;
        _ = bun.windows.SetEnvironmentVariableW(buf1[0..len1 :0].ptr, str2);
    }

    comptime {
        if (Environment.export_cpp_apis and Environment.isWindows) {
            @export(Bun__Process__editWindowsEnvVar, .{ .name = "Bun__Process__editWindowsEnvVar" });
        }
    }

    pub export const Bun__version: [*:0]const u8 = "v" ++ bun.Global.package_json_version;
    pub export const Bun__version_with_sha: [*:0]const u8 = "v" ++ bun.Global.package_json_version_with_sha;
    pub export const Bun__versions_boringssl: [*:0]const u8 = bun.Global.versions.boringssl;
    pub export const Bun__versions_libarchive: [*:0]const u8 = bun.Global.versions.libarchive;
    pub export const Bun__versions_mimalloc: [*:0]const u8 = bun.Global.versions.mimalloc;
    pub export const Bun__versions_picohttpparser: [*:0]const u8 = bun.Global.versions.picohttpparser;
    pub export const Bun__versions_uws: [*:0]const u8 = bun.Environment.git_sha;
    pub export const Bun__versions_webkit: [*:0]const u8 = bun.Global.versions.webkit;
    pub export const Bun__versions_zig: [*:0]const u8 = bun.Global.versions.zig;
    pub export const Bun__versions_zlib: [*:0]const u8 = bun.Global.versions.zlib;
    pub export const Bun__versions_tinycc: [*:0]const u8 = bun.Global.versions.tinycc;
    pub export const Bun__versions_lolhtml: [*:0]const u8 = bun.Global.versions.lolhtml;
    pub export const Bun__versions_c_ares: [*:0]const u8 = bun.Global.versions.c_ares;
    pub export const Bun__versions_libdeflate: [*:0]const u8 = bun.Global.versions.libdeflate;
    pub export const Bun__versions_usockets: [*:0]const u8 = bun.Environment.git_sha;
    pub export const Bun__version_sha: [*:0]const u8 = bun.Environment.git_sha;
    pub export const Bun__versions_lshpack: [*:0]const u8 = bun.Global.versions.lshpack;
    pub export const Bun__versions_zstd: [*:0]const u8 = bun.Global.versions.zstd;
};

pub const PathOrBlob = union(enum) {
    path: JSC.Node.PathOrFileDescriptor,
    blob: Blob,

    const Blob = JSC.WebCore.Blob;

    pub fn fromJSNoCopy(ctx: *JSC.JSGlobalObject, args: *JSC.Node.ArgumentsSlice) bun.JSError!PathOrBlob {
        if (try JSC.Node.PathOrFileDescriptor.fromJS(ctx, args, bun.default_allocator)) |path| {
            return PathOrBlob{
                .path = path,
            };
        }

        const arg = args.nextEat() orelse {
            return ctx.throwInvalidArgumentTypeValue("destination", "path, file descriptor, or Blob", .undefined);
        };
        if (arg.as(Blob)) |blob| {
            return PathOrBlob{
                .blob = blob.*,
            };
        }
        return ctx.throwInvalidArgumentTypeValue("destination", "path, file descriptor, or Blob", arg);
    }
};

comptime {
    std.testing.refAllDecls(Process);
}
