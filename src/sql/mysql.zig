const bun = @import("root").bun;
const JSC = bun.JSC;
const String = bun.String;
const uws = bun.uws;
const std = @import("std");
pub const debug = bun.Output.scoped(.MySQL, false);
const Crypto = JSC.API.Bun.Crypto;
const JSValue = JSC.JSValue;
const BoringSSL = @import("../boringssl.zig");

const sql = @import("./shared_sql.zig");
const QueryBindingIterator = sql.QueryBindingIterator;

pub const protocol = @import("./mysql/mysql_protocol.zig");
pub const types = @import("./mysql/mysql_types.zig");

// MySQL integer types
pub const int1 = u8;
pub const int2 = u16;
pub const int3 = u24;
pub const int4 = u32;
pub const int8 = u64;
const Value = types.Value;
const FieldType = types.FieldType;

pub const MySQLInt8 = int1;
pub const MySQLInt16 = int2;
pub const MySQLInt24 = int3;
pub const MySQLInt32 = int4;
pub const MySQLInt64 = int8;
const mysql = @This();

pub const SSLMode = enum(u8) {
    disable = 0,
    prefer = 1,
    require = 2,
    verify_ca = 3,
    verify_full = 4,
};
pub const Data = sql.Data;
// MySQL capability flags
pub const Capabilities = struct {
    CLIENT_LONG_PASSWORD: bool = false,
    CLIENT_FOUND_ROWS: bool = false,
    CLIENT_LONG_FLAG: bool = false,
    CLIENT_CONNECT_WITH_DB: bool = false,
    CLIENT_NO_SCHEMA: bool = false,
    CLIENT_COMPRESS: bool = false,
    CLIENT_ODBC: bool = false,
    CLIENT_LOCAL_FILES: bool = false,
    CLIENT_IGNORE_SPACE: bool = false,
    CLIENT_PROTOCOL_41: bool = false,
    CLIENT_INTERACTIVE: bool = false,
    CLIENT_SSL: bool = false,
    CLIENT_IGNORE_SIGPIPE: bool = false,
    CLIENT_TRANSACTIONS: bool = false,
    CLIENT_RESERVED: bool = false,
    CLIENT_SECURE_CONNECTION: bool = false,
    CLIENT_MULTI_STATEMENTS: bool = false,
    CLIENT_MULTI_RESULTS: bool = false,
    CLIENT_PS_MULTI_RESULTS: bool = false,
    CLIENT_PLUGIN_AUTH: bool = false,
    CLIENT_CONNECT_ATTRS: bool = false,
    CLIENT_PLUGIN_AUTH_LENENC_CLIENT_DATA: bool = false,
    CLIENT_CAN_HANDLE_EXPIRED_PASSWORDS: bool = false,
    CLIENT_SESSION_TRACK: bool = false,
    CLIENT_DEPRECATE_EOF: bool = false,
    CLIENT_OPTIONAL_RESULTSET_METADATA: bool = false,
    CLIENT_ZSTD_COMPRESSION_ALGORITHM: bool = false,
    CLIENT_QUERY_ATTRIBUTES: bool = false,
    MULTI_FACTOR_AUTHENTICATION: bool = false,
    CLIENT_CAPABILITY_EXTENSION: bool = false,
    CLIENT_SSL_VERIFY_SERVER_CERT: bool = false,
    CLIENT_REMEMBER_OPTIONS: bool = false,

    // Constants with correct shift values from MySQL protocol
    pub const CLIENT_LONG_PASSWORD = 1; // 1 << 0
    pub const CLIENT_FOUND_ROWS = 2; // 1 << 1
    pub const CLIENT_LONG_FLAG = 4; // 1 << 2
    pub const CLIENT_CONNECT_WITH_DB = 8; // 1 << 3
    pub const CLIENT_NO_SCHEMA = 16; // 1 << 4
    pub const CLIENT_COMPRESS = 32; // 1 << 5
    pub const CLIENT_ODBC = 64; // 1 << 6
    pub const CLIENT_LOCAL_FILES = 128; // 1 << 7
    pub const CLIENT_IGNORE_SPACE = 256; // 1 << 8
    pub const CLIENT_PROTOCOL_41 = 512; // 1 << 9
    pub const CLIENT_INTERACTIVE = 1024; // 1 << 10
    pub const CLIENT_SSL = 2048; // 1 << 11
    pub const CLIENT_IGNORE_SIGPIPE = 4096; // 1 << 12
    pub const CLIENT_TRANSACTIONS = 8192; // 1 << 13
    pub const CLIENT_RESERVED = 16384; // 1 << 14
    pub const CLIENT_SECURE_CONNECTION = 32768; // 1 << 15
    pub const CLIENT_MULTI_STATEMENTS = 65536; // 1 << 16
    pub const CLIENT_MULTI_RESULTS = 131072; // 1 << 17
    pub const CLIENT_PS_MULTI_RESULTS = 262144; // 1 << 18
    pub const CLIENT_PLUGIN_AUTH = 524288; // 1 << 19
    pub const CLIENT_CONNECT_ATTRS = 1048576; // 1 << 20
    pub const CLIENT_PLUGIN_AUTH_LENENC_CLIENT_DATA = 2097152; // 1 << 21
    pub const CLIENT_CAN_HANDLE_EXPIRED_PASSWORDS = 4194304; // 1 << 22
    pub const CLIENT_SESSION_TRACK = 8388608; // 1 << 23
    pub const CLIENT_DEPRECATE_EOF = 16777216; // 1 << 24
    pub const CLIENT_OPTIONAL_RESULTSET_METADATA = 33554432; // 1 << 25
    pub const CLIENT_ZSTD_COMPRESSION_ALGORITHM = 67108864; // 1 << 26
    pub const CLIENT_QUERY_ATTRIBUTES = 134217728; // 1 << 27
    pub const MULTI_FACTOR_AUTHENTICATION = 268435456; // 1 << 28
    pub const CLIENT_CAPABILITY_EXTENSION = 536870912; // 1 << 29
    pub const CLIENT_SSL_VERIFY_SERVER_CERT = 1073741824; // 1 << 30
    pub const CLIENT_REMEMBER_OPTIONS = 2147483648; // 1 << 31

    pub fn reject(this: *Capabilities) void {
        this.CLIENT_ZSTD_COMPRESSION_ALGORITHM = false;
        this.MULTI_FACTOR_AUTHENTICATION = false;
        this.CLIENT_CAPABILITY_EXTENSION = false;
        this.CLIENT_SSL_VERIFY_SERVER_CERT = false;
        this.CLIENT_REMEMBER_OPTIONS = false;
        this.CLIENT_COMPRESS = false;
    }

    pub fn format(self: @This(), comptime _: []const u8, _: anytype, writer: anytype) !void {
        var first = true;
        inline for (comptime std.meta.fieldNames(Capabilities)) |field| {
            if (@TypeOf(@field(self, field)) == bool) {
                if (@field(self, field)) {
                    if (!first) {
                        try writer.writeAll(", ");
                    }
                    first = false;
                    try writer.writeAll(field);
                }
            }
        }
    }

    pub fn toInt(this: Capabilities) u32 {
        var value: u32 = 0;

        const fields = .{
            "CLIENT_LONG_PASSWORD",
            "CLIENT_FOUND_ROWS",
            "CLIENT_LONG_FLAG",
            "CLIENT_CONNECT_WITH_DB",
            "CLIENT_NO_SCHEMA",
            "CLIENT_COMPRESS",
            "CLIENT_ODBC",
            "CLIENT_LOCAL_FILES",
            "CLIENT_IGNORE_SPACE",
            "CLIENT_PROTOCOL_41",
            "CLIENT_INTERACTIVE",
            "CLIENT_SSL",
            "CLIENT_IGNORE_SIGPIPE",
            "CLIENT_TRANSACTIONS",
            "CLIENT_RESERVED",
            "CLIENT_SECURE_CONNECTION",
            "CLIENT_MULTI_STATEMENTS",
            "CLIENT_MULTI_RESULTS",
            "CLIENT_PS_MULTI_RESULTS",
            "CLIENT_PLUGIN_AUTH",
            "CLIENT_CONNECT_ATTRS",
            "CLIENT_PLUGIN_AUTH_LENENC_CLIENT_DATA",
            "CLIENT_CAN_HANDLE_EXPIRED_PASSWORDS",
            "CLIENT_SESSION_TRACK",
            "CLIENT_DEPRECATE_EOF",
            "CLIENT_OPTIONAL_RESULTSET_METADATA",
            "CLIENT_ZSTD_COMPRESSION_ALGORITHM",
            "CLIENT_QUERY_ATTRIBUTES",
            "MULTI_FACTOR_AUTHENTICATION",
            "CLIENT_CAPABILITY_EXTENSION",
            "CLIENT_SSL_VERIFY_SERVER_CERT",
            "CLIENT_REMEMBER_OPTIONS",
        };
        inline for (fields) |field| {
            if (@field(this, field)) {
                value |= @field(Capabilities, field);
            }
        }

        return value;
    }

    pub fn fromInt(flags: u32) Capabilities {
        var this: Capabilities = .{};
        inline for (comptime std.meta.fieldNames(Capabilities)) |field| {
            @field(this, field) = (@field(Capabilities, field) & flags) != 0;
        }
        return this;
    }

    pub fn getDefaultCapabilities() Capabilities {
        return .{
            .CLIENT_PROTOCOL_41 = true,
            .CLIENT_PLUGIN_AUTH = true,
            .CLIENT_SECURE_CONNECTION = true,
            .CLIENT_CONNECT_WITH_DB = true,
            .CLIENT_DEPRECATE_EOF = true,
            .CLIENT_TRANSACTIONS = true,
            .CLIENT_MULTI_STATEMENTS = true,
            .CLIENT_MULTI_RESULTS = true,
            .CLIENT_PS_MULTI_RESULTS = true,
            .CLIENT_PLUGIN_AUTH_LENENC_CLIENT_DATA = true,
        };
    }
};

