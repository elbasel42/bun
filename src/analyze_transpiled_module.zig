const std = @import("std");
const bun = @import("bun.zig");
const js_ast = bun.JSAst;
const Ast = js_ast.Ast;

// export fn Bun__analyzeTranspiledModule(globalObject: *bun.JSC.JSGlobalObject, moduleKey: *anyopaque, sourceCode: *anyopaque) *bun.JSC.JSModuleRecord {
//     // const record = bun.JSC.JSModuleRecord.create(globalObject, globalObject.vm(), globalObject.moduleRecordStructure(), moduleKey, sourceCode, declaredVariables, lexicalVariables, features);
//     _ = globalObject;
//     _ = moduleKey;
//     _ = sourceCode;
//     @panic("TODO analyzeTranspiledModule");
// }

pub const RecordKind = enum(u8) {
    /// var_name
    declared_variable,
    /// let_name
    lexical_variable,
    /// module_name, import_name, local_name
    import_info_single,
    /// module_name, import_name = '*', local_name
    import_info_namespace,
    /// export_name, import_name, module_name
    export_info_indirect,
    /// export_name, local_name, padding (for local => indirect conversion)
    export_info_local,
    /// export_name, module_name
    export_info_namespace,
    /// module_name
    export_info_star,
    _,

    pub fn len(record: RecordKind) !usize {
        return switch (record) {
            .declared_variable, .lexical_variable => 1,
            .import_info_single => 3,
            .import_info_namespace => 3,
            .export_info_indirect => 3,
            .export_info_local => 3,
            .export_info_namespace => 2,
            .export_info_star => 1,
            else => return error.InvalidRecordKind,
        };
    }
};

pub const ModuleInfoDeserialized = struct {
    strings_len: u32,
    strings: []const u8, // null-terminated
    requested_modules_keys: []align(1) const StringID,
    requested_modules_values: []align(1) const ModuleInfo.FetchParameters,
    buffer: []align(1) const StringID,
    record_kinds: []align(1) const RecordKind,
    contains_import_meta: bool,

    fn eat(rem: *[]const u8, len: usize) ![]const u8 {
        if (rem.*.len < len) return error.BadModuleInfo;
        const res = rem.*[0..len];
        rem.* = rem.*[len..];
        return res;
    }
    fn eatC(rem: *[]const u8, comptime len: usize) !*const [len]u8 {
        if (rem.*.len < len) return error.BadModuleInfo;
        const res = rem.*[0..len];
        rem.* = rem.*[len..];
        return res;
    }
    pub fn parse(source: []const u8) !ModuleInfoDeserialized {
        var rem = source[0..];
        const record_kinds_len = std.mem.readInt(u32, try eatC(&rem, 4), .little);
        const record_kinds = std.mem.bytesAsSlice(RecordKind, try eat(&rem, record_kinds_len * @sizeOf(RecordKind)));
        const buffer_len = std.mem.readInt(u32, try eatC(&rem, 4), .little);
        const buffer = std.mem.bytesAsSlice(StringID, try eat(&rem, buffer_len * @sizeOf(StringID)));
        const requested_modules_len = std.mem.readInt(u32, try eatC(&rem, 4), .little);
        const requested_modules_keys = std.mem.bytesAsSlice(StringID, try eat(&rem, requested_modules_len * @sizeOf(StringID)));
        const requested_modules_values = std.mem.bytesAsSlice(ModuleInfo.FetchParameters, try eat(&rem, requested_modules_len * @sizeOf(ModuleInfo.FetchParameters)));
        const contains_import_meta = (try eatC(&rem, 1))[0] != 0;
        const strings_len = std.mem.readInt(u32, try eatC(&rem, 4), .little);
        const strings = rem;

        return .{
            .strings_len = strings_len,
            .strings = strings,
            .requested_modules_keys = requested_modules_keys,
            .requested_modules_values = requested_modules_values,
            .buffer = buffer,
            .record_kinds = record_kinds,
            .contains_import_meta = contains_import_meta,
        };
    }
};

