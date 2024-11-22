const bun = @import("root").bun;
const JSC = bun.JSC;

pub const Classes = struct {
    pub const Blob = JSC.WebCore.Blob;
    pub const HTMLRewriter = JSC.Cloudflare.HTMLRewriter;
    pub const Element = JSC.Cloudflare.Element;
    pub const Comment = JSC.Cloudflare.Comment;
    pub const TextChunk = JSC.Cloudflare.TextChunk;
    pub const DocType = JSC.Cloudflare.DocType;
    pub const DocEnd = JSC.Cloudflare.DocEnd;
    pub const EndTag = JSC.Cloudflare.EndTag;
    pub const AttributeIterator = JSC.Cloudflare.AttributeIterator;
    pub const CryptoHasher = JSC.API.Bun.Crypto.CryptoHasher;
    pub const Dirent = JSC.Node.Dirent;
    pub const Expect = JSC.Expect.Expect;
    pub const ExpectAny = JSC.Expect.ExpectAny;
    pub const ExpectAnything = JSC.Expect.ExpectAnything;
    pub const ExpectCustomAsymmetricMatcher = JSC.Expect.ExpectCustomAsymmetricMatcher;
    pub const ExpectMatcherContext = JSC.Expect.ExpectMatcherContext;
    pub const ExpectMatcherUtils = JSC.Expect.ExpectMatcherUtils;
    pub const ExpectStatic = JSC.Expect.ExpectStatic;
    pub const ExpectCloseTo = JSC.Expect.ExpectCloseTo;
    pub const ExpectObjectContaining = JSC.Expect.ExpectObjectContaining;
    pub const ExpectStringContaining = JSC.Expect.ExpectStringContaining;
    pub const ExpectStringMatching = JSC.Expect.ExpectStringMatching;
    pub const ExpectArrayContaining = JSC.Expect.ExpectArrayContaining;
    pub const FileSystemRouter = JSC.API.FileSystemRouter;
    pub const Glob = JSC.API.Glob;
    pub const ShellInterpreter = JSC.API.Shell.Interpreter;
    pub const ParsedShellScript = JSC.API.Shell.ParsedShellScript;
    pub const Bundler = JSC.API.JSBundler;
    pub const JSBundler = Bundler;
    pub const Transpiler = JSC.API.JSTranspiler;
    pub const JSTranspiler = Transpiler;
    pub const Listener = JSC.API.Listener;
    pub const MatchedRoute = JSC.API.MatchedRoute;
    pub const NodeJSFS = JSC.Node.NodeJSFS;
    pub const Request = JSC.WebCore.Request;
    pub const Response = JSC.WebCore.Response;
    pub const MD4 = JSC.API.Bun.Crypto.MD4;
    pub const MD5 = JSC.API.Bun.Crypto.MD5;
    pub const SHA1 = JSC.API.Bun.Crypto.SHA1;
    pub const SHA224 = JSC.API.Bun.Crypto.SHA224;
    pub const SHA256 = JSC.API.Bun.Crypto.SHA256;
    pub const SHA384 = JSC.API.Bun.Crypto.SHA384;
    pub const SHA512 = JSC.API.Bun.Crypto.SHA512;
    pub const SHA512_256 = JSC.API.Bun.Crypto.SHA512_256;
    pub const ServerWebSocket = JSC.API.ServerWebSocket;
    pub const Stats = JSC.Node.StatsSmall;
    pub const BigIntStats = JSC.Node.StatsBig;
    pub const Subprocess = JSC.Subprocess;
    pub const ResourceUsage = JSC.ResourceUsage;
    pub const TCPSocket = JSC.API.TCPSocket;
    pub const TLSSocket = JSC.API.TLSSocket;
    pub const UDPSocket = JSC.API.UDPSocket;
    pub const TextDecoder = JSC.WebCore.TextDecoder;
    pub const Timeout = JSC.API.Bun.Timer.TimerObject;
    pub const BuildArtifact = JSC.API.BuildArtifact;
    pub const BuildMessage = JSC.BuildMessage;
    pub const ResolveMessage = JSC.ResolveMessage;
    pub const FSWatcher = JSC.Node.FSWatcher;
    pub const StatWatcher = JSC.Node.StatWatcher;
    pub const HTTPServer = JSC.API.HTTPServer;
    pub const HTTPSServer = JSC.API.HTTPSServer;
    pub const DebugHTTPServer = JSC.API.DebugHTTPServer;
    pub const DebugHTTPSServer = JSC.API.DebugHTTPSServer;
    pub const Crypto = JSC.WebCore.Crypto;
    pub const FFI = JSC.FFI;
    pub const H2FrameParser = JSC.API.H2FrameParser;
    pub const FileInternalReadableStreamSource = JSC.WebCore.FileReader.Source;
    pub const BlobInternalReadableStreamSource = JSC.WebCore.ByteBlobLoader.Source;
    pub const BytesInternalReadableStreamSource = JSC.WebCore.ByteStream.Source;
    pub const PostgresSQLConnection = JSC.Postgres.PostgresSQLConnection;
    pub const PostgresSQLQuery = JSC.Postgres.PostgresSQLQuery;
    pub const TextEncoderStreamEncoder = JSC.WebCore.TextEncoderStreamEncoder;
    pub const NativeZlib = JSC.API.NativeZlib;
    pub const NativeBrotli = JSC.API.NativeBrotli;
    pub const FrameworkFileSystemRouter = bun.bake.FrameworkRouter.JSFrameworkRouter;
};