// MySQL authentication methods
pub const AuthMethod = enum {
    mysql_native_password,
    caching_sha2_password,
    sha256_password,

    pub fn scramble(this: AuthMethod, password: []const u8, auth_data: []const u8, buf: *[32]u8) ![]u8 {
        if (password.len == 0) {
            return &.{};
        }

        const len = scrambleLength(this);

        switch (this) {
            .mysql_native_password => @memcpy(buf[0..len], &try protocol.Auth.mysql_native_password.scramble(password, auth_data)),
            .caching_sha2_password => @memcpy(buf[0..len], &try protocol.Auth.caching_sha2_password.scramble(password, auth_data)),
            .sha256_password => @memcpy(buf[0..len], &try protocol.Auth.mysql_native_password.scramble(password, auth_data)),
        }

        return buf[0..len];
    }

    pub fn scrambleLength(this: AuthMethod) usize {
        return switch (this) {
            .mysql_native_password => 20,
            .caching_sha2_password => 32,
            .sha256_password => 20,
        };
    }

    const Map = bun.ComptimeEnumMap(AuthMethod);

    pub const fromString = Map.get;
};

// MySQL connection status flags
pub const StatusFlags = packed struct {
    /// Indicates if a transaction is currently active
    SERVER_STATUS_IN_TRANS: bool = false,
    /// Indicates if autocommit mode is enabled
    SERVER_STATUS_AUTOCOMMIT: bool = false,
    /// Indicates there are more result sets from this query
    SERVER_MORE_RESULTS_EXISTS: bool = false,
    /// Query used a suboptimal index
    SERVER_STATUS_NO_GOOD_INDEX_USED: bool = false,
    /// Query performed a full table scan with no index
    SERVER_STATUS_NO_INDEX_USED: bool = false,
    /// Indicates an open cursor exists
    SERVER_STATUS_CURSOR_EXISTS: bool = false,
    /// Last row in result set has been sent
    SERVER_STATUS_LAST_ROW_SENT: bool = false,
    /// Database was dropped
    SERVER_STATUS_DB_DROPPED: bool = false,
    /// Backslash escaping is disabled
    SERVER_STATUS_NO_BACKSLASH_ESCAPES: bool = false,
    /// Server's metadata has changed
    SERVER_STATUS_METADATA_CHANGED: bool = false,
    /// Query execution was considered slow
    SERVER_QUERY_WAS_SLOW: bool = false,
    /// Statement has output parameters
    SERVER_PS_OUT_PARAMS: bool = false,
    /// Transaction is in read-only mode
    SERVER_STATUS_IN_TRANS_READONLY: bool = false,
    /// Session state has changed
    SERVER_SESSION_STATE_CHANGED: bool = false,
    _padding: u2 = 0,

    pub fn format(self: @This(), comptime _: []const u8, _: anytype, writer: anytype) !void {
        var first = true;
        inline for (comptime std.meta.fieldNames(StatusFlags)) |field| {
            if (@TypeOf(@field(self, field)) == bool) {
                if (@field(self, field)) {
                    if (!first) {
                        try writer.writeAll(", ");
                    }
                    first = false;
                    try writer.writeAll(field);
                }
            }
        }
    }

    pub fn toInt(this: StatusFlags) u16 {
        return @bitCast(this);
    }

    pub fn fromInt(flags: u16) StatusFlags {
        return @bitCast(flags);
    }
};

// MySQL connection state
pub const ConnectionState = enum {
    disconnected,
    connecting,
    handshaking,
    authenticating,
    connected,
    failed,
};

// Add after the existing code:

const Socket = uws.AnySocket;
pub const DEFAULT_CHARSET = types.CharacterSet.default;
const PreparedStatementsMap = std.HashMapUnmanaged(u64, *MySQLStatement, bun.IdentityContext(u64), 80);
const SocketMonitor = @import("./SocketMonitor.zig");

pub const MySQLContext = struct {
    tcp: ?*uws.SocketContext = null,

    onQueryResolveFn: JSC.Strong = .{},
    onQueryRejectFn: JSC.Strong = .{},

    pub fn init(globalObject: *JSC.JSGlobalObject, callframe: *JSC.CallFrame) bun.JSError!JSValue {
        var ctx = &globalObject.bunVM().rareData().mysql_context;
        ctx.onQueryResolveFn.set(globalObject, callframe.argument(0));
        ctx.onQueryRejectFn.set(globalObject, callframe.argument(1));

        return .undefined;
    }

    comptime {
        if (!JSC.is_bindgen) {
            const js_init = JSC.toJSHostFunction(init);
            @export(js_init, .{ .name = "MySQLContext__init" });
        }
    }
};