pub const ModuleInfo = struct {
    /// all strings in wtf-8. index in hashmap = StringID
    strings: bun.StringArrayHashMap(void),
    requested_modules: std.AutoArrayHashMap(StringID, FetchParameters),
    buffer: std.ArrayList(StringID),
    record_kinds: std.ArrayList(RecordKind),
    contains_import_meta: bool,
    indirect_exports_fixed: bool = false,

    pub fn serialize(self: *ModuleInfo, writer: anytype) !void {
        bun.assert(self.indirect_exports_fixed);
        try writer.writeInt(u32, @truncate(self.record_kinds.items.len), .little);
        try writer.writeAll(std.mem.sliceAsBytes(self.record_kinds.items));
        try writer.writeInt(u32, @truncate(self.buffer.items.len), .little);
        try writer.writeAll(std.mem.sliceAsBytes(self.buffer.items));

        try writer.writeInt(u32, @truncate(self.requested_modules.count()), .little);
        try writer.writeAll(std.mem.sliceAsBytes(self.requested_modules.keys()));
        try writer.writeAll(std.mem.sliceAsBytes(self.requested_modules.values()));

        try writer.writeInt(u8, @intFromBool(self.contains_import_meta), .little);

        try writer.writeInt(u32, @truncate(self.strings.count()), .little);
        for (self.strings.keys()) |s| {
            try writer.writeAll(s);
            try writer.writeByte(0);
        }
    }
    pub fn serializeToComment(self: *ModuleInfo, final_writer: anytype) !void {
        var res = std.ArrayList(u8).init(bun.default_allocator);
        defer res.deinit();
        const writer = res.writer();
        try self.serialize(writer);

        const enc_buf = try bun.default_allocator.alloc(u8, std.base64.standard.Encoder.calcSize(res.items.len));
        defer bun.default_allocator.free(enc_buf);
        const enc_res = std.base64.standard.Encoder.encode(enc_buf, res.items);

        try final_writer.writeAll("\n// <jsc-module-info>\n// ");
        try final_writer.writeAll(enc_res);
        try final_writer.writeAll("\n// </jsc-module-info>\n");
    }

    pub const FetchParameters = enum(u32) {
        none = std.math.maxInt(u32),
        javascript = std.math.maxInt(u32) - 1,
        webassembly = std.math.maxInt(u32) - 2,
        json = std.math.maxInt(u32) - 3,
        _, // host_defined: cast to StringID
        pub fn hostDefined(value: StringID) FetchParameters {
            return @enumFromInt(@intFromEnum(value));
        }
    };

    pub const VarKind = enum { declared, lexical };
    pub fn addVar(self: *ModuleInfo, name: []const u8, kind: VarKind) !void {
        switch (kind) {
            .declared => try self.addDeclaredVariable(name),
            .lexical => try self.addLexicalVariable(name),
        }
    }

    fn _addRecord(self: *ModuleInfo, kind: RecordKind, data: []const StringID) !void {
        bun.assert(!self.indirect_exports_fixed);
        bun.assert(data.len == kind.len() catch unreachable);
        try self.record_kinds.append(kind);
        try self.buffer.appendSlice(data);
    }
    pub fn addDeclaredVariable(self: *ModuleInfo, id: []const u8) !void {
        try self._addRecord(.declared_variable, &.{try self.str(id)});
    }
    pub fn addLexicalVariable(self: *ModuleInfo, id: []const u8) !void {
        try self._addRecord(.lexical_variable, &.{try self.str(id)});
    }
    pub fn addImportInfoSingle(self: *ModuleInfo, module_name: []const u8, import_name: []const u8, local_name: []const u8) !void {
        try self._addRecord(.import_info_single, &.{ try self.str(module_name), try self.str(import_name), try self.str(local_name) });
    }
    pub fn addImportInfoNamespace(self: *ModuleInfo, module_name: []const u8, local_name: []const u8) !void {
        try self._addRecord(.import_info_namespace, &.{ try self.str(module_name), try self.str("*"), try self.str(local_name) });
    }
    pub fn addExportInfoIndirect(self: *ModuleInfo, export_name: []const u8, import_name: []const u8, module_name: []const u8) !void {
        try self._addRecord(.export_info_indirect, &.{ try self.str(export_name), try self.str(import_name), try self.str(module_name) });
    }
    pub fn addExportInfoLocal(self: *ModuleInfo, export_name: []const u8, local_name: []const u8) !void {
        try self._addRecord(.export_info_local, &.{ try self.str(export_name), try self.str(local_name), @enumFromInt(0) });
    }
    pub fn addExportInfoNamespace(self: *ModuleInfo, export_name: []const u8, module_name: []const u8) !void {
        try self._addRecord(.export_info_namespace, &.{ try self.str(export_name), try self.str(module_name) });
    }
    pub fn addExportInfoStar(self: *ModuleInfo, module_name: []const u8) !void {
        try self._addRecord(.export_info_star, &.{try self.str(module_name)});
    }

    pub fn init(allocator: std.mem.Allocator) ModuleInfo {
        return .{
            .strings = bun.StringArrayHashMap(void).init(allocator),
            .requested_modules = std.AutoArrayHashMap(StringID, FetchParameters).init(allocator),
            .buffer = std.ArrayList(StringID).init(allocator),
            .record_kinds = std.ArrayList(RecordKind).init(allocator),
            .contains_import_meta = false,
        };
    }
    pub fn deinit(self: *ModuleInfo) void {
        for (self.strings.keys()) |string| self.strings.allocator.free(string);
        self.strings.deinit();
        self.requested_modules.deinit();
        self.buffer.deinit();
        self.record_kinds.deinit();
    }
    pub fn str(self: *ModuleInfo, value: []const u8) !StringID {
        const gpres = try self.strings.getOrPut(value);
        if (gpres.found_existing) return @enumFromInt(@as(u32, @intCast(gpres.index)));
        gpres.key_ptr.* = try self.strings.allocator.dupe(u8, value);
        gpres.value_ptr.* = {};
        return @enumFromInt(@as(u32, @intCast(gpres.index)));
    }
    pub const star_default = "*default*";
    pub fn requestModule(self: *ModuleInfo, import_record_path: []const u8, fetch_parameters: FetchParameters) !void {
        // jsc only records the attributes of the first import with the given import_record_path. so only put if not exists.
        const gpres = try self.requested_modules.getOrPut(try self.str(import_record_path));
        if (!gpres.found_existing) gpres.value_ptr.* = fetch_parameters;
    }

    /// find any exports marked as 'local' that are actually 'indirect' and fix them
    pub fn fixupIndirectExports(self: *ModuleInfo) !void {
        bun.assert(!self.indirect_exports_fixed);
        var local_name_to_module_name = std.AutoArrayHashMap(StringID, [2]StringID).init(self.strings.allocator);
        defer local_name_to_module_name.deinit();
        {
            var i: usize = 0;
            for (self.record_kinds.items) |*k| {
                if (k.* == .import_info_single) try local_name_to_module_name.put(self.buffer.items[i + 2], [2]StringID{ self.buffer.items[i], self.buffer.items[i + 1] });
                i += k.len() catch unreachable;
            }
        }

        {
            var i: usize = 0;
            for (self.record_kinds.items) |*k| {
                if (k.* == .export_info_local) {
                    if (local_name_to_module_name.get(self.buffer.items[i + 1])) |ip| {
                        k.* = .export_info_indirect;
                        self.buffer.items[i + 1] = ip[0];
                        self.buffer.items[i + 2] = ip[1];
                        continue;
                    }
                }
                i += k.len() catch unreachable;
            }
        }
        self.indirect_exports_fixed = true;
    }
};
pub const StringID = enum(u32) {
    _,
};

