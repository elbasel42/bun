const JSC = @import("root").bun.JSC;

pub const Classes = struct {
    pub const Blob = JSC.WebCore.Blob;
    pub const CryptoHasher = JSC.API.Bun.Crypto.CryptoHasher;
    pub const Dirent = JSC.Node.Dirent;
    pub const Expect = JSC.Expect.Expect;
    pub const ExpectAny = JSC.Expect.ExpectAny;
    pub const ExpectAnything = JSC.Expect.ExpectAnything;
    pub const ExpectStringContaining = JSC.Expect.ExpectStringContaining;
    pub const ExpectStringMatching = JSC.Expect.ExpectStringMatching;
    pub const FileSystemRouter = JSC.API.FileSystemRouter;
    pub const Bundler = JSC.API.JSBundler;
    pub const JSBundler = Bundler;
    pub const Transpiler = JSC.API.JSTranspiler;
    pub const JSTranspiler = Transpiler;
    pub const Listener = JSC.API.Listener;
    pub const MD4 = JSC.API.Bun.Crypto.MD4;
    pub const MD5 = JSC.API.Bun.Crypto.MD5;
    pub const MatchedRoute = JSC.API.MatchedRoute;
    pub const NodeJSFS = JSC.Node.NodeJSFS;
    pub const Request = JSC.WebCore.Request;
    pub const Response = JSC.WebCore.Response;
    pub const SHA1 = JSC.API.Bun.Crypto.SHA1;
    pub const SHA224 = JSC.API.Bun.Crypto.SHA224;
    pub const SHA256 = JSC.API.Bun.Crypto.SHA256;
    pub const SHA384 = JSC.API.Bun.Crypto.SHA384;
    pub const SHA512 = JSC.API.Bun.Crypto.SHA512;
    pub const SHA512_256 = JSC.API.Bun.Crypto.SHA512_256;
    pub const ServerWebSocket = JSC.API.ServerWebSocket;
    pub const Stats = JSC.Node.Stats;
    pub const Subprocess = JSC.Subprocess;
    pub const TCPSocket = JSC.API.TCPSocket;
    pub const TLSSocket = JSC.API.TLSSocket;
    pub const TextDecoder = JSC.WebCore.TextDecoder;
    pub const Timeout = JSC.API.Bun.Timer.TimerObject;
    pub const BuildArtifact = JSC.API.BuildArtifact;
    pub const BuildMessage = JSC.BuildMessage;
    pub const ResolveMessage = JSC.ResolveMessage;
    pub const FSWatcher = JSC.Node.FSWatcher;
};