pub const MySQLConnection = struct {
    socket: Socket,
    status: ConnectionState = .disconnected,
    ref_count: u32 = 1,

    write_buffer: bun.OffsetByteList = .{},
    read_buffer: bun.OffsetByteList = .{},
    last_message_start: u32 = 0,
    sequence_id: u8 = 0,

    requests: std.fifo.LinearFifo(*MySQLQuery, .Dynamic) = std.fifo.LinearFifo(*MySQLQuery, .Dynamic).init(bun.default_allocator),
    statements: PreparedStatementsMap = .{},

    poll_ref: bun.Async.KeepAlive = .{},
    globalObject: *JSC.JSGlobalObject,

    pending_activity_count: std.atomic.Value(u32) = std.atomic.Value(u32).init(0),
    js_value: JSValue = JSValue.undefined,

    is_ready_for_query: bool = false,

    server_version: bun.ByteList = .{},
    connection_id: u32 = 0,
    capabilities: Capabilities = .{},
    character_set: types.CharacterSet = types.CharacterSet.default,
    status_flags: StatusFlags = .{},

    auth_plugin: ?AuthMethod = null,
    auth_state: AuthState = .{ .pending = {} },

    tls_ctx: ?*uws.SocketContext = null,
    tls_config: JSC.API.ServerConfig.SSLConfig = .{},
    tls_status: TLSStatus = .none,
    ssl_mode: SSLMode = .disable,

    on_connect: JSC.Strong = .{},
    on_close: JSC.Strong = .{},

    auth_data: []const u8 = "",
    database: []const u8 = "",
    user: []const u8 = "",
    password: []const u8 = "",
    options: []const u8 = "",
    options_buf: []const u8 = "",

    pub const AuthState = union(enum) {
        pending: void,
        native_password: void,
        caching_sha2: CachingSha2,
        ok: void,

        pub const CachingSha2 = union(enum) {
            fast_auth,
            full_auth,
            waiting_key,
        };
    };

    pub usingnamespace JSC.Codegen.JSMySQLConnection;

    pub fn hasPendingActivity(this: *MySQLConnection) bool {
        @fence(.acquire);
        return this.pending_activity_count.load(.acquire) > 0;
    }

    fn updateHasPendingActivity(this: *MySQLConnection) void {
        @fence(.release);
        const a: u32 = if (this.requests.count > 0) 1 else 0;
        const b: u32 = if (this.status != .disconnected) 1 else 0;
        this.pending_activity_count.store(a + b, .release);
    }

    pub fn setStatus(this: *MySQLConnection, status: ConnectionState) void {
        defer this.updateHasPendingActivity();

        if (this.status == status) return;

        this.status = status;
        switch (status) {
            .connected => {
                const on_connect = this.on_connect.swap();
                if (on_connect == .zero) return;
                const js_value = this.js_value;
                js_value.ensureStillAlive();
                this.globalObject.queueMicrotask(on_connect, &[_]JSValue{ JSValue.jsNull(), js_value });
                this.poll_ref.unref(this.globalObject.bunVM());
                this.updateHasPendingActivity();
            },
            else => {},
        }
    }

    pub fn finalize(this: *MySQLConnection) void {
        debug("MySQLConnection finalize", .{});

        // Ensure we disconnect before finalizing
        if (this.status != .disconnected) {
            this.disconnect();
        }

        this.js_value = .zero;
        this.deref();
    }

    pub fn doRef(this: *@This(), _: *JSC.JSGlobalObject, _: *JSC.CallFrame) bun.JSError!JSValue {
        this.poll_ref.ref(this.globalObject.bunVM());
        this.updateHasPendingActivity();
        return .undefined;
    }

    pub fn doUnref(this: *@This(), _: *JSC.JSGlobalObject, _: *JSC.CallFrame) bun.JSError!JSValue {
        this.poll_ref.unref(this.globalObject.bunVM());
        this.updateHasPendingActivity();
        return .undefined;
    }

    pub fn doFlush(this: *MySQLConnection, globalObject: *JSC.JSGlobalObject, callframe: *JSC.CallFrame) bun.JSError!JSValue {
        _ = callframe;
        _ = globalObject;
        _ = this;

        return .undefined;
    }

    pub fn createQuery(this: *MySQLConnection, globalObject: *JSC.JSGlobalObject, callframe: *JSC.CallFrame) bun.JSError!JSValue {
        _ = callframe;
        _ = globalObject;
        _ = this;

        return .undefined;
    }

    pub fn getConnected(this: *MySQLConnection, _: *JSC.JSGlobalObject) JSValue {
        return JSValue.jsBoolean(this.status == .connected);
    }

    pub fn doClose(this: *MySQLConnection, globalObject: *JSC.JSGlobalObject, _: *JSC.CallFrame) bun.JSError!JSValue {
        _ = globalObject;
        this.disconnect();
        this.write_buffer.deinit(bun.default_allocator);

        return .undefined;
    }

    pub fn constructor(globalObject: *JSC.JSGlobalObject, callframe: *JSC.CallFrame) bun.JSError!*MySQLConnection {
        _ = callframe;

        globalObject.ERR_ILLEGAL_CONSTRUCTOR("MySQLConnection cannot be constructed directly", .{}).throw();
        return error.JSError;
    }

    pub fn flushData(this: *MySQLConnection) void {
        const chunk = this.write_buffer.remaining();
        if (chunk.len == 0) return;
        const wrote = this.socket.write(chunk, false);
        if (wrote > 0) {
            SocketMonitor.write(chunk[0..@intCast(wrote)]);
            this.write_buffer.consume(@intCast(wrote));
        }
    }

    pub fn failWithJSValue(this: *MySQLConnection, value: JSValue) void {
        defer this.updateHasPendingActivity();
        if (this.status == .failed) return;

        this.status = .failed;
        if (!this.socket.isClosed()) this.socket.close();
        const on_close = this.on_close.swap();
        if (on_close == .zero) return;

        _ = on_close.call(
            this.globalObject,
            this.js_value,
            &[_]JSValue{value},
        ) catch |e| this.globalObject.reportActiveExceptionAsUnhandled(e);
    }

    pub fn fail(this: *MySQLConnection, message: []const u8, err: anyerror) void {
        debug("failed: {s}: {s}", .{ message, @errorName(err) });
        const instance = this.globalObject.createErrorInstance("{s}", .{message});
        instance.put(this.globalObject, JSC.ZigString.static("code"), String.init(@errorName(err)).toJS(this.globalObject));
        this.failWithJSValue(instance);
    }

    pub fn onClose(this: *MySQLConnection) void {
        var vm = this.globalObject.bunVM();
        defer vm.drainMicrotasks();
        this.fail("Connection closed", error.ConnectionClosed);
    }

    pub fn ref(this: *@This()) void {
        bun.assert(this.ref_count > 0);
        this.ref_count += 1;
    }

    pub fn deref(this: *@This()) void {
        const ref_count = this.ref_count;
        this.ref_count -= 1;

        if (ref_count == 1) {
            this.disconnect();
            this.deinit();
        }
    }

    pub fn disconnect(this: *@This()) void {
        if (this.status == .connected) {
            this.status = .disconnected;
            this.poll_ref.disable();

            const requests = this.requests.readableSlice(0);
            this.requests.head = 0;
            this.requests.count = 0;

            // Fail any pending requests
            for (requests) |request| {
                request.onError(.{
                    .error_code = 2013, // CR_SERVER_LOST
                    .error_message = .{ .temporary = "Lost connection to MySQL server" },
                }, this.globalObject);
            }

            this.socket.close();
        }
    }

    const Queue = std.fifo.LinearFifo(*MySQLQuery, .Dynamic);

    fn SocketHandler(comptime ssl: bool) type {
        return struct {
            const SocketType = uws.NewSocketHandler(ssl);
            fn _socket(s: SocketType) Socket {
                if (comptime ssl) {
                    return Socket{ .SocketTLS = s };
                }

                return Socket{ .SocketTCP = s };
            }
            pub fn onOpen(this: *MySQLConnection, socket: SocketType) void {
                this.onOpen(_socket(socket));
            }

            fn onHandshake_(this: *MySQLConnection, _: anytype, success: i32, ssl_error: uws.us_bun_verify_error_t) void {
                this.onHandshake(success, ssl_error);
            }

            pub const onHandshake = if (ssl) onHandshake_ else null;

            pub fn onClose(this: *MySQLConnection, socket: SocketType, _: i32, _: ?*anyopaque) void {
                _ = socket;
                this.onClose();
            }

            pub fn onEnd(this: *MySQLConnection, socket: SocketType) void {
                _ = socket;
                this.onClose();
            }

            pub fn onConnectError(this: *MySQLConnection, socket: SocketType, _: i32) void {
                _ = socket;
                this.onClose();
            }

            pub fn onTimeout(this: *MySQLConnection, socket: SocketType) void {
                _ = socket;
                this.onTimeout();
            }

            pub fn onData(this: *MySQLConnection, socket: SocketType, data: []const u8) void {
                _ = socket;
                this.onData(data);
            }

            pub fn onWritable(this: *MySQLConnection, socket: SocketType) void {
                _ = socket;
                this.onDrain();
            }
        };
    }

    pub fn onTimeout(this: *MySQLConnection) void {
        this.fail("Connection timed out", error.ConnectionTimedOut);
    }

    pub fn onDrain(this: *MySQLConnection) void {
        const event_loop = this.globalObject.bunVM().eventLoop();
        event_loop.enter();
        defer event_loop.exit();
        this.flushData();
    }

    pub fn call(globalObject: *JSC.JSGlobalObject, callframe: *JSC.CallFrame) bun.JSError!JSC.JSValue {
        var vm = globalObject.bunVM();
        const arguments = callframe.arguments_old(10).slice();
        const hostname_str = arguments[0].toBunString(globalObject);
        defer hostname_str.deref();
        const port = arguments[1].coerce(i32, globalObject);

        const username_str = arguments[2].toBunString(globalObject);
        defer username_str.deref();
        const password_str = arguments[3].toBunString(globalObject);
        defer password_str.deref();
        const database_str = arguments[4].toBunString(globalObject);
        defer database_str.deref();
        // TODO: update this to match MySQL.
        const ssl_mode: SSLMode = switch (arguments[5].toInt32()) {
            0 => .disable,
            1 => .prefer,
            2 => .require,
            3 => .verify_ca,
            4 => .verify_full,
            else => .disable,
        };

        const tls_object = arguments[6];

        var tls_config: JSC.API.ServerConfig.SSLConfig = .{};
        var tls_ctx: ?*uws.SocketContext = null;
        if (ssl_mode != .disable) {
            tls_config = if (tls_object.isBoolean() and tls_object.toBoolean())
                .{}
            else if (tls_object.isObject())
                (JSC.API.ServerConfig.SSLConfig.fromJS(vm, globalObject, tls_object) catch return .zero) orelse .{}
            else {
                return globalObject.throwInvalidArguments("tls must be a boolean or an object", .{});
            };

            if (globalObject.hasException()) {
                tls_config.deinit();
                return .zero;
            }

            if (tls_config.reject_unauthorized != 0)
                tls_config.request_cert = 1;

            // We create it right here so we can throw errors early.
            const context_options = tls_config.asUSockets();
            var err: uws.create_bun_socket_error_t = .none;
            tls_ctx = uws.us_create_bun_socket_context(1, vm.uwsLoop(), @sizeOf(*MySQLConnection), context_options, &err) orelse {
                if (err != .none) {
                    globalObject.throw("failed to create TLS context", .{});
                } else {
                    globalObject.throwValue(err.toJS(globalObject));
                }
                return .zero;
            };

            if (err != .none) {
                tls_config.deinit();
                globalObject.throwValue(err.toJS(globalObject));
                if (tls_ctx) |ctx| {
                    ctx.deinit(true);
                }
                return .zero;
            }

            uws.NewSocketHandler(true).configure(tls_ctx.?, true, *MySQLConnection, SocketHandler(true));
        }

        var username: []const u8 = "";
        var password: []const u8 = "";
        var database: []const u8 = "";
        var options: []const u8 = "";

        const options_str = arguments[7].toBunString(globalObject);
        defer options_str.deref();

        const options_buf: []u8 = brk: {
            var b = bun.StringBuilder{};
            b.cap += username_str.utf8ByteLength() + 1 + password_str.utf8ByteLength() + 1 + database_str.utf8ByteLength() + 1 + options_str.utf8ByteLength() + 1;

            b.allocate(bun.default_allocator) catch {};
            var u = username_str.toUTF8WithoutRef(bun.default_allocator);
            defer u.deinit();
            username = b.append(u.slice());

            var p = password_str.toUTF8WithoutRef(bun.default_allocator);
            defer p.deinit();
            password = b.append(p.slice());

            var d = database_str.toUTF8WithoutRef(bun.default_allocator);
            defer d.deinit();
            database = b.append(d.slice());

            var o = options_str.toUTF8WithoutRef(bun.default_allocator);
            defer o.deinit();
            options = b.append(o.slice());

            break :brk b.allocatedSlice();
        };

        const on_connect = arguments[8];
        const on_close = arguments[9];

        var ptr = try bun.default_allocator.create(MySQLConnection);

        ptr.* = MySQLConnection{
            .globalObject = globalObject,
            .on_connect = JSC.Strong.create(on_connect, globalObject),
            .on_close = JSC.Strong.create(on_close, globalObject),
            .database = database,
            .user = username,
            .password = password,
            .options = options,
            .options_buf = options_buf,
            .socket = .{
                .SocketTCP = .{ .socket = .{ .detached = {} } },
            },
            .requests = Queue.init(bun.default_allocator),
            .statements = PreparedStatementsMap{},
            .tls_config = tls_config,
            .tls_ctx = tls_ctx,
            .ssl_mode = ssl_mode,
            .tls_status = if (ssl_mode != .disable) .pending else .none,
            .character_set = types.CharacterSet.default,
        };

        ptr.updateHasPendingActivity();
        ptr.poll_ref.ref(vm);
        const js_value = ptr.toJS(globalObject);
        js_value.ensureStillAlive();
        ptr.js_value = js_value;

        {
            const hostname = hostname_str.toUTF8(bun.default_allocator);
            defer hostname.deinit();

            const ctx = vm.rareData().mysql_context.tcp orelse brk: {
                var err: uws.create_bun_socket_error_t = .none;
                const ctx_ = uws.us_create_bun_socket_context(0, vm.uwsLoop(), @sizeOf(*MySQLConnection), uws.us_bun_socket_context_options_t{}, &err).?;
                uws.NewSocketHandler(false).configure(ctx_, true, *MySQLConnection, SocketHandler(false));
                vm.rareData().mysql_context.tcp = ctx_;
                break :brk ctx_;
            };
            ptr.socket = .{
                .SocketTCP = uws.SocketTCP.connectAnon(hostname.slice(), port, ctx, ptr, false) catch |err| {
                    tls_config.deinit();
                    if (tls_ctx) |tls| {
                        tls.deinit(true);
                    }
                    ptr.deinit();
                    return globalObject.throwError(err, "failed to connect to mysql");
                },
            };
        }

        return js_value;
    }

    pub fn deinit(this: *MySQLConnection) void {
        debug("MySQLConnection deinit", .{});

        bun.assert(this.ref_count == 0);

        var requests = this.requests;
        defer requests.deinit();
        this.requests = Queue.init(bun.default_allocator);

        // Clear any pending requests first
        for (requests.readableSlice(0)) |request| {
            request.onError(.{
                .error_code = 2013,
                .error_message = .{ .temporary = "Connection closed" },
            }, this.globalObject);
        }
        this.write_buffer.deinit(bun.default_allocator);
        this.read_buffer.deinit(bun.default_allocator);
        this.statements.deinit(bun.default_allocator);
        bun.default_allocator.free(this.auth_data);
        this.auth_data = "";
        this.tls_config.deinit();
        if (this.tls_ctx) |ctx| {
            ctx.deinit(true);
        }
        bun.default_allocator.free(this.options_buf);
        bun.default_allocator.destroy(this);
    }

    pub fn onOpen(this: *MySQLConnection, socket: Socket) void {
        this.socket = socket;
        this.status = .handshaking;
        this.poll_ref.ref(this.globalObject.bunVM());
        this.updateHasPendingActivity();

        // Do nothing, the server will start the handshake process.
        // Set a timeout so that we at least don't do nothing forever.
        socket.setTimeout(120);
    }

    pub fn onHandshake(this: *MySQLConnection, success: i32, ssl_error: uws.us_bun_verify_error_t) void {
        debug("onHandshake: {d} {d}", .{ success, ssl_error.error_no });

        if (success != 1) {
            this.failWithJSValue(ssl_error.toJS(this.globalObject));
            return;
        }

        if (this.tls_config.reject_unauthorized == 1) {
            if (ssl_error.error_no != 0) {
                this.failWithJSValue(ssl_error.toJS(this.globalObject));
                return;
            }
            const ssl_ptr = @as(*BoringSSL.SSL, @ptrCast(this.socket.getNativeHandle()));
            if (BoringSSL.SSL_get_servername(ssl_ptr, 0)) |servername| {
                const hostname = servername[0..bun.len(servername)];
                if (!BoringSSL.checkServerIdentity(ssl_ptr, hostname)) {
                    this.failWithJSValue(ssl_error.toJS(this.globalObject));
                }
            }
        }
    }

    pub fn onData(this: *MySQLConnection, data: []const u8) void {
        this.ref();
        const vm = this.globalObject.bunVM();

        // Clear the timeout.
        this.socket.setTimeout(0);

        defer {
            if (this.status == .connected and this.requests.readableLength() == 0 and this.write_buffer.remaining().len == 0) {
                // Don't keep the process alive when there's nothing to do.
                this.poll_ref.unref(vm);
            } else if (this.status == .connected) {
                // Keep the process alive if there's something to do.
                this.poll_ref.ref(vm);
            }

            this.deref();
        }

        const event_loop = vm.eventLoop();
        event_loop.enter();
        defer event_loop.exit();
        SocketMonitor.read(data);

        if (this.read_buffer.remaining().len == 0) {
            var consumed: usize = 0;
            var offset: usize = 0;
            const reader = protocol.StackReader.init(data, &consumed, &offset);
            this.processPackets(protocol.StackReader, reader) catch |err| {
                if (err == error.ShortRead) {
                    if (comptime bun.Environment.allow_assert) {
                        debug("Received short read: last_message_start: {d}, head: {d}, len: {d}", .{
                            offset,
                            consumed,
                            data.len,
                        });
                    }

                    this.read_buffer.head = 0;
                    this.last_message_start = 0;
                    this.read_buffer.byte_list.len = 0;
                    this.read_buffer.write(bun.default_allocator, data[offset..]) catch @panic("failed to write to read buffer");
                } else {
                    if (comptime bun.Environment.allow_assert) {
                        bun.handleErrorReturnTrace(err, @errorReturnTrace());
                    }
                    this.fail("Failed to read data", err);
                }
            };
            return;
        }

        {
            this.read_buffer.head = this.last_message_start;

            this.read_buffer.write(bun.default_allocator, data) catch @panic("failed to write to read buffer");
            this.processPackets(Reader, this.bufferedReader()) catch |err| {
                if (err != error.ShortRead) {
                    if (comptime bun.Environment.allow_assert) {
                        if (@errorReturnTrace()) |trace| {
                            debug("Error: {s}\n{}", .{ @errorName(err), trace });
                        }
                    }
                    this.fail("Failed to read data", err);
                    return;
                }

                if (comptime bun.Environment.allow_assert) {
                    debug("Received short read: last_message_start: {d}, head: {d}, len: {d}", .{
                        this.last_message_start,
                        this.read_buffer.head,
                        this.read_buffer.byte_list.len,
                    });
                }

                return;
            };

            this.last_message_start = 0;
            this.read_buffer.head = 0;
        }
    }

    pub fn processPackets(this: *MySQLConnection, comptime Context: type, reader: protocol.NewReader(Context)) !void {
        while (true) {
            reader.markMessageStart();

            // Read packet header
            const header = protocol.PacketHeader.decode(reader.peek()) orelse break;
            reader.skip(protocol.PACKET_HEADER_SIZE);

            // Ensure we have the full packet
            reader.ensureCapacity(header.length) catch |err| {
                if (err == error.ShortRead) {
                    reader.skip(-@as(isize, @intCast(protocol.PACKET_HEADER_SIZE)));
                }

                return err;
            };

            // Update sequence id
            this.sequence_id = header.sequence_id +% 1;

            // Process packet based on connection state
            switch (this.status) {
                .handshaking => try this.handleHandshake(Context, reader),
                .authenticating => try this.handleAuth(Context, reader),
                .connected => try this.handleCommand(Context, reader),
                else => {
                    debug("Unexpected packet in state {s}", .{@tagName(this.status)});
                    return error.UnexpectedPacket;
                },
            }
        }
    }

    pub fn handleHandshake(this: *MySQLConnection, comptime Context: type, reader: protocol.NewReader(Context)) !void {
        var handshake = protocol.HandshakeV10{};
        try handshake.decode(reader);
        defer handshake.deinit();

        // Store server info
        this.server_version = try handshake.server_version.toOwned();
        this.connection_id = handshake.connection_id;
        this.capabilities = handshake.capability_flags;
        // Override with utf8mb4 instead of using server's default
        this.character_set = DEFAULT_CHARSET;
        this.status_flags = handshake.status_flags;

        debug(
            \\Handshake
            \\   Server Version: {s}
            \\   Connection ID:  {d}
            \\   Character Set:  {d} ({s})
            \\   Server Capabilities:   [ {} ] {d}
            \\   Status Flags:   [ {} ]
            \\
        , .{
            this.server_version.slice(),
            this.connection_id,
            this.character_set,
            this.character_set.label(),
            this.capabilities,
            this.capabilities.toInt(),
            this.status_flags,
        });

        if (this.auth_data.len > 0) {
            bun.default_allocator.free(this.auth_data);
            this.auth_data = "";
        }

        // Store auth data
        const auth_data = try bun.default_allocator.alloc(u8, handshake.auth_plugin_data_part_1.len + handshake.auth_plugin_data_part_2.len);
        @memcpy(auth_data[0..8], &handshake.auth_plugin_data_part_1);
        @memcpy(auth_data[8..], handshake.auth_plugin_data_part_2);
        this.auth_data = auth_data;

        // Get auth plugin
        if (handshake.auth_plugin_name.slice().len > 0) {
            this.auth_plugin = mysql.AuthMethod.fromString(handshake.auth_plugin_name.slice()) orelse {
                this.fail("Unsupported auth plugin", error.UnsupportedAuthPlugin);
                return;
            };
        }

        // Update status
        this.status = .authenticating;

        // Send auth response
        try this.sendHandshakeResponse();
    }

    pub fn handleAuth(this: *MySQLConnection, comptime Context: type, reader: protocol.NewReader(Context)) !void {
        const first_byte = try reader.int(u8);
        reader.skip(-1);

        debug("Auth packet: 0x{x:0>2}", .{first_byte});

        switch (first_byte) {
            @intFromEnum(protocol.PacketType.OK) => {
                var ok = protocol.OKPacket{};
                try ok.decode(reader);
                defer ok.deinit();

                this.status = .connected;
                this.status_flags = ok.status_flags;
                this.is_ready_for_query = true;
            },

            @intFromEnum(protocol.PacketType.ERROR) => {
                var err = protocol.ErrorPacket{};
                try err.decode(reader);
                defer err.deinit();

                this.failWithJSValue(err.toJS(this.globalObject));
                return error.AuthenticationFailed;
            },

            @intFromEnum(protocol.PacketType.MORE_DATA) => {
                // Handle various MORE_DATA cases
                if (this.auth_plugin) |plugin| {
                    switch (plugin) {
                        .caching_sha2_password => {
                            var response = protocol.Auth.caching_sha2_password.Response{};
                            try response.decode(reader);
                            defer response.deinit();

                            switch (response.status) {
                                .success => {
                                    this.status = .connected;
                                    this.is_ready_for_query = true;
                                },
                                .fail => {
                                    this.fail("Authentication failed", error.AuthenticationFailed);
                                },
                                .full_auth => {
                                    // Server wants full authentication
                                    this.auth_state = .{ .caching_sha2 = .full_auth };
                                    // Send empty response to continue auth
                                    try this.sendAuthSwitchResponse(plugin, "");
                                },
                            }
                        },
                        else => {
                            debug("Unexpected auth continuation for plugin: {s}", .{@tagName(plugin)});
                            return error.UnexpectedPacket;
                        },
                    }
                } else if (first_byte == @intFromEnum(protocol.PacketType.LOCAL_INFILE)) {
                    // Handle LOCAL INFILE request
                    var infile = protocol.LocalInfileRequest{};
                    try infile.decode(reader);
                    defer infile.deinit();

                    // We don't support LOCAL INFILE for security reasons
                    this.fail("LOCAL INFILE not supported", error.LocalInfileNotSupported);
                    return;
                } else {
                    debug("Received auth continuation without plugin", .{});
                    return error.UnexpectedPacket;
                }
            },

            protocol.PacketType.AUTH_SWITCH => {
                var auth_switch = protocol.AuthSwitchRequest{};
                try auth_switch.decode(reader);
                defer auth_switch.deinit();

                // Update auth plugin and data
                const auth_method = mysql.AuthMethod.fromString(auth_switch.plugin_name.slice()) orelse {
                    this.fail("Unsupported auth plugin", error.UnsupportedAuthPlugin);
                    return;
                };

                // Send new auth response
                try this.sendAuthSwitchResponse(auth_method, auth_switch.plugin_data.slice());
            },

            else => {
                debug("Unexpected auth packet: 0x{x:0>2}", .{first_byte});
                return error.UnexpectedPacket;
            },
        }
    }

    pub fn handleCommand(this: *MySQLConnection, comptime Context: type, reader: protocol.NewReader(Context)) !void {
        // Get the current request if any
        if (this.requests.readableLength() == 0) {
            debug("Received unexpected command response", .{});
            return error.UnexpectedPacket;
        }

        const request = this.requests.peekItem(0);

        // Handle based on request type
        if (request.statement) |statement| {
            switch (statement.status) {
                .parsing => {
                    // We're waiting for prepare response
                    try this.handlePreparedStatement(Context, reader);
                },
                .prepared => {
                    // We're waiting for execute response
                    try this.handleResultSet(Context, reader);
                },
                .failed => {
                    // Statement failed, clean up
                    if (this.requests.readItem()) |req| {
                        req.onError(statement.error_response, this.globalObject);
                    }
                },
            }
            return;
        }

        // Regular query response
        try this.handleResultSet(Context, reader);
    }

    pub fn sendHandshakeResponse(this: *MySQLConnection) !void {
        // Only require password for caching_sha2_password when connecting for the first time
        if (this.auth_plugin) |plugin| {
            const requires_password = switch (plugin) {
                .caching_sha2_password => false, // Allow empty password, server will handle auth flow
                .sha256_password => true, // Always requires password
                .mysql_native_password => false, // Allows empty password
            };

            if (requires_password and this.password.len == 0) {
                this.fail("Password required for authentication", error.PasswordRequired);
                return;
            }
        }

        var response = protocol.HandshakeResponse41{
            .capability_flags = this.capabilities,
            .max_packet_size = 16777216,
            .character_set = DEFAULT_CHARSET,
            .username = .{ .temporary = this.user },
            .database = .{ .temporary = this.database },
            .auth_plugin_name = .{
                .temporary = if (this.auth_plugin) |plugin|
                    switch (plugin) {
                        .mysql_native_password => "mysql_native_password",
                        .caching_sha2_password => "caching_sha2_password",
                        .sha256_password => "sha256_password",
                    }
                else
                    "",
            },
            .auth_response = .{ .empty = {} },
        };
        defer response.deinit();

        // Generate auth response based on plugin
        var scrambled_buf: [32]u8 = undefined;
        if (this.auth_plugin) |plugin| {
            if (this.auth_data.len == 0) {
                this.fail("Missing auth data from server", error.MissingAuthData);
                return;
            }

            response.auth_response = .{ .temporary = try plugin.scramble(this.password, this.auth_data, &scrambled_buf) };
        }

        try response.write(this.writer());
        this.capabilities = response.capability_flags;
        this.flushData();

        this.socket.setTimeout(0);
    }

    pub fn sendAuthSwitchResponse(this: *MySQLConnection, auth_method: mysql.AuthMethod, plugin_data: []const u8) !void {
        var response = protocol.AuthSwitchResponse{};
        defer response.deinit();

        var scrambled_buf: [32]u8 = undefined;

        response.auth_response = .{
            .temporary = try auth_method.scramble(this.password, plugin_data, &scrambled_buf),
        };

        try response.write(this.writer());
        this.flushData();
    }

    pub const Writer = struct {
        connection: *MySQLConnection,

        pub fn write(this: Writer, data: []const u8) anyerror!void {
            var buffer = &this.connection.write_buffer;
            try buffer.write(bun.default_allocator, data);
        }

        pub fn pwrite(this: Writer, data: []const u8, index: usize) anyerror!void {
            @memcpy(this.connection.write_buffer.byte_list.slice()[index..][0..data.len], data);
        }

        pub fn offset(this: Writer) usize {
            return this.connection.write_buffer.len();
        }
    };

    pub fn writer(this: *MySQLConnection) protocol.NewWriter(Writer) {
        return .{
            .wrapped = .{
                .connection = this,
            },
        };
    }

    pub const Reader = struct {
        connection: *MySQLConnection,

        pub fn markMessageStart(this: Reader) void {
            this.connection.last_message_start = this.connection.read_buffer.head;
        }

        pub const ensureLength = ensureCapacity;

        pub fn peek(this: Reader) []const u8 {
            return this.connection.read_buffer.remaining();
        }

        pub fn skip(this: Reader, count: isize) void {
            if (count < 0) {
                const abs_count = @abs(count);
                if (abs_count > this.connection.read_buffer.head) {
                    this.connection.read_buffer.head = 0;
                    return;
                }
                this.connection.read_buffer.head -= @intCast(abs_count);
                return;
            }

            const ucount: usize = @intCast(count);
            if (this.connection.read_buffer.head + ucount > this.connection.read_buffer.byte_list.len) {
                this.connection.read_buffer.head = this.connection.read_buffer.byte_list.len;
                return;
            }

            this.connection.read_buffer.head += @intCast(ucount);
        }

        pub fn ensureCapacity(this: Reader, count: usize) bool {
            return this.connection.read_buffer.remaining().len >= count;
        }

        pub fn read(this: Reader, count: usize) anyerror!Data {
            const remaining = this.peek();
            if (remaining.len < count) {
                return error.ShortRead;
            }

            this.skip(@intCast(count));
            return Data{
                .temporary = remaining[0..count],
            };
        }

        pub fn readZ(this: Reader) anyerror!Data {
            const remaining = this.peek();
            if (bun.strings.indexOfChar(remaining, 0)) |zero| {
                this.skip(@intCast(zero + 1));
                return Data{
                    .temporary = remaining[0..zero],
                };
            }

            return error.ShortRead;
        }
    };

    pub fn bufferedReader(this: *MySQLConnection) protocol.NewReader(Reader) {
        return .{
            .wrapped = .{
                .connection = this,
            },
        };
    }

    pub fn handlePreparedStatement(this: *MySQLConnection, comptime Context: type, reader: protocol.NewReader(Context)) !void {
        const first_byte = try reader.int(u8);
        reader.skip(-1);

        switch (first_byte) {
            @intFromEnum(protocol.PacketType.OK) => {
                var ok = protocol.StmtPrepareOKPacket{};
                try ok.decode(reader);

                // Get the current request
                const request = this.requests.peekItem(0);
                if (request.statement) |statement| {
                    statement.statement_id = ok.statement_id;

                    // Read parameter definitions if any
                    if (ok.num_params > 0) {
                        const params = try bun.default_allocator.alloc(types.FieldType, ok.num_params);
                        errdefer bun.default_allocator.free(params);

                        for (params) |*param| {
                            var column = protocol.ColumnDefinition41{};
                            defer column.deinit();
                            try column.decode(reader);
                            param.* = column.column_type;
                        }

                        statement.params = params;
                    }

                    // Read column definitions if any
                    if (ok.num_columns > 0) {
                        const columns = try bun.default_allocator.alloc(protocol.ColumnDefinition41, ok.num_columns);
                        var consumed: u32 = 0;
                        errdefer {
                            for (columns[0..consumed]) |*column| {
                                column.deinit();
                            }
                            bun.default_allocator.free(columns);
                        }

                        for (columns) |*column| {
                            try column.decode(reader);
                            consumed += 1;
                        }

                        statement.columns = columns;
                    }

                    statement.status = .prepared;

                    if (request.status == .pending) {
                        try request.bindAndExecute(this.writer(), statement, this.globalObject);
                        this.flushData();
                    }
                } else {
                    debug("Unexpected prepared statement packet", .{});
                }
            },

            @intFromEnum(protocol.PacketType.ERROR) => {
                var err = protocol.ErrorPacket{};
                try err.decode(reader);
                defer err.deinit();

                if (this.requests.readItem()) |request| {
                    if (request.statement) |statement| {
                        statement.status = .failed;
                        statement.error_response = err;
                    }
                    request.onError(err, this.globalObject);
                }
            },

            else => {
                debug("Unexpected prepared statement packet: 0x{x:0>2}", .{first_byte});
                return error.UnexpectedPacket;
            },
        }
    }

    pub fn handleResultSet(this: *MySQLConnection, comptime Context: type, reader: protocol.NewReader(Context)) !void {
        const first_byte = try reader.int(u8);
        reader.skip(-1);

        switch (first_byte) {
            @intFromEnum(protocol.PacketType.OK) => {
                var ok = protocol.OKPacket{};
                try ok.decode(reader);
                defer ok.deinit();

                this.status_flags = ok.status_flags;
                this.is_ready_for_query = true;

                if (this.requests.readItem()) |request| {
                    request.onSuccess(this.globalObject);
                }
            },

            @intFromEnum(protocol.PacketType.ERROR) => {
                var err = protocol.ErrorPacket{};
                try err.decode(reader);
                defer err.deinit();

                if (this.requests.readItem()) |request| {
                    request.onError(err, this.globalObject);
                }
            },

            else => {
                // This is likely a result set header
                var header = protocol.ResultSetHeader{};
                try header.decode(reader);

                if (this.requests.readableLength() > 0) {
                    const request = this.requests.peekItem(0);

                    // Read column definitions
                    const columns = try bun.default_allocator.alloc(protocol.ColumnDefinition41, header.field_count);
                    var columns_read: u32 = 0;
                    errdefer {
                        for (columns[0..columns_read]) |*column| {
                            column.deinit();
                        }
                        bun.default_allocator.free(columns);
                    }

                    for (columns) |*column| {
                        try column.decode(reader);
                        columns_read += 1;
                    }

                    const globalThis = this.globalObject;
                    // Start reading rows
                    while (true) {
                        const row_first_byte = try reader.byte();
                        reader.skip(-1);

                        switch (row_first_byte) {
                            @intFromEnum(protocol.PacketType.EOF) => {
                                var eof = protocol.EOFPacket{};
                                try eof.decode(reader);

                                // Update status flags and finish
                                this.status_flags = eof.status_flags;
                                this.is_ready_for_query = true;
                                this.requests.discard(1);

                                request.onSuccess(this.globalObject);
                                break;
                            },

                            @intFromEnum(protocol.PacketType.ERROR) => {
                                var err = protocol.ErrorPacket{};
                                try err.decode(reader);
                                defer err.deinit();
                                this.requests.discard(1);
                                request.onError(err, this.globalObject);
                                break;
                            },

                            else => {
                                var stack_fallback = std.heap.stackFallback(4096, bun.default_allocator);
                                const allocator = stack_fallback.get();

                                // Read row data
                                var row = protocol.ResultSet.Row{
                                    .columns = columns,
                                    .binary = request.binary,
                                };
                                defer row.deinit(allocator);
                                try row.decode(allocator, reader);

                                const pending_value = MySQLQuery.pendingValueGetCached(request.thisValue) orelse .zero;

                                // Process row data
                                const row_value = row.toJS(request.statement.?.structure(request.thisValue, globalThis), pending_value, globalThis);
                                if (globalThis.hasException()) {
                                    request.onJSError(globalThis.tryTakeException().?, globalThis);
                                    return error.JSError;
                                }

                                if (pending_value == .zero) {
                                    MySQLQuery.pendingValueSetCached(request.thisValue, globalThis, row_value);
                                }
                            },
                        }
                    }
                } else {
                    debug("Unexpected result set packet", .{});
                }
            },
        }
    }

    pub fn closeStatement(this: *MySQLConnection, statement: *MySQLStatement) !void {
        var close = protocol.PreparedStatement.Close{
            .statement_id = statement.statement_id,
        };

        try close.write(this.writer());
        this.flushData();
    }

    pub fn resetStatement(this: *MySQLConnection, statement: *MySQLStatement) !void {
        var reset = protocol.PreparedStatement.Reset{
            .statement_id = statement.statement_id,
        };

        try reset.write(this.writer());
        this.flushData();
    }
};