export fn zig__renderDiff(expected_ptr: [*:0]const u8, expected_len: usize, received_ptr: [*:0]const u8, received_len: usize, globalThis: *bun.JSC.JSGlobalObject) void {
    const DiffFormatter = @import("bun.js/test/diff_format.zig").DiffFormatter;
    const formatter = DiffFormatter{
        .received_string = received_ptr[0..received_len],
        .expected_string = expected_ptr[0..expected_len],
        .globalThis = globalThis,
    };
    const stderr = std.io.getStdErr().writer();
    stderr.print("DIFF:\n{}\n", .{formatter}) catch {};
}

fn fail(result: *c_int, code: c_int) ?*JSModuleRecord {
    result.* = code;
    return null;
}
export fn zig__ModuleInfo__parseFromSourceCode(
    globalObject: *bun.JSC.JSGlobalObject,
    vm: *bun.JSC.VM,
    module_key: *const IdentifierArray,
    source_code: *const SourceCode,
    declared_variables: *VariableEnvironment,
    lexical_variables: *VariableEnvironment,
    source_ptr: [*]const u8,
    source_len: usize,
    failure_reason: *c_int,
) ?*JSModuleRecord {
    const source = source_ptr[0..source_len];
    const l3 = std.mem.lastIndexOfScalar(u8, source, '\n') orelse return fail(failure_reason, 1);
    const l2 = std.mem.lastIndexOfScalar(u8, source[0..l3], '\n') orelse return fail(failure_reason, 1);
    const l1 = std.mem.lastIndexOfScalar(u8, source[0..l2], '\n') orelse return fail(failure_reason, 1);
    const l0 = std.mem.lastIndexOfScalar(u8, source[0..l1], '\n') orelse return fail(failure_reason, 1);

    if (l3 + 1 != source.len) return fail(failure_reason, 1);

    if (!std.mem.eql(u8, source[l0..l1], "\n// <jsc-module-info>")) return fail(failure_reason, 1);
    if (!std.mem.startsWith(u8, source[l1..l2], "\n// ")) return fail(failure_reason, 1);
    if (!std.mem.eql(u8, source[l2..l3], "\n// </jsc-module-info>")) return fail(failure_reason, 1);
    const json_part = source[l1 + "\n// ".len .. l2];

    const dec_res = bun.default_allocator.alloc(u8, std.base64.standard.Decoder.calcSizeForSlice(json_part) catch return fail(failure_reason, 2)) catch bun.outOfMemory();
    defer bun.default_allocator.free(dec_res);
    std.base64.standard.Decoder.decode(dec_res, json_part) catch return fail(failure_reason, 2);

    const res = ModuleInfoDeserialized.parse(dec_res) catch return fail(failure_reason, 2);

    var identifiers = IdentifierArray.create(res.strings_len);
    defer identifiers.destroy();
    {
        var strs_rem = res.strings;
        var i: usize = 0;
        while (std.mem.indexOfScalar(u8, strs_rem, 0)) |next_zero| : (i += 1) {
            const sub = strs_rem[0..next_zero];
            strs_rem = strs_rem[next_zero + 1 ..];
            if (bun.strings.eqlComptime(sub, ModuleInfo.star_default)) {
                identifiers.setFromStarDefault(i, vm);
            } else {
                identifiers.setFromUtf8(i, vm, sub);
            }
        }
    }

    {
        var i: usize = 0;
        for (res.record_kinds) |k| {
            switch (k) {
                .declared_variable => declared_variables.add(identifiers, res.buffer[i]),
                .lexical_variable => lexical_variables.add(identifiers, res.buffer[i]),
                .import_info_single, .import_info_namespace, .export_info_indirect, .export_info_local, .export_info_namespace, .export_info_star => {},
                else => return fail(failure_reason, 2),
            }
            i += k.len() catch return fail(failure_reason, 2);
        }
    }

    const module_record = JSModuleRecord.create(globalObject, vm, module_key, source_code, declared_variables, lexical_variables, res.contains_import_meta);

    for (res.requested_modules_keys, res.requested_modules_values) |reqk, reqv| {
        switch (reqv) {
            .none => module_record.addRequestedModuleNullAttributesPtr(identifiers, reqk),
            .javascript => module_record.addRequestedModuleJavaScript(identifiers, reqk),
            .webassembly => module_record.addRequestedModuleWebAssembly(identifiers, reqk),
            .json => module_record.addRequestedModuleJSON(identifiers, reqk),
            else => |uv| module_record.addRequestedModuleHostDefined(identifiers, reqk, @enumFromInt(@intFromEnum(uv))),
        }
    }

    {
        var i: usize = 0;
        for (res.record_kinds) |k| {
            switch (k) {
                .declared_variable, .lexical_variable => {},
                .import_info_single => module_record.addImportEntrySingle(identifiers, res.buffer[i + 1], res.buffer[i + 2], res.buffer[i]),
                .import_info_namespace => module_record.addImportEntryNamespace(identifiers, res.buffer[i + 1], res.buffer[i + 2], res.buffer[i]),
                .export_info_indirect => module_record.addIndirectExport(identifiers, res.buffer[i + 1], res.buffer[i + 2], res.buffer[i]),
                .export_info_local => module_record.addLocalExport(identifiers, res.buffer[i], res.buffer[i + 1]),
                .export_info_namespace => module_record.addNamespaceExport(identifiers, res.buffer[i], res.buffer[i + 1]),
                .export_info_star => module_record.addStarExport(identifiers, res.buffer[i]),
                else => return fail(failure_reason, 2),
            }
            i += k.len() catch return fail(failure_reason, 2);
        }
    }

    return module_record;
}
export fn zig__ModuleInfo__destroy(info: *ModuleInfo) void {
    info.deinit();
    bun.default_allocator.destroy(info);
}

const VariableEnvironment = opaque {
    extern fn JSC__VariableEnvironment__add(environment: *VariableEnvironment, identifier_array: *IdentifierArray, identifier_index: StringID) void;
    pub const add = JSC__VariableEnvironment__add;
};
const IdentifierArray = opaque {
    extern fn JSC__IdentifierArray__create(len: usize) *IdentifierArray;
    pub const create = JSC__IdentifierArray__create;

    extern fn JSC__IdentifierArray__destroy(identifier_array: *IdentifierArray) void;
    pub const destroy = JSC__IdentifierArray__destroy;

    extern fn JSC__IdentifierArray__setFromUtf8(identifier_array: *IdentifierArray, n: usize, vm: *bun.JSC.VM, str: [*]const u8, len: usize) void;
    pub fn setFromUtf8(self: *IdentifierArray, n: usize, vm: *bun.JSC.VM, str: []const u8) void {
        JSC__IdentifierArray__setFromUtf8(self, n, vm, str.ptr, str.len);
    }

    extern fn JSC__IdentifierArray__setFromStarDefault(identifier_array: *IdentifierArray, n: usize, vm: *bun.JSC.VM) void;
    pub const setFromStarDefault = JSC__IdentifierArray__setFromStarDefault;
};
const SourceCode = opaque {};
const JSModuleRecord = opaque {
    extern fn JSC_JSModuleRecord__create(global_object: *bun.JSC.JSGlobalObject, vm: *bun.JSC.VM, module_key: *const IdentifierArray, source_code: *const SourceCode, declared_variables: *VariableEnvironment, lexical_variables: *VariableEnvironment, has_import_meta: bool) *JSModuleRecord;
    pub const create = JSC_JSModuleRecord__create;

    extern fn JSC_JSModuleRecord__declaredVariables(module_record: *JSModuleRecord) *VariableEnvironment;
    pub const declaredVariables = JSC_JSModuleRecord__declaredVariables;
    extern fn JSC_JSModuleRecord__lexicalVariables(module_record: *JSModuleRecord) *VariableEnvironment;
    pub const lexicalVariables = JSC_JSModuleRecord__lexicalVariables;

    extern fn JSC_JSModuleRecord__addIndirectExport(module_record: *JSModuleRecord, identifier_array: *IdentifierArray, export_name: StringID, import_name: StringID, module_name: StringID) void;
    pub const addIndirectExport = JSC_JSModuleRecord__addIndirectExport;
    extern fn JSC_JSModuleRecord__addLocalExport(module_record: *JSModuleRecord, identifier_array: *IdentifierArray, export_name: StringID, local_name: StringID) void;
    pub const addLocalExport = JSC_JSModuleRecord__addLocalExport;
    extern fn JSC_JSModuleRecord__addNamespaceExport(module_record: *JSModuleRecord, identifier_array: *IdentifierArray, export_name: StringID, module_name: StringID) void;
    pub const addNamespaceExport = JSC_JSModuleRecord__addNamespaceExport;
    extern fn JSC_JSModuleRecord__addStarExport(module_record: *JSModuleRecord, identifier_array: *IdentifierArray, module_name: StringID) void;
    pub const addStarExport = JSC_JSModuleRecord__addStarExport;

    extern fn JSC_JSModuleRecord__addRequestedModuleNullAttributesPtr(module_record: *JSModuleRecord, identifier_array: *IdentifierArray, module_name: StringID) void;
    pub const addRequestedModuleNullAttributesPtr = JSC_JSModuleRecord__addRequestedModuleNullAttributesPtr;
    extern fn JSC_JSModuleRecord__addRequestedModuleJavaScript(module_record: *JSModuleRecord, identifier_array: *IdentifierArray, module_name: StringID) void;
    pub const addRequestedModuleJavaScript = JSC_JSModuleRecord__addRequestedModuleJavaScript;
    extern fn JSC_JSModuleRecord__addRequestedModuleWebAssembly(module_record: *JSModuleRecord, identifier_array: *IdentifierArray, module_name: StringID) void;
    pub const addRequestedModuleWebAssembly = JSC_JSModuleRecord__addRequestedModuleWebAssembly;
    extern fn JSC_JSModuleRecord__addRequestedModuleJSON(module_record: *JSModuleRecord, identifier_array: *IdentifierArray, module_name: StringID) void;
    pub const addRequestedModuleJSON = JSC_JSModuleRecord__addRequestedModuleJSON;
    extern fn JSC_JSModuleRecord__addRequestedModuleHostDefined(module_record: *JSModuleRecord, identifier_array: *IdentifierArray, module_name: StringID, host_defined_import_type: StringID) void;
    pub const addRequestedModuleHostDefined = JSC_JSModuleRecord__addRequestedModuleHostDefined;

    extern fn JSC_JSModuleRecord__addImportEntrySingle(module_record: *JSModuleRecord, identifier_array: *IdentifierArray, import_name: StringID, local_name: StringID, module_name: StringID) void;
    pub const addImportEntrySingle = JSC_JSModuleRecord__addImportEntrySingle;
    extern fn JSC_JSModuleRecord__addImportEntryNamespace(module_record: *JSModuleRecord, identifier_array: *IdentifierArray, import_name: StringID, local_name: StringID, module_name: StringID) void;
    pub const addImportEntryNamespace = JSC_JSModuleRecord__addImportEntryNamespace;
};