pub const MySQLStatement = struct {
    cached_structure: JSC.Strong = .{},
    ref_count: u32 = 1,
    statement_id: u32 = 0,
    params: []const types.FieldType = &[_]types.FieldType{},
    columns: []const protocol.ColumnDefinition41 = &[_]protocol.ColumnDefinition41{},
    signature: Signature,
    status: Status = Status.parsing,
    error_response: protocol.ErrorPacket = .{ .error_code = 0 },

    pub const Status = enum {
        parsing,
        prepared,
        failed,
    };

    pub usingnamespace bun.NewRefCounted(@This(), deinit);

    pub fn deinit(this: *MySQLStatement) void {
        debug("MySQLStatement deinit", .{});

        bun.assert(this.ref_count == 0);

        for (this.columns) |*column| {
            @constCast(column).deinit();
        }
        bun.default_allocator.free(this.columns);
        bun.default_allocator.free(this.params);
        this.cached_structure.deinit();
        this.error_response.deinit();
        this.signature.deinit();
        bun.default_allocator.destroy(this);
    }

    pub fn structure(this: *MySQLStatement, owner: JSValue, globalObject: *JSC.JSGlobalObject) JSValue {
        return this.cached_structure.get() orelse {
            const names = bun.default_allocator.alloc(bun.String, this.columns.len) catch return .undefined;
            defer {
                for (names) |*name| {
                    name.deref();
                }
                bun.default_allocator.free(names);
            }
            for (this.columns, names) |*column, *name| {
                name.* = String.fromUTF8(column.name.slice());
            }
            const structure_ = JSC.JSObject.createStructure(
                globalObject,
                owner,
                @truncate(this.columns.len),
                names.ptr,
            );
            this.cached_structure.set(globalObject, structure_);
            return structure_;
        };
    }
};

pub const MySQLQuery = struct {
    statement: ?*MySQLStatement = null,
    query: bun.String = bun.String.empty,
    cursor_name: bun.String = bun.String.empty,
    thisValue: JSValue = .undefined,
    target: JSC.Strong = JSC.Strong.init(),
    status: Status = Status.pending,
    is_done: bool = false,
    ref_count: std.atomic.Value(u32) = std.atomic.Value(u32).init(1),
    binary: bool = false,
    pending_value: JSC.Strong = .{},

    pub usingnamespace JSC.Codegen.JSMySQLQuery;

    pub const Status = enum(u8) {
        pending,
        written,
        running,
        binding,
        success,
        fail,

        pub fn isRunning(this: Status) bool {
            return this == .running or this == .binding;
        }
    };

    pub fn hasPendingActivity(this: *@This()) bool {
        return this.ref_count.load(.monotonic) > 1;
    }

    pub fn deinit(this: *@This()) void {
        if (this.statement) |statement| {
            statement.deref();
        }
        this.query.deref();
        this.cursor_name.deref();
        this.target.deinit();
        this.pending_value.deinit();

        bun.default_allocator.destroy(this);
    }

    pub fn finalize(this: *@This()) void {
        debug("MySQLQuery finalize", .{});

        // Clean up any statement reference
        if (this.statement) |statement| {
            statement.deref();
            this.statement = null;
        }

        this.thisValue = .zero;
        this.deref();
    }

    pub usingnamespace bun.NewThreadSafeRefCounted(@This(), deinit);

    pub fn onNoData(this: *@This(), globalObject: *JSC.JSGlobalObject) void {
        this.status = .success;
        defer this.deref();

        const thisValue = this.thisValue;
        const targetValue = this.target.trySwap() orelse JSValue.zero;
        if (thisValue == .zero or targetValue == .zero) {
            return;
        }

        const vm = JSC.VirtualMachine.get();
        const function = vm.rareData().mysql_context.onQueryResolveFn.get().?;
        const event_loop = vm.eventLoop();
        event_loop.runCallback(function, globalObject, thisValue, &.{
            targetValue,
            this.pending_value.trySwap() orelse .undefined,
            JSValue.jsNumber(0),
            JSValue.jsNumber(0),
        });
    }

    pub fn onWriteFail(this: *@This(), err: anyerror, globalObject: *JSC.JSGlobalObject) void {
        this.status = .fail;
        this.pending_value.deinit();
        const thisValue = this.thisValue;
        const targetValue = this.target.trySwap() orelse JSValue.zero;
        if (thisValue == .zero or targetValue == .zero) {
            return;
        }

        const instance = globalObject.createErrorInstance("Failed to bind query: {s}", .{@errorName(err)});

        const vm = JSC.VirtualMachine.get();
        const function = vm.rareData().mysql_context.onQueryRejectFn.get().?;
        const event_loop = vm.eventLoop();
        event_loop.runCallback(function, globalObject, thisValue, &.{
            targetValue,
            instance,
        });
    }

    pub fn bindAndExecute(this: *MySQLQuery, writer: anytype, statement: *MySQLStatement, globalObject: *JSC.JSGlobalObject) !void {
        var execute = protocol.PreparedStatement.Execute{
            .statement_id = statement.statement_id,
            .param_types = statement.params,
            .iteration_count = 1,
        };
        defer execute.deinit();
        try this.bind(&execute, globalObject);
        try execute.write(writer);
        this.status = .written;
    }

    pub fn bind(this: *MySQLQuery, execute: *protocol.PreparedStatement.Execute, globalObject: *JSC.JSGlobalObject) !void {
        const binding_value = MySQLQuery.bindingGetCached(this.thisValue) orelse .zero;
        const columns_value = MySQLQuery.columnsGetCached(this.thisValue) orelse .zero;

        var iter = QueryBindingIterator.init(binding_value, columns_value, globalObject);

        var i: u32 = 0;
        var params = try bun.default_allocator.alloc(Data, execute.params.len);
        errdefer {
            for (params[0..i]) |*param| {
                param.deinit();
            }
            bun.default_allocator.free(params);
        }
        while (iter.next()) |js_value| {
            const param = execute.param_types[i];
            var value = try Value.fromJS(
                js_value,
                globalObject,
                param,
                // TODO: unsigned
                false,
            );
            defer value.deinit(bun.default_allocator);
            params[i] = try value.toData(param);
            i += 1;
        }

        if (iter.anyFailed()) {
            return error.InvalidQueryBinding;
        }

        this.status = .binding;
        execute.params = params;
    }

    pub fn onError(this: *@This(), err: protocol.ErrorPacket, globalObject: *JSC.JSGlobalObject) void {
        this.status = .fail;
        defer {
            // Clean up statement reference on error
            if (this.statement) |statement| {
                statement.deref();
                this.statement = null;
            }
            this.deref();
        }

        const thisValue = this.thisValue;
        const targetValue = this.target.trySwap() orelse JSValue.zero;
        if (thisValue == .zero or targetValue == .zero) {
            return;
        }

        var vm = JSC.VirtualMachine.get();
        const function = vm.rareData().mysql_context.onQueryRejectFn.get().?;
        globalObject.queueMicrotask(function, &[_]JSValue{ targetValue, err.toJS(globalObject) });
    }

    pub fn onJSError(this: *@This(), exception: JSC.JSValue, globalObject: *JSC.JSGlobalObject) void {
        this.status = .fail;
        defer {
            // Clean up statement reference on error
            if (this.statement) |statement| {
                statement.deref();
                this.statement = null;
            }
            this.deref();
        }

        const thisValue = this.thisValue;
        const targetValue = this.target.trySwap() orelse JSValue.zero;
        if (thisValue == .zero or targetValue == .zero) {
            return;
        }

        var vm = JSC.VirtualMachine.get();
        const function = vm.rareData().mysql_context.onQueryRejectFn.get().?;
        globalObject.queueMicrotask(function, &[_]JSValue{ targetValue, exception.toError().? });
    }

    pub fn onSuccess(this: *@This(), globalObject: *JSC.JSGlobalObject) void {
        this.status = .success;
        defer this.deref();

        const thisValue = this.thisValue;
        const targetValue = this.target.trySwap() orelse JSValue.zero;
        if (thisValue == .zero or targetValue == .zero) {
            return;
        }

        const vm = JSC.VirtualMachine.get();
        const function = vm.rareData().mysql_context.onQueryResolveFn.get().?;
        const event_loop = vm.eventLoop();
        event_loop.runCallback(function, globalObject, thisValue, &.{
            targetValue,
            this.pending_value.trySwap() orelse .undefined,
            JSValue.jsNumber(0),
            JSValue.jsNumber(0),
        });
    }

    pub fn constructor(globalThis: *JSC.JSGlobalObject, callframe: *JSC.CallFrame) bun.JSError!*MySQLQuery {
        _ = callframe;
        return globalThis.throw2("MySQLQuery cannot be constructed directly", .{});
    }

    pub fn estimatedSize(this: *MySQLQuery) usize {
        _ = this;
        return @sizeOf(MySQLQuery);
    }

    pub fn call(globalThis: *JSC.JSGlobalObject, callframe: *JSC.CallFrame) bun.JSError!JSC.JSValue {
        const arguments = callframe.argumentsUndef(4).slice();
        const query = arguments[0];
        const values = arguments[1];
        const columns = arguments[3];

        if (!query.isString()) {
            globalThis.throw("query must be a string", .{});
            return .zero;
        }

        if (values.jsType() != .Array) {
            globalThis.throw("values must be an array", .{});
            return .zero;
        }

        const pending_value = arguments[2];
        if (!pending_value.jsType().isArrayLike()) {
            globalThis.throwInvalidArgumentType("query", "pendingValue", "Array");
            return .zero;
        }

        var ptr = bun.default_allocator.create(MySQLQuery) catch |err| {
            return globalThis.throwError(err, "failed to allocate query");
        };

        const this_value = ptr.toJS(globalThis);
        this_value.ensureStillAlive();

        ptr.* = .{
            .query = query.toBunString(globalThis),
            .thisValue = this_value,
        };
        ptr.query.ref();

        MySQLQuery.bindingSetCached(this_value, globalThis, values);
        MySQLQuery.pendingValueSetCached(this_value, globalThis, pending_value);
        if (columns != .undefined) {
            MySQLQuery.columnsSetCached(this_value, globalThis, columns);
        }
        ptr.pending_value.set(globalThis, pending_value);

        return this_value;
    }

    pub fn doDone(this: *@This(), globalObject: *JSC.JSGlobalObject, _: *JSC.CallFrame) bun.JSError!JSValue {
        _ = globalObject;
        this.is_done = true;
        return .undefined;
    }

    pub fn doCancel(this: *MySQLQuery, globalObject: *JSC.JSGlobalObject, callframe: *JSC.CallFrame) bun.JSError!JSValue {
        _ = callframe;
        _ = globalObject;
        _ = this;

        return .undefined;
    }

    pub fn doRun(this: *MySQLQuery, globalObject: *JSC.JSGlobalObject, callframe: *JSC.CallFrame) bun.JSError!JSValue {
        var arguments_ = callframe.arguments_old(2);
        const arguments = arguments_.slice();
        var connection: *MySQLConnection = arguments[0].as(MySQLConnection) orelse {
            globalObject.throw("connection must be a MySQLConnection", .{});
            return error.JSError;
        };
        var query = arguments[1];

        if (!query.isObject()) {
            globalObject.throwInvalidArgumentType("run", "query", "Query");
            return error.JSError;
        }

        this.target.set(globalObject, query);
        const binding_value = MySQLQuery.bindingGetCached(callframe.this()) orelse .zero;
        var query_str = this.query.toUTF8(bun.default_allocator);
        defer query_str.deinit();
        const columns_value = MySQLQuery.columnsGetCached(callframe.this()) orelse .undefined;

        var signature = Signature.generate(globalObject, query_str.slice(), binding_value, columns_value) catch |err| {
            if (!globalObject.hasException())
                return globalObject.throwError(err, "failed to generate signature");
            return error.JSError;
        };
        errdefer signature.deinit();

        const writer = connection.writer();

        const entry = connection.statements.getOrPut(bun.default_allocator, bun.hash(signature.name)) catch |err| {
            return globalObject.throwError(err, "failed to allocate statement");
        };

        const has_params = signature.fields.len > 0;
        var did_write = false;

        enqueue: {
            if (entry.found_existing) {
                this.statement = entry.value_ptr.*;
                this.statement.?.ref();
                signature.deinit();
                signature = Signature{};

                if (has_params and this.statement.?.status == .parsing) {
                    // if it has params, we need to wait for PrepareOk to be received before we can write the data
                } else {
                    this.binary = true;
                    this.bindAndExecute(writer, this.statement.?, globalObject) catch |err| {
                        if (!globalObject.hasException())
                            return globalObject.throwError(err, "failed to bind and execute query");
                        return error.JSError;
                    };
                    did_write = true;
                }

                break :enqueue;
            }

            const stmt = bun.default_allocator.create(MySQLStatement) catch |err| {
                return globalObject.throwError(err, "failed to allocate statement");
            };
            stmt.* = .{
                .signature = signature,
                .ref_count = 2,
                .status = .parsing,
                .statement_id = 0,
            };
            this.statement = stmt;
            entry.value_ptr.* = stmt;
        }

        try connection.requests.writeItem(this);
        this.ref();
        this.status = if (did_write) .binding else .pending;

        if (connection.is_ready_for_query)
            connection.flushData();

        return .undefined;
    }

    comptime {
        if (!JSC.is_bindgen) {
            const jscall = JSC.toJSHostFunction(call);
            @export(jscall, .{ .name = "MySQLQuery__createInstance" });
        }
    }
};

pub const Signature = struct {
    fields: []const types.FieldType = &.{},
    name: []const u8 = "",
    query: []const u8 = "",

    pub fn deinit(this: *Signature) void {
        bun.default_allocator.free(this.fields);
        bun.default_allocator.free(this.name);
        bun.default_allocator.free(this.query);
    }

    pub fn hash(this: *const Signature) u64 {
        var hasher = std.hash.Wyhash.init(0);
        hasher.update(this.name);
        hasher.update(std.mem.sliceAsBytes(this.fields));
        return hasher.final();
    }

    pub fn generate(globalObject: *JSC.JSGlobalObject, query: []const u8, array_value: JSValue, columns: JSValue) !Signature {
        var fields = std.ArrayList(types.FieldType).init(bun.default_allocator);
        var name = try std.ArrayList(u8).initCapacity(bun.default_allocator, query.len);

        name.appendSliceAssumeCapacity(query);

        errdefer {
            fields.deinit();
            name.deinit();
        }

        var iter = QueryBindingIterator.init(array_value, columns, globalObject);

        while (iter.next()) |value| {
            if (value.isEmptyOrUndefinedOrNull()) {
                // Allow MySQL to decide the type
                try fields.append(.MYSQL_TYPE_NULL);
                try name.appendSlice(".null");
                continue;
            }

            const tag = try types.FieldType.fromJS(globalObject, value);
            try name.appendSlice(@tagName(tag));
            try fields.append(tag);
        }

        if (iter.anyFailed()) {
            return error.InvalidQueryBinding;
        }

        return Signature{
            .name = name.items,
            .fields = fields.items,
            .query = try bun.default_allocator.dupe(u8, query),
        };
    }
};

pub const TLSStatus = enum {
    none,
    pending,
    message_sent,
    ssl_not_available,
    ssl_ok,
};

pub fn createBinding(globalObject: *JSC.JSGlobalObject) JSValue {
    const binding = JSValue.createEmptyObjectWithNullPrototype(globalObject);
    const ZigString = JSC.ZigString;
    binding.put(globalObject, ZigString.static("MySQLConnection"), MySQLConnection.getConstructor(globalObject));
    binding.put(globalObject, ZigString.static("init"), JSC.JSFunction.create(globalObject, "init", MySQLContext.init, 0, .{}));
    binding.put(
        globalObject,
        ZigString.static("createQuery"),
        JSC.JSFunction.create(globalObject, "createQuery", MySQLQuery.call, 2, .{}),
    );

    binding.put(
        globalObject,
        ZigString.static("createConnection"),
        JSC.JSFunction.create(globalObject, "createConnection", MySQLConnection.call, 10, .{}),
    );

    return binding;
}
