

#include "root.h"

#include "ZigGlobalObject.h"
#include "JavaScriptCore/ExceptionHelpers.h"
#include "JavaScriptCore/JSString.h"
#include "JavaScriptCore/Error.h"
#include "JavaScriptCore/JSArrayBufferView.h"
#include "JavaScriptCore/JSCell.h"
#include "JavaScriptCore/JSGlobalObject.h"
#include "BufferEncodingType.h"
#include "JavaScriptCore/JSCJSValue.h"

#include "JSBuffer.h"

#include "JavaScriptCore/ArgList.h"
#include "JavaScriptCore/ExceptionScope.h"

#include "ActiveDOMObject.h"
#include "ExtendedDOMClientIsoSubspaces.h"
#include "ExtendedDOMIsoSubspaces.h"
#include "IDLTypes.h"
// #include "JSBlob.h"
#include "JSDOMAttribute.h"
#include "JSDOMBinding.h"
#include "JSDOMConstructor.h"
#include "JSDOMConvertBase.h"
#include "JSDOMConvertInterface.h"
#include "JSDOMConvertStrings.h"
#include "JSDOMExceptionHandling.h"
#include "JSDOMGlobalObject.h"
#include "JSDOMGlobalObjectInlines.h"
#include "JSDOMOperation.h"
#include "JSDOMWrapperCache.h"
#include "ScriptExecutionContext.h"
#include "WebCoreJSClientData.h"
#include <JavaScriptCore/FunctionPrototype.h>
#include <JavaScriptCore/HeapAnalyzer.h>

#include <JavaScriptCore/JSFunction.h>
#include <JavaScriptCore/InternalFunction.h>
#include <JavaScriptCore/LazyClassStructure.h>
#include <JavaScriptCore/LazyClassStructureInlines.h>
#include <JavaScriptCore/FunctionPrototype.h>

#include <JavaScriptCore/JSDestructibleObjectHeapCellType.h>
#include <JavaScriptCore/SlotVisitorMacros.h>
#include <JavaScriptCore/SubspaceInlines.h>
#include <wtf/GetPtr.h>
#include <wtf/PointerPreparations.h>
#include <wtf/URL.h>
#include <wtf/text/WTFString.h>
#include <JavaScriptCore/BuiltinNames.h>

#include "JSBufferEncodingType.h"
#include "ErrorCode.h"
#include "NodeValidator.h"
#include "wtf/Assertions.h"
#include "wtf/Forward.h"
#include <JavaScriptCore/JSBase.h>
#if ENABLE(MEDIA_SOURCE)
#include "BufferMediaSource.h"
#include "JSMediaSource.h"
#endif

#if OS(WINDOWS)
#include <windows.h>
#endif

#include <JavaScriptCore/DOMJITAbstractHeap.h>
#include "DOMJITIDLConvert.h"
#include "DOMJITIDLType.h"
#include "DOMJITIDLTypeFilter.h"
#include "DOMJITHelpers.h"
#include <JavaScriptCore/DFGAbstractHeap.h>

// #include <JavaScriptCore/JSTypedArrayViewPrototype.h>
#include <JavaScriptCore/JSArrayBufferViewInlines.h>

extern "C" bool Bun__Node__ZeroFillBuffers;

// export fn Bun__inspect_singleline(globalThis: *JSGlobalObject, value: JSValue) bun.String
extern "C" BunString Bun__inspect_singleline(JSC::JSGlobalObject* globalObject, JSC::JSValue value);

using namespace JSC;
using namespace WebCore;

JSC_DECLARE_HOST_FUNCTION(constructJSBuffer);
JSC_DECLARE_HOST_FUNCTION(callJSBuffer);

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-function"
static JSC_DECLARE_HOST_FUNCTION(jsBufferConstructorFunction_alloc);
static JSC_DECLARE_HOST_FUNCTION(jsBufferConstructorFunction_allocUnsafe);
static JSC_DECLARE_HOST_FUNCTION(jsBufferConstructorFunction_allocUnsafeSlow);
static JSC_DECLARE_HOST_FUNCTION(jsBufferConstructorFunction_byteLength);
static JSC_DECLARE_HOST_FUNCTION(jsBufferConstructorFunction_compare);
static JSC_DECLARE_HOST_FUNCTION(jsBufferConstructorFunction_concat);
static JSC_DECLARE_HOST_FUNCTION(jsBufferConstructorFunction_copyBytesFrom);
static JSC_DECLARE_HOST_FUNCTION(jsBufferConstructorFunction_from);
static JSC_DECLARE_HOST_FUNCTION(jsBufferConstructorFunction_isBuffer);
static JSC_DECLARE_HOST_FUNCTION(jsBufferConstructorFunction_isEncoding);

static JSC_DECLARE_HOST_FUNCTION(jsBufferPrototypeFunction_compare);
static JSC_DECLARE_HOST_FUNCTION(jsBufferPrototypeFunction_copy);
static JSC_DECLARE_HOST_FUNCTION(jsBufferPrototypeFunction_equals);
static JSC_DECLARE_HOST_FUNCTION(jsBufferPrototypeFunction_fill);
static JSC_DECLARE_HOST_FUNCTION(jsBufferPrototypeFunction_includes);
static JSC_DECLARE_HOST_FUNCTION(jsBufferPrototypeFunction_indexOf);
static JSC_DECLARE_HOST_FUNCTION(jsBufferPrototypeFunction_inspect);
static JSC_DECLARE_HOST_FUNCTION(jsBufferPrototypeFunction_lastIndexOf);
static JSC_DECLARE_HOST_FUNCTION(jsBufferPrototypeFunction_swap16);
static JSC_DECLARE_HOST_FUNCTION(jsBufferPrototypeFunction_swap32);
static JSC_DECLARE_HOST_FUNCTION(jsBufferPrototypeFunction_swap64);
static JSC_DECLARE_HOST_FUNCTION(jsBufferPrototypeFunction_toString);
static JSC_DECLARE_HOST_FUNCTION(jsBufferPrototypeFunction_write);
#pragma clang diagnostic pop

extern "C" EncodedJSValue WebCore_BufferEncodingType_toJS(JSC::JSGlobalObject* lexicalGlobalObject, WebCore::BufferEncodingType encoding)
{
    // clang-format off
    auto* globalObject = defaultGlobalObject(lexicalGlobalObject);
    switch (encoding) {
    case WebCore::BufferEncodingType::utf8:      return JSC::JSValue::encode(globalObject->commonStrings().utf8String(globalObject));
    case WebCore::BufferEncodingType::ucs2:      return JSC::JSValue::encode(globalObject->commonStrings().ucs2String(globalObject));
    case WebCore::BufferEncodingType::utf16le:   return JSC::JSValue::encode(globalObject->commonStrings().utf16leString(globalObject));
    case WebCore::BufferEncodingType::latin1:    return JSC::JSValue::encode(globalObject->commonStrings().latin1String(globalObject));
    case WebCore::BufferEncodingType::ascii:     return JSC::JSValue::encode(globalObject->commonStrings().asciiString(globalObject));
    case WebCore::BufferEncodingType::base64:    return JSC::JSValue::encode(globalObject->commonStrings().base64String(globalObject));
    case WebCore::BufferEncodingType::base64url: return JSC::JSValue::encode(globalObject->commonStrings().base64urlString(globalObject));
    case WebCore::BufferEncodingType::hex:       return JSC::JSValue::encode(globalObject->commonStrings().hexString(globalObject));
    case WebCore::BufferEncodingType::buffer:    return JSC::JSValue::encode(globalObject->commonStrings().bufferString(globalObject));
    }
    // clang-format on
}

namespace Bun {

// Use a JSString* here to avoid unnecessarily joining the rope string.
// If we're only getting the length property, it won't join the rope string.
std::optional<double> byteLength(JSC::JSString* str, JSC::JSGlobalObject* lexicalGlobalObject, WebCore::BufferEncodingType encoding)
{
    if (str->length() == 0)
        return 0;

    switch (encoding) {

    case WebCore::BufferEncodingType::ucs2:
    case WebCore::BufferEncodingType::utf16le: {
        // https://github.com/nodejs/node/blob/e676942f814915b2d24fc899bb42dc71ae6c8226/lib/buffer.js#L600
        return str->length() * 2;
    }

    case WebCore::BufferEncodingType::latin1:
    case WebCore::BufferEncodingType::ascii: {
        // https://github.com/nodejs/node/blob/e676942f814915b2d24fc899bb42dc71ae6c8226/lib/buffer.js#L627
        return str->length();
    }

    case WebCore::BufferEncodingType::base64:
    case WebCore::BufferEncodingType::base64url: {
        int64_t length = str->length();
        const auto view = str->view(lexicalGlobalObject);
        if (UNLIKELY(view->isNull())) {
            return std::nullopt;
        }

        if (view->is8Bit()) {
            const auto span = view->span8();
            if (span.data()[length - 1] == 0x3D) {
                length--;

                if (length > 1 && span.data()[length - 1] == '=')
                    length--;
            }
        } else {
            const auto span = view->span16();
            if (span.data()[length - 1] == 0x3D) {
                length--;

                if (length > 1 && span.data()[length - 1] == '=')
                    length--;
            }
        }

        // https://github.com/nodejs/node/blob/e676942f814915b2d24fc899bb42dc71ae6c8226/lib/buffer.js#L579
        return static_cast<double>((length * 3) >> 2);
    }

    case WebCore::BufferEncodingType::hex: {
        return str->length() >> 1;
    }

    case WebCore::BufferEncodingType::utf8: {
        const auto view = str->view(lexicalGlobalObject);
        if (UNLIKELY(view->isNull())) {
            return std::nullopt;
        }

        if (view->is8Bit()) {
            const auto span = view->span8();
            return Bun__encoding__byteLengthLatin1(span.data(), span.size(), static_cast<uint8_t>(encoding));
        } else {
            const auto span = view->span16();
            return Bun__encoding__byteLengthUTF16(span.data(), span.size(), static_cast<uint8_t>(encoding));
        }
    }
    default: {
        RELEASE_ASSERT_NOT_REACHED();
    }
    }

    return std::nullopt;
}
}

static JSUint8Array* allocBuffer(JSC::JSGlobalObject* lexicalGlobalObject, size_t byteLength)
{
#if ASSERT_ENABLED
    auto& vm = JSC::getVM(lexicalGlobalObject);
    auto throwScope = DECLARE_THROW_SCOPE(vm);
#endif

    auto* globalObject = defaultGlobalObject(lexicalGlobalObject);
    auto* subclassStructure = globalObject->JSBufferSubclassStructure();

    auto* uint8Array = JSC::JSUint8Array::create(lexicalGlobalObject, subclassStructure, byteLength);
#if ASSERT_ENABLED
    if (UNLIKELY(!uint8Array)) {
        // it should have thrown an exception already
        ASSERT(throwScope.exception());
    }
#endif

    return uint8Array;
}

static JSUint8Array* allocBufferUnsafe(JSC::JSGlobalObject* lexicalGlobalObject, size_t byteLength)
{

#if ASSERT_ENABLED
    auto& vm = JSC::getVM(lexicalGlobalObject);
    auto throwScope = DECLARE_THROW_SCOPE(vm);
#endif

    auto* result = createUninitializedBuffer(lexicalGlobalObject, byteLength);

#if ASSERT_ENABLED
    if (UNLIKELY(!result)) {
        // it should have thrown an exception already
        ASSERT(throwScope.exception());
    }
#endif

    return result;
}

// Normalize val to be an integer in the range of [1, -1] since
// implementations of memcmp() can vary by platform.
static int normalizeCompareVal(int val, size_t a_length, size_t b_length)
{
    if (val == 0) {
        if (a_length > b_length)
            return 1;
        else if (a_length < b_length)
            return -1;
    } else {
        if (val > 0)
            return 1;
        else
            return -1;
    }
    return val;
}

static inline WebCore::BufferEncodingType parseEncoding(JSC::JSGlobalObject* lexicalGlobalObject, JSC::ThrowScope& scope, JSValue arg)
{
    auto arg_ = arg.toStringOrNull(lexicalGlobalObject);
    RETURN_IF_EXCEPTION(scope, {});
    const auto& view = arg_->view(lexicalGlobalObject);

    std::optional<BufferEncodingType> encoded = parseEnumeration2(*lexicalGlobalObject, view);
    if (UNLIKELY(!encoded)) {
        Bun::ERR::UNKNOWN_ENCODING(scope, lexicalGlobalObject, view);
        return WebCore::BufferEncodingType::utf8;
    }

    return encoded.value();
}

namespace WebCore {
using namespace JSC;

template<> class IDLOperation<JSArrayBufferView> {
public:
    using ClassParameter = JSC::JSUint8Array*;
    using Operation = JSC::EncodedJSValue(JSC::JSGlobalObject*, JSC::CallFrame*, ClassParameter);

    template<Operation operation, CastedThisErrorBehavior = CastedThisErrorBehavior::Throw>
    static JSC::EncodedJSValue call(JSC::JSGlobalObject& lexicalGlobalObject, JSC::CallFrame& callFrame, const char* operationName)
    {
        auto& vm = JSC::getVM(&lexicalGlobalObject);
        auto throwScope = DECLARE_THROW_SCOPE(vm);

        auto thisValue = callFrame.thisValue().toThis(&lexicalGlobalObject, JSC::ECMAMode::strict());
        if (thisValue.isUndefinedOrNull()) {
            throwTypeError(&lexicalGlobalObject, throwScope, "Cannot convert undefined or null to object"_s);
            return JSC::JSValue::encode(JSC::jsUndefined());
        }

        auto thisObject = JSC::jsDynamicCast<JSC::JSUint8Array*>(thisValue);
        if (UNLIKELY(!thisObject))
            return throwThisTypeError(lexicalGlobalObject, throwScope, "Buffer", operationName);

        RELEASE_AND_RETURN(throwScope, (operation(&lexicalGlobalObject, &callFrame, thisObject)));
    }
};

}

JSC::EncodedJSValue JSBuffer__bufferFromPointerAndLengthAndDeinit(JSC::JSGlobalObject* lexicalGlobalObject, char* ptr, size_t length, void* ctx, JSTypedArrayBytesDeallocator bytesDeallocator)
{

    JSC::JSUint8Array* uint8Array = nullptr;

    auto* globalObject = defaultGlobalObject(lexicalGlobalObject);
    auto* subclassStructure = globalObject->JSBufferSubclassStructure();

    if (LIKELY(length > 0)) {
        auto buffer = ArrayBuffer::createFromBytes({ reinterpret_cast<const uint8_t*>(ptr), length }, createSharedTask<void(void*)>([ctx, bytesDeallocator](void* p) {
            if (bytesDeallocator)
                bytesDeallocator(p, ctx);
        }));

        uint8Array = JSC::JSUint8Array::create(lexicalGlobalObject, subclassStructure, WTFMove(buffer), 0, length);
    } else {
        uint8Array = JSC::JSUint8Array::create(lexicalGlobalObject, subclassStructure, 0);
    }

    return JSC::JSValue::encode(uint8Array);
}

namespace WebCore {
using namespace JSC;

static inline JSC::EncodedJSValue writeToBuffer(JSC::JSGlobalObject* lexicalGlobalObject, JSArrayBufferView* castedThis, JSString* str, uint32_t offset, uint32_t length, BufferEncodingType encoding)
{
    if (UNLIKELY(str->length() == 0))
        return JSC::JSValue::encode(JSC::jsNumber(0));

    const auto& view = str->view(lexicalGlobalObject);
    if (view->isNull()) {
        return {};
    }

    size_t written = 0;

    switch (encoding) {
    case WebCore::BufferEncodingType::utf8:
    case WebCore::BufferEncodingType::latin1:
    case WebCore::BufferEncodingType::ascii:
    case WebCore::BufferEncodingType::ucs2:
    case WebCore::BufferEncodingType::utf16le:
    case WebCore::BufferEncodingType::base64:
    case WebCore::BufferEncodingType::base64url:
    case WebCore::BufferEncodingType::hex: {

        if (view->is8Bit()) {
            const auto span = view->span8();
            written = Bun__encoding__writeLatin1(span.data(), span.size(), reinterpret_cast<unsigned char*>(castedThis->vector()) + offset, length, static_cast<uint8_t>(encoding));
        } else {
            const auto span = view->span16();
            written = Bun__encoding__writeUTF16(span.data(), span.size(), reinterpret_cast<unsigned char*>(castedThis->vector()) + offset, length, static_cast<uint8_t>(encoding));
        }
        break;
    }
    default: {
        break;
    }
    }

    return JSC::JSValue::encode(JSC::jsNumber(written));
}

JSC::JSUint8Array* createBuffer(JSC::JSGlobalObject* lexicalGlobalObject, Ref<JSC::ArrayBuffer>&& backingStore)
{
    size_t length = backingStore->byteLength();
    return JSC::JSUint8Array::create(lexicalGlobalObject, defaultGlobalObject(lexicalGlobalObject)->JSBufferSubclassStructure(), WTFMove(backingStore), 0, length);
}

JSC::JSUint8Array* createBuffer(JSC::JSGlobalObject* lexicalGlobalObject, const uint8_t* ptr, size_t length)
{
    auto* buffer = createUninitializedBuffer(lexicalGlobalObject, length);

    if (LIKELY(ptr && length > 0 && buffer))
        memcpy(buffer->typedVector(), ptr, length);

    return buffer;
}

JSC::JSUint8Array* createBuffer(JSC::JSGlobalObject* lexicalGlobalObject, const std::span<const uint8_t> data)
{
    return createBuffer(lexicalGlobalObject, data.data(), data.size());
}

JSC::JSUint8Array* createBuffer(JSC::JSGlobalObject* lexicalGlobalObject, const char* ptr, size_t length)
{
    return createBuffer(lexicalGlobalObject, reinterpret_cast<const uint8_t*>(ptr), length);
}

JSC::JSUint8Array* createBuffer(JSC::JSGlobalObject* lexicalGlobalObject, const Vector<uint8_t>& data)
{
    return createBuffer(lexicalGlobalObject, data.data(), data.size());
}

JSC::JSUint8Array* createEmptyBuffer(JSC::JSGlobalObject* lexicalGlobalObject)
{
    return createUninitializedBuffer(lexicalGlobalObject, 0);
}

JSC::JSUint8Array* createUninitializedBuffer(JSC::JSGlobalObject* lexicalGlobalObject, size_t length)
{
    auto* globalObject = defaultGlobalObject(lexicalGlobalObject);
    auto* subclassStructure = globalObject->JSBufferSubclassStructure();

    return JSC::JSUint8Array::createUninitialized(lexicalGlobalObject, subclassStructure, length);
}

static inline JSC::JSUint8Array* JSBuffer__bufferFromLengthAsArray(JSC::JSGlobalObject* lexicalGlobalObject, int64_t length)
{
    auto throwScope = DECLARE_THROW_SCOPE(lexicalGlobalObject->vm());

    if (UNLIKELY(length < 0)) {
        throwNodeRangeError(lexicalGlobalObject, throwScope, "Invalid array length"_s);
        return nullptr;
    }
    if (length > MAX_ARRAY_BUFFER_SIZE) {
        Bun::ERR::OUT_OF_RANGE(throwScope, lexicalGlobalObject, "size"_s, 0, MAX_ARRAY_BUFFER_SIZE, jsNumber(length));
        return nullptr;
    }

    auto* globalObject = defaultGlobalObject(lexicalGlobalObject);
    auto* subclassStructure = globalObject->JSBufferSubclassStructure();
    JSC::JSUint8Array* uint8Array = JSC::JSUint8Array::create(lexicalGlobalObject, subclassStructure, static_cast<size_t>(length));

    RELEASE_AND_RETURN(throwScope, uint8Array);
}

extern "C" JSC::EncodedJSValue JSBuffer__bufferFromLength(JSC::JSGlobalObject* lexicalGlobalObject, int64_t length)
{
    return JSC::JSValue::encode(JSBuffer__bufferFromLengthAsArray(lexicalGlobalObject, length));
}

// https://github.com/nodejs/node/blob/v22.9.0/lib/buffer.js#L404
static inline JSC::EncodedJSValue jsBufferConstructorFunction_allocUnsafeBody(JSC::JSGlobalObject* lexicalGlobalObject, JSC::CallFrame* callFrame)
{
    auto& vm = JSC::getVM(lexicalGlobalObject);
    auto throwScope = DECLARE_THROW_SCOPE(vm);
    JSValue lengthValue = callFrame->argument(0);
    Bun::V::validateNumber(throwScope, lexicalGlobalObject, lengthValue, "size"_s, jsNumber(0), jsNumber(Bun::Buffer::kMaxLength));
    RETURN_IF_EXCEPTION(throwScope, {});
    size_t length = lengthValue.toLength(lexicalGlobalObject);
    auto result = allocBufferUnsafe(lexicalGlobalObject, length);
    RETURN_IF_EXCEPTION(throwScope, {});
    if (Bun__Node__ZeroFillBuffers) memset(result->typedVector(), 0, length);
    RELEASE_AND_RETURN(throwScope, JSValue::encode(result));
}

// new Buffer()
static inline JSC::EncodedJSValue constructBufferEmpty(JSGlobalObject* lexicalGlobalObject)
{
    return JSBuffer__bufferFromLength(lexicalGlobalObject, 0);
}

static JSC::EncodedJSValue constructFromEncoding(JSGlobalObject* lexicalGlobalObject, JSString* str, WebCore::BufferEncodingType encoding)
{
    auto& vm = JSC::getVM(lexicalGlobalObject);
    auto scope = DECLARE_THROW_SCOPE(vm);

    // Use ->view() here instead of ->value() as that will avoid flattening ropestrings from .slice()
    const auto& view = str->view(lexicalGlobalObject);
    RETURN_IF_EXCEPTION(scope, {});
    JSC::EncodedJSValue result;

    if (view->is8Bit()) {
        const auto span = view->span8();

        switch (encoding) {
        case WebCore::BufferEncodingType::utf8:
        case WebCore::BufferEncodingType::ucs2:
        case WebCore::BufferEncodingType::utf16le:
        case WebCore::BufferEncodingType::base64:
        case WebCore::BufferEncodingType::base64url:
        case WebCore::BufferEncodingType::hex: {

            result = Bun__encoding__constructFromLatin1(lexicalGlobalObject, span.data(), span.size(), static_cast<uint8_t>(encoding));
            break;
        }
        case WebCore::BufferEncodingType::ascii: // ascii is a noop for latin1
        case WebCore::BufferEncodingType::latin1: { // The native encoding is latin1, so we don't need to do any conversion.
            result = JSValue::encode(createBuffer(lexicalGlobalObject, span.data(), span.size()));
            break;
        }
        default: {
            result = 0;
            break;
        }
        }
    } else {
        const auto span = view->span16();
        switch (encoding) {
        case WebCore::BufferEncodingType::utf8:
        case WebCore::BufferEncodingType::base64:
        case WebCore::BufferEncodingType::base64url:
        case WebCore::BufferEncodingType::hex:
        case WebCore::BufferEncodingType::ascii:
        case WebCore::BufferEncodingType::latin1: {
            result = Bun__encoding__constructFromUTF16(lexicalGlobalObject, span.data(), span.size(), static_cast<uint8_t>(encoding));
            break;
        }
        case WebCore::BufferEncodingType::ucs2:
        case WebCore::BufferEncodingType::utf16le: {
            // The native encoding is UTF-16
            // so we don't need to do any conversion.
            result = JSValue::encode(createBuffer(lexicalGlobalObject, reinterpret_cast<const unsigned char*>(span.data()), span.size() * 2));
            break;
        }
        default: {
            result = 0;
            break;
        }
        }
    }

    JSC::JSValue decoded = JSC::JSValue::decode(result);
    if (UNLIKELY(!result)) {
        throwTypeError(lexicalGlobalObject, scope, "An error occurred while decoding the string"_s);
        return {};
    }

    if (decoded.isCell() && decoded.getObject()->isErrorInstance()) {
        scope.throwException(lexicalGlobalObject, decoded);
        return {};
    }
    return result;
}

static inline JSC::EncodedJSValue constructBufferFromStringAndEncoding(JSC::JSGlobalObject* lexicalGlobalObject, JSValue arg0, JSValue arg1)
{
    auto& vm = JSC::getVM(lexicalGlobalObject);
    auto scope = DECLARE_THROW_SCOPE(vm);

    WebCore::BufferEncodingType encoding = WebCore::BufferEncodingType::utf8;

    auto* str = arg0.toString(lexicalGlobalObject);
    RETURN_IF_EXCEPTION(scope, {});

    if (arg1 && arg1.isString()) {
        std::optional<BufferEncodingType> encoded = parseEnumeration<BufferEncodingType>(*lexicalGlobalObject, arg1);
        if (!encoded) {
            auto* encodingString = arg1.toString(lexicalGlobalObject);
            RETURN_IF_EXCEPTION(scope, {});
            const auto& view = encodingString->view(lexicalGlobalObject);
            return Bun::ERR::UNKNOWN_ENCODING(scope, lexicalGlobalObject, view);
        }

        encoding = encoded.value();
    }

    if (str->length() == 0)
        return constructBufferEmpty(lexicalGlobalObject);

    JSC::EncodedJSValue result = constructFromEncoding(lexicalGlobalObject, str, encoding);

    RELEASE_AND_RETURN(scope, result);
}

// https://github.com/nodejs/node/blob/v22.9.0/lib/buffer.js#L391
static inline JSC::EncodedJSValue jsBufferConstructorFunction_allocBody(JSC::JSGlobalObject* lexicalGlobalObject, JSC::CallFrame* callFrame)
{
    auto& vm = JSC::getVM(lexicalGlobalObject);
    auto scope = DECLARE_THROW_SCOPE(vm);

    JSValue lengthValue = callFrame->argument(0);
    Bun::V::validateNumber(scope, lexicalGlobalObject, lengthValue, "size"_s, jsNumber(0), jsNumber(Bun::Buffer::kMaxLength));
    RETURN_IF_EXCEPTION(scope, {});
    size_t length = lengthValue.toLength(lexicalGlobalObject);

    // fill argument
    if (UNLIKELY(callFrame->argumentCount() > 1)) {
        auto* uint8Array = createUninitializedBuffer(lexicalGlobalObject, length);
        RETURN_IF_EXCEPTION(scope, {});

        auto value = callFrame->argument(1);

        if (value.isString()) {
            size_t length = uint8Array->byteLength();
            size_t start = 0;
            size_t end = length;
            WebCore::BufferEncodingType encoding = WebCore::BufferEncodingType::utf8;
            if (callFrame->argumentCount() > 2) {
                EnsureStillAliveScope arg2 = callFrame->uncheckedArgument(2);
                if (!arg2.value().isUndefined()) {
                    encoding = parseEncoding(lexicalGlobalObject, scope, arg2.value());
                    RETURN_IF_EXCEPTION(scope, {});
                }
            }
            auto startPtr = uint8Array->typedVector() + start;
            auto str_ = value.toString(lexicalGlobalObject);
            RETURN_IF_EXCEPTION(scope, {});
            const auto& view = str_->view(lexicalGlobalObject);
            if (view->isEmpty()) {
                memset(startPtr, 0, length);
                RELEASE_AND_RETURN(scope, JSC::JSValue::encode(uint8Array));
            }

            ZigString str = Zig::toZigString(view);

            if (UNLIKELY(!Bun__Buffer_fill(&str, startPtr, end - start, encoding))) {
                throwTypeError(lexicalGlobalObject, scope, "Failed to decode value"_s);
                return {};
            }
        } else if (auto* view = JSC::jsDynamicCast<JSC::JSArrayBufferView*>(value)) {
            if (UNLIKELY(view->isDetached())) {
                throwVMTypeError(lexicalGlobalObject, scope, "Uint8Array is detached"_s);
                return {};
            }

            size_t length = view->byteLength();
            if (UNLIKELY(length == 0)) {
                throwTypeError(lexicalGlobalObject, scope, "Buffer cannot be empty"_s);
                return {};
            }

            auto* start = uint8Array->typedVector();
            auto* head = start;
            size_t remain = uint8Array->byteLength();
            length = std::min(length, remain);

            memmove(head, view->vector(), length);
            remain -= length;
            head += length;
            while (remain >= length && length > 0) {
                memmove(head, start, length);
                remain -= length;
                head += length;
                length <<= 1;
            }
            if (remain > 0) {
                memmove(head, start, remain);
            }
        } else {
            auto value_ = value.toInt32(lexicalGlobalObject) & 0xFF;

            auto value_uint8 = static_cast<uint8_t>(value_);
            RETURN_IF_EXCEPTION(scope, {});

            auto length = uint8Array->byteLength();
            auto start = 0;
            auto end = length;

            auto startPtr = uint8Array->typedVector() + start;
            auto endPtr = uint8Array->typedVector() + end;
            memset(startPtr, value_uint8, endPtr - startPtr);
        }

        RELEASE_AND_RETURN(scope, JSC::JSValue::encode(uint8Array));
    } else {
        RELEASE_AND_RETURN(scope, JSValue::encode(allocBuffer(lexicalGlobalObject, length)));
    }
}

static inline JSC::EncodedJSValue jsBufferConstructorFunction_allocUnsafeSlowBody(JSC::JSGlobalObject* lexicalGlobalObject, JSC::CallFrame* callFrame)
{
    return jsBufferConstructorFunction_allocUnsafeBody(lexicalGlobalObject, callFrame);
}

// new SlowBuffer(size)
JSC_DEFINE_HOST_FUNCTION(constructSlowBuffer, (JSGlobalObject * lexicalGlobalObject, CallFrame* callFrame))
{
    return jsBufferConstructorFunction_allocUnsafeSlowBody(lexicalGlobalObject, callFrame);
}

static inline JSC::EncodedJSValue jsBufferByteLengthFromStringAndEncoding(JSC::JSGlobalObject* lexicalGlobalObject, JSString* str, WebCore::BufferEncodingType encoding)
{
    auto& vm = JSC::getVM(lexicalGlobalObject);
    auto scope = DECLARE_THROW_SCOPE(vm);

    if (!str) {
        throwTypeError(lexicalGlobalObject, scope, "byteLength() expects a string"_s);
        return {};
    }

    if (auto length = Bun::byteLength(str, lexicalGlobalObject, encoding)) {
        return JSValue::encode(jsNumber(*length));
    }
    if (!scope.exception()) {
        throwOutOfMemoryError(lexicalGlobalObject, scope);
    }

    return {};
}

static inline JSC::EncodedJSValue jsBufferConstructorFunction_byteLengthBody(JSC::JSGlobalObject* lexicalGlobalObject, JSC::CallFrame* callFrame)
{
    auto& vm = JSC::getVM(lexicalGlobalObject);
    auto scope = DECLARE_THROW_SCOPE(vm);

    WebCore::BufferEncodingType encoding = WebCore::BufferEncodingType::utf8;

    EnsureStillAliveScope arg0 = callFrame->argument(0);
    EnsureStillAliveScope arg1 = callFrame->argument(1);

    if (callFrame->argumentCount() > 1) {

        if (arg1.value().isString()) {
            std::optional<BufferEncodingType> encoded = parseEnumeration<BufferEncodingType>(*lexicalGlobalObject, arg1.value());

            // this one doesn't fail
            if (encoded) {
                encoding = encoded.value();
            }
        }
    }

    if (LIKELY(arg0.value().isString()))
        return jsBufferByteLengthFromStringAndEncoding(lexicalGlobalObject, asString(arg0.value()), encoding);

    if (auto* arrayBufferView = jsDynamicCast<JSC::JSArrayBufferView*>(arg0.value())) {
        return JSValue::encode(jsNumber(arrayBufferView->byteLength()));
    }

    if (auto* arrayBuffer = jsDynamicCast<JSC::JSArrayBuffer*>(arg0.value())) {
        return JSValue::encode(jsNumber(arrayBuffer->impl()->byteLength()));
    }

    return Bun::ERR::INVALID_ARG_TYPE(scope, lexicalGlobalObject, "string"_s, "string or an instance of Buffer or ArrayBuffer"_s, callFrame->argument(0));
}

static inline JSC::EncodedJSValue jsBufferConstructorFunction_compareBody(JSC::JSGlobalObject* lexicalGlobalObject, JSC::CallFrame* callFrame)
{
    auto& vm = JSC::getVM(lexicalGlobalObject);
    auto throwScope = DECLARE_THROW_SCOPE(vm);

    auto castedThisValue = callFrame->argument(0);
    JSC::JSArrayBufferView* castedThis = JSC::jsDynamicCast<JSC::JSArrayBufferView*>(castedThisValue);
    if (UNLIKELY(!castedThis)) {
        return Bun::ERR::INVALID_ARG_TYPE(throwScope, lexicalGlobalObject, "buf1"_s, "Buffer or Uint8Array"_s, castedThisValue);
    }
    if (UNLIKELY(castedThis->isDetached())) {
        throwVMTypeError(lexicalGlobalObject, throwScope, "Uint8Array (first argument) is detached"_s);
        return {};
    }

    auto buffer = callFrame->argument(1);
    JSC::JSArrayBufferView* view = JSC::jsDynamicCast<JSC::JSArrayBufferView*>(buffer);
    if (UNLIKELY(!view)) {
        return Bun::ERR::INVALID_ARG_TYPE(throwScope, lexicalGlobalObject, "buf2"_s, "Buffer or Uint8Array"_s, buffer);
    }
    if (UNLIKELY(view->isDetached())) {
        throwVMTypeError(lexicalGlobalObject, throwScope, "Uint8Array (second argument) is detached"_s);
        return {};
    }

    size_t targetStart = 0;
    size_t targetEndInit = view->byteLength();
    size_t targetEnd = targetEndInit;

    size_t sourceStart = 0;
    size_t sourceEndInit = castedThis->byteLength();
    size_t sourceEnd = sourceEndInit;

    targetStart = std::min(targetStart, std::min(targetEnd, targetEndInit));
    sourceStart = std::min(sourceStart, std::min(sourceEnd, sourceEndInit));

    auto sourceLength = sourceEnd - sourceStart;
    auto targetLength = targetEnd - targetStart;
    auto actualLength = std::min(sourceLength, targetLength);

    auto sourceStartPtr = reinterpret_cast<unsigned char*>(castedThis->vector()) + sourceStart;
    auto targetStartPtr = reinterpret_cast<unsigned char*>(view->vector()) + targetStart;

    auto result = actualLength > 0 ? memcmp(sourceStartPtr, targetStartPtr, actualLength) : 0;

    RELEASE_AND_RETURN(throwScope, JSC::JSValue::encode(JSC::jsNumber(normalizeCompareVal(result, sourceLength, targetLength))));
}

static inline JSC::EncodedJSValue jsBufferConstructorFunction_concatBody(JSC::JSGlobalObject* lexicalGlobalObject, JSC::CallFrame* callFrame)
{
    auto& vm = JSC::getVM(lexicalGlobalObject);
    auto throwScope = DECLARE_THROW_SCOPE(vm);

    if (callFrame->argumentCount() < 1) {
        return constructBufferEmpty(lexicalGlobalObject);
    }
    auto listValue = callFrame->argument(0);

    Bun::V::validateArray(throwScope, lexicalGlobalObject, listValue, "list"_s, jsUndefined());
    RETURN_IF_EXCEPTION(throwScope, {});

    auto array = JSC::jsDynamicCast<JSC::JSArray*>(listValue);
    size_t arrayLength = array->length();
    if (arrayLength < 1) {
        RELEASE_AND_RETURN(throwScope, constructBufferEmpty(lexicalGlobalObject));
    }

    JSValue totalLengthValue = callFrame->argument(1);

    size_t byteLength = 0;

    // Use an argument buffer to avoid calling `getIndex` more than once per element.
    // This is a small optimization
    MarkedArgumentBuffer args;
    args.ensureCapacity(arrayLength);
    if (UNLIKELY(args.hasOverflowed())) {
        throwOutOfMemoryError(lexicalGlobalObject, throwScope);
        return {};
    }

    for (unsigned i = 0; i < arrayLength; i++) {
        JSValue element = array->getIndex(lexicalGlobalObject, i);
        RETURN_IF_EXCEPTION(throwScope, {});

        auto* typedArray = JSC::jsDynamicCast<JSC::JSUint8Array*>(element);
        if (!typedArray) {
            return Bun::ERR::INVALID_ARG_TYPE(throwScope, lexicalGlobalObject, makeString("list["_s, i, "]"_s), "Buffer or Uint8Array"_s, element);
        }
        if (UNLIKELY(typedArray->isDetached())) {
            return throwVMTypeError(lexicalGlobalObject, throwScope, "ArrayBufferView is detached"_s);
        }

        auto length = typedArray->byteLength();

        if (length > 0)
            args.append(element);

        byteLength += length;
    }

    size_t availableLength = byteLength;
    if (!totalLengthValue.isUndefined()) {
        if (UNLIKELY(!totalLengthValue.isNumber())) {
            throwTypeError(lexicalGlobalObject, throwScope, "totalLength must be a valid number"_s);
            return {};
        }

        auto totalLength = totalLengthValue.toTypedArrayIndex(lexicalGlobalObject, "totalLength must be a valid number"_s);
        RETURN_IF_EXCEPTION(throwScope, {});
        byteLength = totalLength;
    }

    if (byteLength == 0) {
        RELEASE_AND_RETURN(throwScope, constructBufferEmpty(lexicalGlobalObject));
    }

    JSC::JSUint8Array* outBuffer = byteLength <= availableLength
        ?
        // all pages will be copied in, so we can use uninitialized buffer
        createUninitializedBuffer(lexicalGlobalObject, byteLength)
        :
        // there will be some data that needs to be zeroed out
        // let's let the operating system do that for us
        allocBuffer(lexicalGlobalObject, byteLength);

    if (!outBuffer) {
        ASSERT(throwScope.exception());
        return {};
    }

    size_t remain = byteLength;
    auto* head = outBuffer->typedVector();
    const int arrayLengthI = args.size();
    for (int i = 0; i < arrayLengthI && remain > 0; i++) {
        auto* bufferView = JSC::jsCast<JSC::JSArrayBufferView*>(args.at(i));
        size_t length = std::min(remain, bufferView->byteLength());

        ASSERT_WITH_MESSAGE(length > 0, "length should be greater than 0. This should be checked before appending to the MarkedArgumentBuffer.");

        auto* source = bufferView->vector();
        ASSERT(source);
        memcpy(head, source, length);

        remain -= length;
        head += length;
    }

    RELEASE_AND_RETURN(throwScope, JSC::JSValue::encode(JSC::JSValue(outBuffer)));
}

// https://github.com/nodejs/node/blob/v22.9.0/lib/buffer.js#L337
static inline JSC::EncodedJSValue jsBufferConstructorFunction_copyBytesFromBody(JSC::JSGlobalObject* lexicalGlobalObject, JSC::CallFrame* callFrame)
{
    auto& vm = JSC::getVM(lexicalGlobalObject);
    auto throwScope = DECLARE_THROW_SCOPE(vm);

    auto viewValue = callFrame->argument(0);
    auto offsetValue = callFrame->argument(1);
    auto lengthValue = callFrame->argument(2);

    auto view = jsDynamicCast<JSArrayBufferView*>(viewValue);
    if (!view) {
        return Bun::ERR::INVALID_ARG_TYPE(throwScope, lexicalGlobalObject, "view"_s, "TypedArray"_s, viewValue);
    }

    auto ty = JSC::typedArrayType(view->type());

    auto viewLength = view->length();
    if (viewLength == 0) {
        return JSValue::encode(createEmptyBuffer(lexicalGlobalObject));
    }

    double offset;
    double length;

    if (!offsetValue.isUndefined() || !lengthValue.isUndefined()) {
        if (!offsetValue.isUndefined()) {
            Bun::V::validateInteger(throwScope, lexicalGlobalObject, offsetValue, "offset"_s, jsNumber(0), jsUndefined());
            RETURN_IF_EXCEPTION(throwScope, {});
            offset = offsetValue.asNumber();
            if (offset >= viewLength) return JSValue::encode(createEmptyBuffer(lexicalGlobalObject));
        } else {
            offset = 0;
        }

        double end = 0;
        if (!lengthValue.isUndefined()) {
            Bun::V::validateInteger(throwScope, lexicalGlobalObject, lengthValue, "length"_s, jsNumber(0), jsUndefined());
            RETURN_IF_EXCEPTION(throwScope, {});
            length = lengthValue.asNumber();
            end = offset + length;
        } else {
            end = viewLength;
        }
        end = std::min(end, (double)viewLength);

        auto elemSize = JSC::elementSize(ty);
        auto offset_r = offset * elemSize;
        auto end_r = end * elemSize;
        auto span = view->span().subspan(offset_r, end_r - offset_r);
        return JSValue::encode(createBuffer(lexicalGlobalObject, span.data(), span.size()));
    }

    auto boffset = view->byteOffset();
    auto blength = view->byteLength();
    auto span = view->span().subspan(boffset, blength - boffset);
    return JSValue::encode(createBuffer(lexicalGlobalObject, span.data(), span.size()));
}

static inline JSC::EncodedJSValue jsBufferConstructorFunction_isEncodingBody(JSC::JSGlobalObject* lexicalGlobalObject, JSC::CallFrame* callFrame)
{
    auto& vm = JSC::getVM(lexicalGlobalObject);
    auto throwScope = DECLARE_THROW_SCOPE(vm);
    auto encodingValue = callFrame->argument(0);
    if (!encodingValue.isString()) {
        return JSValue::encode(jsBoolean(false));
    }
    auto* encoding = encodingValue.toString(lexicalGlobalObject);
    RETURN_IF_EXCEPTION(throwScope, {});
    std::optional<BufferEncodingType> encoded = parseEnumeration<BufferEncodingType>(*lexicalGlobalObject, encoding);
    return JSValue::encode(jsBoolean(!!encoded));
}

class JSBufferPrototype : public JSC::JSNonFinalObject {
public:
    using Base = JSC::JSNonFinalObject;
    static JSBufferPrototype* create(JSC::VM& vm, JSGlobalObject* globalObject, JSC::Structure* structure)
    {
        JSBufferPrototype* ptr = new (NotNull, JSC::allocateCell<JSBufferPrototype>(vm)) JSBufferPrototype(vm, globalObject, structure);
        ptr->finishCreation(vm, globalObject);
        return ptr;
    }

    DECLARE_INFO;
    template<typename CellType, JSC::SubspaceAccess>
    static JSC::GCClient::IsoSubspace* subspaceFor(JSC::VM& vm)
    {
        STATIC_ASSERT_ISO_SUBSPACE_SHARABLE(JSBufferPrototype, Base);
        return &vm.plainObjectSpace();
    }
    static JSC::Structure* createStructure(JSC::VM& vm, JSC::JSGlobalObject* globalObject, JSC::JSValue prototype)
    {
        return JSC::Structure::create(vm, globalObject, prototype, JSC::TypeInfo(JSC::ObjectType, StructureFlags), info());
    }

private:
    JSBufferPrototype(JSC::VM& vm, JSC::JSGlobalObject* globalObject, JSC::Structure* structure)
        : Base(vm, structure)
    {
    }

    void finishCreation(JSC::VM&, JSC::JSGlobalObject*);
};
STATIC_ASSERT_ISO_SUBSPACE_SHARABLE(JSBufferPrototype, JSBufferPrototype::Base);

static inline JSC::EncodedJSValue jsBufferPrototypeFunction_compareBody(JSC::JSGlobalObject* lexicalGlobalObject, JSC::CallFrame* callFrame, typename IDLOperation<JSArrayBufferView>::ClassParameter castedThis)
{
    auto& vm = JSC::getVM(lexicalGlobalObject);
    auto throwScope = DECLARE_THROW_SCOPE(vm);

    auto arg0 = callFrame->argument(0);
    JSC::JSUint8Array* view = JSC::jsDynamicCast<JSC::JSUint8Array*>(arg0);

    if (UNLIKELY(!view)) {
        return Bun::ERR::INVALID_ARG_TYPE(throwScope, lexicalGlobalObject, "target"_s, "Buffer or Uint8Array"_s, arg0);
    }

    if (UNLIKELY(view->isDetached())) {
        throwVMTypeError(lexicalGlobalObject, throwScope, "Uint8Array is detached"_s);
        return {};
    }

    size_t targetStart = 0;
    size_t targetEndInit = view->byteLength();
    size_t targetEnd = targetEndInit;

    size_t sourceStart = 0;
    size_t sourceEndInit = castedThis->byteLength();
    size_t sourceEnd = sourceEndInit;

    JSValue targetStartValue = jsUndefined();
    JSValue targetEndValue = jsUndefined();
    JSValue sourceStartValue = jsUndefined();
    JSValue sourceEndValue = jsUndefined();

    switch (callFrame->argumentCount()) {
    default:
        sourceEndValue = callFrame->uncheckedArgument(4);
        if (sourceEndValue != jsUndefined()) {
            Bun::V::validateInteger(throwScope, lexicalGlobalObject, sourceEndValue, "sourceEnd"_s, jsNumber(0), jsNumber(Bun::Buffer::kMaxLength));
            RETURN_IF_EXCEPTION(throwScope, {});
            sourceEnd = sourceEndValue.asNumber();
        }
        RETURN_IF_EXCEPTION(throwScope, {});
        FALLTHROUGH;
    case 4:
        sourceStartValue = callFrame->uncheckedArgument(3);
        if (sourceStartValue != jsUndefined()) {
            Bun::V::validateInteger(throwScope, lexicalGlobalObject, sourceStartValue, "sourceStart"_s, jsNumber(0), jsNumber(Bun::Buffer::kMaxLength));
            RETURN_IF_EXCEPTION(throwScope, {});
            sourceStart = sourceStartValue.asNumber();
        }
        RETURN_IF_EXCEPTION(throwScope, {});
        FALLTHROUGH;
    case 3:
        targetEndValue = callFrame->uncheckedArgument(2);
        if (targetEndValue != jsUndefined()) {
            Bun::V::validateInteger(throwScope, lexicalGlobalObject, targetEndValue, "targetEnd"_s, jsNumber(0), jsNumber(Bun::Buffer::kMaxLength));
            RETURN_IF_EXCEPTION(throwScope, {});
            targetEnd = targetEndValue.asNumber();
        }
        RETURN_IF_EXCEPTION(throwScope, {});
        FALLTHROUGH;
    case 2:
        targetStartValue = callFrame->uncheckedArgument(1);
        if (targetStartValue != jsUndefined()) {
            Bun::V::validateInteger(throwScope, lexicalGlobalObject, targetStartValue, "targetStart"_s, jsNumber(0), jsNumber(Bun::Buffer::kMaxLength));
            RETURN_IF_EXCEPTION(throwScope, {});
            targetStart = targetStartValue.asNumber();
        }
        RETURN_IF_EXCEPTION(throwScope, {});
        break;
    case 1:
    case 0:
        break;
    }

    if (targetStart > targetEndInit && targetStart <= targetEnd) {
        return Bun::ERR::OUT_OF_RANGE(throwScope, lexicalGlobalObject, "targetStart"_s, 0, targetEndInit, targetStartValue);
    }
    if (targetEnd > targetEndInit && targetEnd >= targetStart) {
        return Bun::ERR::OUT_OF_RANGE(throwScope, lexicalGlobalObject, "targetEnd"_s, 0, targetEndInit, targetEndValue);
    }
    if (sourceStart > sourceEndInit && sourceStart <= sourceEnd) {
        return Bun::ERR::OUT_OF_RANGE(throwScope, lexicalGlobalObject, "sourceStart"_s, 0, sourceEndInit, sourceStartValue);
    }
    if (sourceEnd > sourceEndInit && sourceEnd >= sourceStart) {
        return Bun::ERR::OUT_OF_RANGE(throwScope, lexicalGlobalObject, "sourceEnd"_s, 0, sourceEndInit, sourceEndValue);
    }

    targetStart = std::min(targetStart, std::min(targetEnd, targetEndInit));
    sourceStart = std::min(sourceStart, std::min(sourceEnd, sourceEndInit));

    auto sourceLength = sourceEnd - sourceStart;
    auto targetLength = targetEnd - targetStart;
    auto actualLength = std::min(sourceLength, targetLength);

    auto sourceStartPtr = castedThis->typedVector() + sourceStart;
    auto targetStartPtr = view->typedVector() + targetStart;

    auto result = actualLength > 0 ? memcmp(sourceStartPtr, targetStartPtr, actualLength) : 0;

    RELEASE_AND_RETURN(throwScope, JSC::JSValue::encode(JSC::jsNumber(normalizeCompareVal(result, sourceLength, targetLength))));
}

static double toInteger(JSC::ThrowScope& scope, JSC::JSGlobalObject* globalObject, JSValue value, double defaultVal)
{
    auto n = value.toNumber(globalObject);
    RETURN_IF_EXCEPTION(scope, {});
    if (std::isnan(n)) return defaultVal;
    if (n < JSC::minSafeInteger()) return defaultVal;
    if (n > JSC::maxSafeInteger()) return defaultVal;
    return std::trunc(n);
}

// https://github.com/nodejs/node/blob/v22.9.0/lib/buffer.js#L825
// https://github.com/nodejs/node/blob/v22.9.0/lib/buffer.js#L205
static inline JSC::EncodedJSValue jsBufferPrototypeFunction_copyBody(JSC::JSGlobalObject* lexicalGlobalObject, JSC::CallFrame* callFrame, typename IDLOperation<JSArrayBufferView>::ClassParameter castedThis)
{
    auto& vm = JSC::getVM(lexicalGlobalObject);
    auto throwScope = DECLARE_THROW_SCOPE(vm);

    auto targetValue = callFrame->argument(0);
    auto targetStartValue = callFrame->argument(1);
    auto sourceStartValue = callFrame->argument(2);
    auto sourceEndValue = callFrame->argument(3);

    auto source = castedThis;
    auto target = jsDynamicCast<JSArrayBufferView*>(targetValue);
    if (!target) {
        return Bun::ERR::INVALID_ARG_TYPE(throwScope, lexicalGlobalObject, "target"_s, "Buffer or Uint8Array"_s, targetValue);
    }

    auto sourceLength = source->byteLength();
    auto targetLength = target->byteLength();

    size_t targetStart = 0;
    if (targetStartValue.isUndefined()) {
    } else {
        double targetStartD = targetStartValue.isAnyInt() ? targetStartValue.asNumber() : toInteger(throwScope, lexicalGlobalObject, targetStartValue, 0);
        RETURN_IF_EXCEPTION(throwScope, {});
        if (targetStartD < 0) return Bun::ERR::OUT_OF_RANGE(throwScope, lexicalGlobalObject, "targetStart"_s, 0, targetLength, targetStartValue);
        targetStart = static_cast<size_t>(targetStartD);
    }

    size_t sourceStart = 0;
    if (sourceStartValue.isUndefined()) {
    } else {
        double sourceStartD = sourceStartValue.isAnyInt() ? sourceStartValue.asNumber() : toInteger(throwScope, lexicalGlobalObject, sourceStartValue, 0);
        RETURN_IF_EXCEPTION(throwScope, {});
        if (sourceStartD < 0 || sourceStartD > sourceLength) return Bun::ERR::OUT_OF_RANGE(throwScope, lexicalGlobalObject, "sourceStart"_s, 0, sourceLength, sourceStartValue);
        sourceStart = static_cast<size_t>(sourceStartD);
    }

    size_t sourceEnd = sourceLength;
    if (sourceEndValue.isUndefined()) {
    } else {
        double sourceEndD = sourceEndValue.isAnyInt() ? sourceEndValue.asNumber() : toInteger(throwScope, lexicalGlobalObject, sourceEndValue, 0);
        RETURN_IF_EXCEPTION(throwScope, {});
        if (sourceEndD < 0) return Bun::ERR::OUT_OF_RANGE(throwScope, lexicalGlobalObject, "sourceEnd"_s, 0, sourceLength, sourceEndValue);
        sourceEnd = static_cast<size_t>(sourceEndD);
    }

    if (targetStart >= targetLength || sourceStart >= sourceEnd) {
        return JSValue::encode(jsNumber(0));
    }

    if (sourceEnd - sourceStart > targetLength - targetStart)
        sourceEnd = sourceStart + targetLength - targetStart;

    ssize_t nb = sourceEnd - sourceStart;
    auto sourceLen = sourceLength - sourceStart;
    if (nb > sourceLen) nb = sourceLen;

    if (nb <= 0) return JSValue::encode(jsNumber(0));

    auto sourceStartPtr = reinterpret_cast<unsigned char*>(source->vector()) + sourceStart;
    auto targetStartPtr = reinterpret_cast<unsigned char*>(target->vector()) + targetStart;
    memmove(targetStartPtr, sourceStartPtr, nb);

    return JSValue::encode(jsNumber(nb));
}

static inline JSC::EncodedJSValue jsBufferPrototypeFunction_equalsBody(JSC::JSGlobalObject* lexicalGlobalObject, JSC::CallFrame* callFrame, typename IDLOperation<JSArrayBufferView>::ClassParameter castedThis)
{
    auto& vm = JSC::getVM(lexicalGlobalObject);
    auto throwScope = DECLARE_THROW_SCOPE(vm);

    if (callFrame->argumentCount() < 1) {
        throwVMError(lexicalGlobalObject, throwScope, createNotEnoughArgumentsError(lexicalGlobalObject));
        return {};
    }

    auto buffer = callFrame->uncheckedArgument(0);
    JSC::JSArrayBufferView* view = JSC::jsDynamicCast<JSC::JSArrayBufferView*>(buffer);
    if (UNLIKELY(!view)) {
        return Bun::ERR::INVALID_ARG_TYPE(throwScope, lexicalGlobalObject, "otherBuffer"_s, "Buffer or Uint8Array"_s, buffer);
    }

    if (UNLIKELY(view->isDetached())) {
        throwVMTypeError(lexicalGlobalObject, throwScope, "Uint8Array is detached"_s);
        return {};
    }

    size_t a_length = castedThis->byteLength();
    size_t b_length = view->byteLength();
    auto sourceStartPtr = castedThis->typedVector();
    auto targetStartPtr = reinterpret_cast<unsigned char*>(view->vector());

    // same pointer, same length, same contents
    if (sourceStartPtr == targetStartPtr && a_length == b_length)
        RELEASE_AND_RETURN(throwScope, JSValue::encode(jsBoolean(true)));

    size_t compare_length = std::min(a_length, b_length);
    auto result = compare_length > 0 ? memcmp(sourceStartPtr, targetStartPtr, compare_length) : 0;

    RELEASE_AND_RETURN(throwScope, JSC::JSValue::encode(JSC::jsBoolean(normalizeCompareVal(result, a_length, b_length) == 0)));
}

static inline JSC::EncodedJSValue jsBufferPrototypeFunction_fillBody(JSC::JSGlobalObject* lexicalGlobalObject, JSC::CallFrame* callFrame, typename IDLOperation<JSArrayBufferView>::ClassParameter castedThis)
{
    auto& vm = JSC::getVM(lexicalGlobalObject);
    auto scope = DECLARE_THROW_SCOPE(vm);

    if (callFrame->argumentCount() < 1) {
        return JSValue::encode(castedThis);
    }

    auto value = callFrame->uncheckedArgument(0);
    const size_t limit = castedThis->byteLength();
    size_t offset = 0;
    size_t end = limit;
    WebCore::BufferEncodingType encoding = WebCore::BufferEncodingType::utf8;
    JSValue encodingValue = jsUndefined();
    JSValue offsetValue = jsUndefined();
    JSValue endValue = jsUndefined();

    switch (callFrame->argumentCount()) {
    case 4:
        encodingValue = callFrame->uncheckedArgument(3);
        FALLTHROUGH;
    case 3:
        endValue = callFrame->uncheckedArgument(2);
        FALLTHROUGH;
    case 2:
        offsetValue = callFrame->uncheckedArgument(1);
        FALLTHROUGH;
    default:
        break;
    }

    if (offsetValue.isUndefined() || offsetValue.isString()) {
        encodingValue = offsetValue;
        offsetValue = jsUndefined();
    } else if (endValue.isString()) {
        encodingValue = endValue;
        endValue = jsUndefined();
    }

    if (!encodingValue.isUndefined() && value.isString()) {
        if (!encodingValue.isString()) return Bun::ERR::INVALID_ARG_TYPE(scope, lexicalGlobalObject, "encoding"_s, "string"_s, encodingValue);
        encoding = parseEncoding(lexicalGlobalObject, scope, encodingValue);
        RETURN_IF_EXCEPTION(scope, {});
    }

    // https://github.com/nodejs/node/blob/v22.9.0/lib/buffer.js#L1066-L1079
    // https://github.com/nodejs/node/blob/v22.9.0/lib/buffer.js#L122
    if (!offsetValue.isUndefined()) {
        Bun::V::validateNumber(scope, lexicalGlobalObject, offsetValue, "offset"_s, jsNumber(0), jsNumber(Bun::Buffer::kMaxLength));
        RETURN_IF_EXCEPTION(scope, {});
        offset = offsetValue.toLength(lexicalGlobalObject);
    }
    if (!endValue.isUndefined()) {
        Bun::V::validateNumber(scope, lexicalGlobalObject, endValue, "end"_s, jsNumber(0), jsNumber(limit));
        RETURN_IF_EXCEPTION(scope, {});
        end = endValue.toLength(lexicalGlobalObject);
    }
    if (offset >= end) {
        RELEASE_AND_RETURN(scope, JSValue::encode(castedThis));
    }

    if (value.isString()) {
        auto startPtr = castedThis->typedVector() + offset;
        auto str_ = value.toWTFString(lexicalGlobalObject);
        RETURN_IF_EXCEPTION(scope, {});
        ZigString str = Zig::toZigString(str_);

        if (str.len == 0) {
            memset(startPtr, 0, end - offset);
        } else if (UNLIKELY(!Bun__Buffer_fill(&str, startPtr, end - offset, encoding))) {
            return Bun::ERR::INVALID_ARG_VALUE(scope, lexicalGlobalObject, "value"_s, value);
        }
    } else if (auto* view = JSC::jsDynamicCast<JSC::JSArrayBufferView*>(value)) {
        auto* startPtr = castedThis->typedVector() + offset;
        auto* head = startPtr;
        size_t remain = end - offset;

        if (UNLIKELY(view->isDetached())) {
            throwVMTypeError(lexicalGlobalObject, scope, "Uint8Array is detached"_s);
            return {};
        }

        size_t length = view->byteLength();
        if (UNLIKELY(length == 0)) {
            throwTypeError(lexicalGlobalObject, scope, "Buffer cannot be empty"_s);
            return {};
        }

        length = std::min(length, remain);

        memmove(head, view->vector(), length);
        remain -= length;
        head += length;
        while (remain >= length && length > 0) {
            memmove(head, startPtr, length);
            remain -= length;
            head += length;
            length <<= 1;
        }
        if (remain > 0) {
            memmove(head, startPtr, remain);
        }
    } else {
        auto value_ = value.toInt32(lexicalGlobalObject) & 0xFF;
        RETURN_IF_EXCEPTION(scope, {});

        auto value_uint8 = static_cast<uint8_t>(value_);
        RETURN_IF_EXCEPTION(scope, {});

        auto startPtr = castedThis->typedVector() + offset;
        auto endPtr = castedThis->typedVector() + end;
        memset(startPtr, value_uint8, endPtr - startPtr);
    }

    RELEASE_AND_RETURN(scope, JSValue::encode(castedThis));
}

#if OS(WINDOWS)
extern "C" void* zig_memmem(const void* haystack, size_t haystack_len, const void* needle, size_t needle_len);
#define MEMMEM_IMPL zig_memmem
#else
#define MEMMEM_IMPL memmem
#endif

static int64_t indexOf(const uint8_t* thisPtr, int64_t thisLength, const uint8_t* valuePtr, int64_t valueLength, int64_t byteOffset)
{
    if (thisLength < valueLength + byteOffset)
        return -1;
    auto start = thisPtr + byteOffset;

    auto it = static_cast<uint8_t*>(MEMMEM_IMPL(start, static_cast<size_t>(thisLength - byteOffset), valuePtr, static_cast<size_t>(valueLength)));
    if (it != NULL) {
        return it - thisPtr;
    }
    return -1;
}

static int64_t lastIndexOf(const uint8_t* thisPtr, int64_t thisLength, const uint8_t* valuePtr, int64_t valueLength, int64_t byteOffset)
{
    auto start = thisPtr;
    auto end = thisPtr + std::min(thisLength, byteOffset + valueLength);
    auto it = std::find_end(start, end, valuePtr, valuePtr + valueLength);
    if (it != end) {
        return it - thisPtr;
    }
    return -1;
}

static int64_t indexOf(JSC::JSGlobalObject* lexicalGlobalObject, JSC::CallFrame* callFrame, typename IDLOperation<JSArrayBufferView>::ClassParameter castedThis, bool last)
{
    auto& vm = JSC::getVM(lexicalGlobalObject);
    auto scope = DECLARE_THROW_SCOPE(vm);

    if (callFrame->argumentCount() < 1) {
        throwVMError(lexicalGlobalObject, scope, createNotEnoughArgumentsError(lexicalGlobalObject));
        return -1;
    }

    auto value = callFrame->uncheckedArgument(0);
    WebCore::BufferEncodingType encoding = WebCore::BufferEncodingType::utf8;

    int64_t length = static_cast<int64_t>(castedThis->byteLength());
    const uint8_t* typedVector = castedThis->typedVector();

    int64_t byteOffset = last ? length - 1 : 0;

    if (callFrame->argumentCount() > 1) {
        EnsureStillAliveScope arg1 = callFrame->uncheckedArgument(1);
        if (arg1.value().isString()) {
            encoding = parseEncoding(lexicalGlobalObject, scope, arg1.value());
            RETURN_IF_EXCEPTION(scope, -1);
        } else {
            auto byteOffset_ = arg1.value().toNumber(lexicalGlobalObject);
            RETURN_IF_EXCEPTION(scope, -1);

            if (std::isnan(byteOffset_) || std::isinf(byteOffset_)) {
                byteOffset = last ? length - 1 : 0;
            } else if (byteOffset_ < 0) {
                byteOffset = length + static_cast<int64_t>(byteOffset_);
            } else {
                byteOffset = static_cast<int64_t>(byteOffset_);
            }

            if (last) {
                if (byteOffset < 0) {
                    return -1;
                } else if (byteOffset > length - 1) {
                    byteOffset = length - 1;
                }
            } else {
                if (byteOffset <= 0) {
                    byteOffset = 0;
                } else if (byteOffset > length - 1) {
                    return -1;
                }
            }

            if (callFrame->argumentCount() > 2) {
                EnsureStillAliveScope encodingValue = callFrame->uncheckedArgument(2);
                if (!encodingValue.value().isUndefined()) {
                    encoding = parseEncoding(lexicalGlobalObject, scope, encodingValue.value());
                    RETURN_IF_EXCEPTION(scope, -1);
                }
            }
        }
    }

    if (value.isString()) {
        auto* str = value.toStringOrNull(lexicalGlobalObject);
        RETURN_IF_EXCEPTION(scope, -1);

        JSC::EncodedJSValue encodedBuffer = constructFromEncoding(lexicalGlobalObject, str, encoding);
        auto* arrayValue = JSC::jsDynamicCast<JSC::JSUint8Array*>(JSC::JSValue::decode(encodedBuffer));
        int64_t lengthValue = static_cast<int64_t>(arrayValue->byteLength());
        const uint8_t* typedVectorValue = arrayValue->typedVector();
        if (last) {
            return lastIndexOf(typedVector, length, typedVectorValue, lengthValue, byteOffset);
        } else {
            return indexOf(typedVector, length, typedVectorValue, lengthValue, byteOffset);
        }
    } else if (value.isNumber()) {
        uint8_t byteValue = static_cast<uint8_t>((value.toInt32(lexicalGlobalObject)) % 256);
        RETURN_IF_EXCEPTION(scope, -1);

        if (last) {
            for (int64_t i = byteOffset; i >= 0; --i) {
                if (byteValue == typedVector[i]) {
                    return i;
                }
            }
        } else {
            const void* offset = memchr(reinterpret_cast<const void*>(typedVector + byteOffset), byteValue, length - byteOffset);
            if (offset != NULL) {
                return static_cast<int64_t>(static_cast<const uint8_t*>(offset) - typedVector);
            }
        }

        return -1;
    } else if (auto* arrayValue = JSC::jsDynamicCast<JSC::JSUint8Array*>(value)) {
        size_t lengthValue = arrayValue->byteLength();
        const uint8_t* typedVectorValue = arrayValue->typedVector();
        if (last) {
            return lastIndexOf(typedVector, length, typedVectorValue, lengthValue, byteOffset);
        } else {
            return indexOf(typedVector, length, typedVectorValue, lengthValue, byteOffset);
        }
    } else {
        throwTypeError(lexicalGlobalObject, scope, "Invalid value type"_s);
        return -1;
    }

    return -1;
}

static inline JSC::EncodedJSValue jsBufferPrototypeFunction_includesBody(JSC::JSGlobalObject* lexicalGlobalObject, JSC::CallFrame* callFrame, typename IDLOperation<JSArrayBufferView>::ClassParameter castedThis)
{
    auto index = indexOf(lexicalGlobalObject, callFrame, castedThis, false);
    return JSC::JSValue::encode(jsBoolean(index != -1));
}

static inline JSC::EncodedJSValue jsBufferPrototypeFunction_indexOfBody(JSC::JSGlobalObject* lexicalGlobalObject, JSC::CallFrame* callFrame, typename IDLOperation<JSArrayBufferView>::ClassParameter castedThis)
{
    auto index = indexOf(lexicalGlobalObject, callFrame, castedThis, false);
    return JSC::JSValue::encode(jsNumber(index));
}

static JSC::EncodedJSValue jsBufferPrototypeFunction_inspectBody(JSC::JSGlobalObject* lexicalGlobalObject, JSC::CallFrame* callFrame, typename IDLOperation<JSArrayBufferView>::ClassParameter castedThis)
{
    auto globalObject = defaultGlobalObject(lexicalGlobalObject);
    auto& vm = JSC::getVM(globalObject);
    auto scope = DECLARE_THROW_SCOPE(vm);

    auto recurseTimes = callFrame->argument(0);
    UNUSED_PARAM(recurseTimes);
    auto ctx = callFrame->argument(1);

    WTF::StringBuilder result;
    auto data = castedThis->span();
    auto alphabet = "0123456789abcdef"_s;
    auto any = false;

    result.append("<Buffer"_s);
    auto max = globalObject->INSPECT_MAX_BYTES;
    auto actualMaxD = std::min<double>(max, data.size());
    size_t actualMax = actualMaxD;

    for (auto item : data.first(actualMax)) {
        any = true;
        result.append(' ');
        result.append(alphabet[item / 16]);
        result.append(alphabet[item % 16]);
    }
    if (data.size() > max) {
        auto remaining = data.size() - max;
        result.append(makeString(" ... "_s, remaining, " more byte"_s));
        if (remaining > 1) result.append('s');
    }

    // Inspect special properties as well, if possible.
    if (ctx.toBoolean(globalObject)) {
        auto showHidden = ctx.get(globalObject, Identifier::fromString(vm, "showHidden"_s));
        RETURN_IF_EXCEPTION(scope, {});
        JSC::PropertyNameArray array(vm, PropertyNameMode::StringsAndSymbols, PrivateSymbolMode::Exclude);

        auto filter = showHidden.toBoolean(globalObject) ? DontEnumPropertiesMode::Include : DontEnumPropertiesMode::Exclude;

        if (UNLIKELY(castedThis->hasNonReifiedStaticProperties())) {
            castedThis->reifyAllStaticProperties(globalObject);
        }
        castedThis->getOwnNonIndexPropertyNames(globalObject, array, filter);
        RETURN_IF_EXCEPTION(scope, {});

        if (array.size() > 0) {
            any = true;
            if (data.size() > 0) {
                result.append(","_s);
            }
            result.append(' ');
            size_t i = 0;
            for (auto ident : array) {
                if (i > 0) result.append(", "_s);
                result.append(ident.string());
                result.append(": "_s);
                auto value = castedThis->get(globalObject, ident);
                RETURN_IF_EXCEPTION(scope, {});
                auto inspected = Bun__inspect_singleline(globalObject, value).transferToWTFString();
                result.append(inspected);
                i++;
            }
        }
    }
    if (!any) result.append(' ');
    result.append('>');
    return JSValue::encode(JSC::jsString(vm, result.toString()));
}

static inline JSC::EncodedJSValue jsBufferPrototypeFunction_lastIndexOfBody(JSC::JSGlobalObject* lexicalGlobalObject, JSC::CallFrame* callFrame, typename IDLOperation<JSArrayBufferView>::ClassParameter castedThis)
{
    auto index = indexOf(lexicalGlobalObject, callFrame, castedThis, true);
    return JSC::JSValue::encode(jsNumber(index));
}

static inline JSC::EncodedJSValue jsBufferPrototypeFunction_swap16Body(JSC::JSGlobalObject* lexicalGlobalObject, JSC::CallFrame* callFrame, typename IDLOperation<JSArrayBufferView>::ClassParameter castedThis)
{
    auto& vm = JSC::getVM(lexicalGlobalObject);
    auto scope = DECLARE_THROW_SCOPE(vm);

    constexpr int elemSize = 2;
    int64_t length = static_cast<int64_t>(castedThis->byteLength());
    if (length % elemSize != 0) {
        throwNodeRangeError(lexicalGlobalObject, scope, "Buffer size must be a multiple of 16-bits"_s);
        return {};
    }

    if (UNLIKELY(castedThis->isDetached())) {
        throwVMTypeError(lexicalGlobalObject, scope, "Buffer is detached"_s);
        return {};
    }

    uint8_t* typedVector = castedThis->typedVector();

    for (size_t elem = 0; elem < length; elem += elemSize) {
        const size_t right = elem + 1;

        uint8_t temp = typedVector[elem];
        typedVector[elem] = typedVector[right];
        typedVector[right] = temp;
    }

    return JSC::JSValue::encode(castedThis);
}

static inline JSC::EncodedJSValue jsBufferPrototypeFunction_swap32Body(JSC::JSGlobalObject* lexicalGlobalObject, JSC::CallFrame* callFrame, typename IDLOperation<JSArrayBufferView>::ClassParameter castedThis)
{
    auto& vm = JSC::getVM(lexicalGlobalObject);
    auto scope = DECLARE_THROW_SCOPE(vm);

    constexpr int elemSize = 4;
    int64_t length = static_cast<int64_t>(castedThis->byteLength());
    if (length % elemSize != 0) {
        throwNodeRangeError(lexicalGlobalObject, scope, "Buffer size must be a multiple of 32-bits"_s);
        return {};
    }

    if (UNLIKELY(castedThis->isDetached())) {
        throwVMTypeError(lexicalGlobalObject, scope, "Buffer is detached"_s);
        return {};
    }

    uint8_t* typedVector = castedThis->typedVector();

    constexpr size_t swaps = elemSize / 2;
    for (size_t elem = 0; elem < length; elem += elemSize) {
        const size_t right = elem + elemSize - 1;
        for (size_t k = 0; k < swaps; k++) {
            const size_t i = right - k;
            const size_t j = elem + k;

            uint8_t temp = typedVector[i];
            typedVector[i] = typedVector[j];
            typedVector[j] = temp;
        }
    }

    return JSC::JSValue::encode(castedThis);
}

static inline JSC::EncodedJSValue jsBufferPrototypeFunction_swap64Body(JSC::JSGlobalObject* lexicalGlobalObject, JSC::CallFrame* callFrame, typename IDLOperation<JSArrayBufferView>::ClassParameter castedThis)
{
    auto& vm = JSC::getVM(lexicalGlobalObject);
    auto scope = DECLARE_THROW_SCOPE(vm);

    constexpr size_t elemSize = 8;
    int64_t length = static_cast<int64_t>(castedThis->byteLength());
    if (length % elemSize != 0) {
        throwNodeRangeError(lexicalGlobalObject, scope, "Buffer size must be a multiple of 64-bits"_s);
        return {};
    }

    if (UNLIKELY(castedThis->isDetached())) {
        throwVMTypeError(lexicalGlobalObject, scope, "Buffer is detached"_s);
        return {};
    }

    uint8_t* typedVector = castedThis->typedVector();

    constexpr size_t swaps = elemSize / 2;
    for (size_t elem = 0; elem < length; elem += elemSize) {
        const size_t right = elem + elemSize - 1;
        for (size_t k = 0; k < swaps; k++) {
            const size_t i = right - k;
            const size_t j = elem + k;

            uint8_t temp = typedVector[i];
            typedVector[i] = typedVector[j];
            typedVector[j] = temp;
        }
    }

    return JSC::JSValue::encode(castedThis);
}

static inline JSC::EncodedJSValue jsBufferToString(JSC::VM& vm, JSC::JSGlobalObject* lexicalGlobalObject, JSC::JSArrayBufferView* castedThis, size_t offset, size_t length, WebCore::BufferEncodingType encoding)
{
    auto scope = DECLARE_THROW_SCOPE(vm);

    if (UNLIKELY(length == 0)) {
        RELEASE_AND_RETURN(scope, JSC::JSValue::encode(JSC::jsEmptyString(vm)));
    }
    if (length > WTF::String::MaxLength) {
        return Bun::ERR::STRING_TOO_LONG(scope, lexicalGlobalObject);
    }
    if (length > castedThis->byteLength()) {
        length = castedThis->byteLength();
    }

    JSC::EncodedJSValue ret = 0;

    switch (encoding) {
    case WebCore::BufferEncodingType::latin1: {
        std::span<LChar> data;
        auto str = String::createUninitialized(length, data);
        memcpy(data.data(), reinterpret_cast<const char*>(castedThis->vector()) + offset, length);
        return JSC::JSValue::encode(JSC::jsString(vm, WTFMove(str)));
    }

    case WebCore::BufferEncodingType::ucs2:
    case WebCore::BufferEncodingType::utf16le: {
        std::span<UChar> data;
        size_t u16length = length / 2;
        if (u16length == 0) {
            return JSC::JSValue::encode(JSC::jsEmptyString(vm));
        } else {
            auto str = String::createUninitialized(u16length, data);
            memcpy(reinterpret_cast<void*>(data.data()), reinterpret_cast<const char*>(castedThis->vector()) + offset, u16length * 2);
            return JSC::JSValue::encode(JSC::jsString(vm, str));
        }

        break;
    }

    case WebCore::BufferEncodingType::ascii: {
        // ascii: we always know the length
        // so we might as well allocate upfront
        std::span<LChar> data;
        auto str = String::createUninitialized(length, data);
        Bun__encoding__writeLatin1(reinterpret_cast<const unsigned char*>(castedThis->vector()) + offset, length, data.data(), length, static_cast<uint8_t>(encoding));
        return JSC::JSValue::encode(JSC::jsString(vm, WTFMove(str)));
    }

    case WebCore::BufferEncodingType::buffer:
    case WebCore::BufferEncodingType::utf8:
    case WebCore::BufferEncodingType::base64:
    case WebCore::BufferEncodingType::base64url:
    case WebCore::BufferEncodingType::hex: {
        ret = Bun__encoding__toString(reinterpret_cast<const unsigned char*>(castedThis->vector()) + offset, length, lexicalGlobalObject, static_cast<uint8_t>(encoding));
        RETURN_IF_EXCEPTION(scope, {});
        break;
    }
    default: {
        throwTypeError(lexicalGlobalObject, scope, "Unsupported encoding? This shouldn't happen"_s);
        return {};
    }
    }

    JSC::JSValue retValue = JSC::JSValue::decode(ret);
    if (UNLIKELY(!retValue.isString())) {
        scope.throwException(lexicalGlobalObject, retValue);
        return {};
    }

    RELEASE_AND_RETURN(scope, JSC::JSValue::encode(retValue));
}

// https://github.com/nodejs/node/blob/2eff28fb7a93d3f672f80b582f664a7c701569fb/src/node_buffer.cc#L208-L233
bool inline parseArrayIndex(JSC::ThrowScope& scope, JSC::JSGlobalObject* globalObject, JSC::JSValue value, size_t& out, ASCIILiteral errorMessage)
{
    if (value.isUndefined()) {
        return true;
    }

    int64_t index = static_cast<int64_t>(value.toIntegerWithTruncation(globalObject));
    RETURN_IF_EXCEPTION(scope, false);

    if (index < 0) {
        throwNodeRangeError(globalObject, scope, errorMessage);
        return false;
    }

    out = static_cast<size_t>(index);
    return true;
}

// https://github.com/nodejs/node/blob/v22.9.0/lib/buffer.js#L834
// using byteLength and byte offsets here is intentional
static inline JSC::EncodedJSValue jsBufferPrototypeFunction_toStringBody(JSC::JSGlobalObject* lexicalGlobalObject, JSC::CallFrame* callFrame, typename IDLOperation<JSArrayBufferView>::ClassParameter castedThis)
{
    auto& vm = JSC::getVM(lexicalGlobalObject);
    auto scope = DECLARE_THROW_SCOPE(vm);

    uint32_t start = 0;
    uint32_t end = castedThis->byteLength();
    uint32_t byteLength = end;
    WebCore::BufferEncodingType encoding = WebCore::BufferEncodingType::utf8;

    if (end == 0)
        return JSC::JSValue::encode(JSC::jsEmptyString(vm));

    size_t argsCount = callFrame->argumentCount();

    JSC::JSValue arg1 = callFrame->argument(0);
    JSC::JSValue arg2 = callFrame->argument(1);
    JSC::JSValue arg3 = callFrame->argument(2);

    if (argsCount == 0)
        return jsBufferToString(vm, lexicalGlobalObject, castedThis, start, end, encoding);

    if (!arg1.isUndefined()) {
        encoding = parseEncoding(lexicalGlobalObject, scope, arg1);
        RETURN_IF_EXCEPTION(scope, {});
    }

    auto fstart = arg2.toNumber(lexicalGlobalObject);
    RETURN_IF_EXCEPTION(scope, {});
    if (fstart < 0) {
        fstart = 0;
        goto lstart;
    }
    if (fstart > byteLength) {
        return JSC::JSValue::encode(JSC::jsEmptyString(vm));
    }
    start = static_cast<uint32_t>(fstart);
lstart:

    if (!arg3.isUndefined()) {
        auto lend = arg3.toLength(lexicalGlobalObject);
        RETURN_IF_EXCEPTION(scope, {});
        if (lend < byteLength) end = lend;
    }

    if (end <= start)
        return JSC::JSValue::encode(JSC::jsEmptyString(vm));

    auto offset = start;
    auto length = end > start ? end - start : 0;
    return jsBufferToString(vm, lexicalGlobalObject, castedThis, offset, length, encoding);
}

// https://github.com/nodejs/node/blob/2eff28fb7a93d3f672f80b582f664a7c701569fb/src/node_buffer.cc#L544
template<BufferEncodingType encoding>
static inline JSC::EncodedJSValue jsBufferPrototypeFunction_SliceWithEncoding(JSC::JSGlobalObject* lexicalGlobalObject, JSC::CallFrame* callFrame)
{
    auto& vm = JSC::getVM(lexicalGlobalObject);
    auto scope = DECLARE_THROW_SCOPE(vm);

    auto* castedThis = JSC::jsDynamicCast<JSC::JSArrayBufferView*>(callFrame->thisValue());
    const JSValue startValue = callFrame->argument(0);
    const JSValue endValue = callFrame->argument(1);

    if (UNLIKELY(!castedThis)) {
        throwTypeError(lexicalGlobalObject, scope, "Expected ArrayBufferView"_s);
        return {};
    }

    const size_t length = castedThis->byteLength();
    if (UNLIKELY(length == 0)) {
        return JSC::JSValue::encode(JSC::jsEmptyString(vm));
    }

    size_t start = 0;
    size_t end = length;

    if (UNLIKELY(!parseArrayIndex(scope, lexicalGlobalObject, startValue, start, "start must be a positive integer"_s))) {
        return {};
    }

    if (UNLIKELY(!parseArrayIndex(scope, lexicalGlobalObject, endValue, end, "end must be a positive integer"_s))) {
        return {};
    }

    if (end < start)
        end = start;

    if (!(end <= length)) {
        throwNodeRangeError(lexicalGlobalObject, scope, "end out of range"_s);
        return {};
    }

    return jsBufferToString(vm, lexicalGlobalObject, castedThis, start, end - start, encoding);
}

// DOMJIT makes it slower! TODO: investigate why
// JSC_DECLARE_JIT_OPERATION_WITHOUT_WTF_INTERNAL(jsBufferPrototypeToStringWithoutTypeChecks, JSValue, (JSC::JSGlobalObject * lexicalGlobalObject, JSC::JSUint8Array* thisValue, JSC::JSString* encodingValue));

// JSC_DEFINE_JIT_OPERATION(jsBufferPrototypeToStringWithoutTypeChecks, JSValue, (JSC::JSGlobalObject * lexicalGlobalObject, JSUint8Array* thisValue, JSString* encodingValue))
// {
//     auto& vm = JSC::getVM(lexicalGlobalObject);
//     IGNORE_WARNINGS_BEGIN("frame-address")
//     CallFrame* callFrame = DECLARE_CALL_FRAME(vm);
//     IGNORE_WARNINGS_END
//     JSC::JITOperationPrologueCallFrameTracer tracer(vm, callFrame);

//     std::optional<BufferEncodingType> encoded = parseEnumeration<BufferEncodingType>(*lexicalGlobalObject, encodingValue);
//     if (!encoded) {
//         auto scope = DECLARE_THROW_SCOPE(vm);

//         throwTypeError(lexicalGlobalObject, scope, "Invalid encoding"_s);
//         return {};
//     }

//     auto encoding = encoded.value();

//     return JSValue::decode(jsBufferToString(vm, lexicalGlobalObject, thisValue, 0, thisValue->byteLength(), encoding));
// }

// https://github.com/nodejs/node/blob/2eff28fb7a93d3f672f80b582f664a7c701569fb/src/node_buffer.cc#L711
template<BufferEncodingType encoding>
static inline JSC::EncodedJSValue jsBufferPrototypeFunction_writeEncodingBody(JSC::VM& vm, JSC::JSGlobalObject* lexicalGlobalObject, JSArrayBufferView* castedThis, JSString* str, JSValue offsetValue, JSValue lengthValue)
{
    size_t offset = 0;
    size_t length = castedThis->byteLength();
    size_t max = length;
    auto scope = DECLARE_THROW_SCOPE(vm);

    if (UNLIKELY(!parseArrayIndex(scope, lexicalGlobalObject, offsetValue, offset, "offset must be > 0"_s))) {
        return {};
    }

    if (UNLIKELY(offset > max)) {
        throwNodeRangeError(lexicalGlobalObject, scope, "offset is out of bounds"_s);
        return {};
    }

    if (UNLIKELY(!parseArrayIndex(scope, lexicalGlobalObject, lengthValue, max, "length must be > 0"_s))) {
        return {};
    }

    size_t max_length = std::min(length - offset, max);

    RELEASE_AND_RETURN(scope, writeToBuffer(lexicalGlobalObject, castedThis, str, offset, max_length, encoding));
}

template<BufferEncodingType encoding>
static inline JSC::EncodedJSValue jsBufferPrototypeFunctionWriteWithEncoding(JSC::JSGlobalObject* lexicalGlobalObject, JSC::CallFrame* callFrame)
{
    auto& vm = JSC::getVM(lexicalGlobalObject);
    auto scope = DECLARE_THROW_SCOPE(vm);

    auto* castedThis = JSC::jsDynamicCast<JSC::JSArrayBufferView*>(callFrame->thisValue());

    JSString* text = callFrame->argument(0).toStringOrNull(lexicalGlobalObject);
    RETURN_IF_EXCEPTION(scope, {});

    JSValue offsetValue = callFrame->argument(1);
    JSValue lengthValue = callFrame->argument(2);

    if (UNLIKELY(!castedThis)) {
        throwTypeError(lexicalGlobalObject, scope, "Expected ArrayBufferView"_s);
        return {};
    }

    if (UNLIKELY(castedThis->isDetached())) {
        throwTypeError(lexicalGlobalObject, scope, "ArrayBufferView is detached"_s);
        return {};
    }

    return jsBufferPrototypeFunction_writeEncodingBody<encoding>(vm, lexicalGlobalObject, castedThis, text, offsetValue, lengthValue);
}

static inline JSC::EncodedJSValue jsBufferPrototypeFunction_writeBody(JSC::JSGlobalObject* lexicalGlobalObject, JSC::CallFrame* callFrame, typename IDLOperation<JSArrayBufferView>::ClassParameter castedThis)
{
    auto& vm = JSC::getVM(lexicalGlobalObject);
    auto scope = DECLARE_THROW_SCOPE(vm);

    uint32_t offset = 0;
    uint32_t length = castedThis->byteLength();
    uint32_t max = length;
    WebCore::BufferEncodingType encoding = WebCore::BufferEncodingType::utf8;

    if (UNLIKELY(callFrame->argumentCount() == 0)) {
        throwTypeError(lexicalGlobalObject, scope, "Not enough arguments"_s);
        return {};
    }

    EnsureStillAliveScope arg0 = callFrame->argument(0);
    auto* str = arg0.value().toStringOrNull(lexicalGlobalObject);
    if (!str) {
        throwTypeError(lexicalGlobalObject, scope, "write() expects a string"_s);
        return {};
    }

    JSValue offsetValue = jsUndefined();
    JSValue lengthValue = jsUndefined();
    JSValue encodingValue = jsUndefined();

    switch (callFrame->argumentCount()) {
    case 4:
        encodingValue = callFrame->uncheckedArgument(3);
        FALLTHROUGH;
    case 3:
        lengthValue = callFrame->uncheckedArgument(2);
        FALLTHROUGH;
    case 2:
        offsetValue = callFrame->uncheckedArgument(1);
        break;
    default:
        break;
    }

    auto setEncoding = [&]() {
        if (!encodingValue.isUndefined()) {
            encoding = parseEncoding(lexicalGlobalObject, scope, encodingValue);
        }
    };

    if (offsetValue.isUndefined()) {
        // https://github.com/nodejs/node/blob/e676942f814915b2d24fc899bb42dc71ae6c8226/lib/buffer.js#L1053
        RELEASE_AND_RETURN(scope, writeToBuffer(lexicalGlobalObject, castedThis, str, offset, length, encoding));
    }

    if (lengthValue.isUndefined() && offsetValue.isString()) {
        // https://github.com/nodejs/node/blob/e676942f814915b2d24fc899bb42dc71ae6c8226/lib/buffer.js#L1056
        encodingValue = offsetValue;
        setEncoding();
        RETURN_IF_EXCEPTION(scope, {});
        RELEASE_AND_RETURN(scope, writeToBuffer(lexicalGlobalObject, castedThis, str, offset, length, encoding));
    }

    if (UNLIKELY(!offsetValue.isNumber())) {
        throwTypeError(lexicalGlobalObject, scope, "Invalid offset"_s);
        return {};
    }

    int32_t userOffset = offsetValue.toInt32(lexicalGlobalObject);
    RETURN_IF_EXCEPTION(scope, {});
    if (userOffset < 0 || userOffset > max) {
        throwNodeRangeError(lexicalGlobalObject, scope, "Offset is out of bounds"_s);
        return {};
    }
    offset = static_cast<uint32_t>(userOffset);
    uint32_t remaining = max - static_cast<uint32_t>(userOffset);

    // https://github.com/nodejs/node/blob/e676942f814915b2d24fc899bb42dc71ae6c8226/lib/buffer.js#L1062-L1077
    if (lengthValue.isUndefined()) {
        length = remaining;
    } else if (lengthValue.isString()) {
        encodingValue = lengthValue;
        setEncoding();
        RETURN_IF_EXCEPTION(scope, {});
        length = remaining;
    } else {
        setEncoding();

        int32_t userLength = lengthValue.toInt32(lexicalGlobalObject);
        RETURN_IF_EXCEPTION(scope, {});
        length = std::min(static_cast<uint32_t>(userLength), remaining);
    }

    RELEASE_AND_RETURN(scope, writeToBuffer(lexicalGlobalObject, castedThis, str, offset, length, encoding));
}

extern "C" JSC::EncodedJSValue JSBuffer__fromMmap(Zig::GlobalObject* globalObject, void* ptr, size_t length)
{
    auto& vm = JSC::getVM(globalObject);
    auto scope = DECLARE_THROW_SCOPE(vm);

    auto* structure = globalObject->JSBufferSubclassStructure();

    auto buffer = ArrayBuffer::createFromBytes({ static_cast<const uint8_t*>(ptr), length }, createSharedTask<void(void*)>([length](void* p) {
#if !OS(WINDOWS)
        munmap(p, length);
#else
        UnmapViewOfFile(p);
#endif
    }));

    auto* view = JSC::JSUint8Array::create(globalObject, structure, WTFMove(buffer), 0, length);

    if (UNLIKELY(!view)) {
        throwOutOfMemoryError(globalObject, scope);
        return {};
    }

    return JSC::JSValue::encode(view);
}

JSC_DEFINE_HOST_FUNCTION(jsBufferConstructorFunction_alloc, (JSGlobalObject * lexicalGlobalObject, CallFrame* callFrame))
{
    return jsBufferConstructorFunction_allocBody(lexicalGlobalObject, callFrame);
}

JSC_DEFINE_HOST_FUNCTION(jsBufferConstructorFunction_allocUnsafe, (JSGlobalObject * lexicalGlobalObject, CallFrame* callFrame))
{
    return jsBufferConstructorFunction_allocUnsafeBody(lexicalGlobalObject, callFrame);
}

JSC_DEFINE_HOST_FUNCTION(jsBufferConstructorFunction_allocUnsafeSlow, (JSGlobalObject * lexicalGlobalObject, CallFrame* callFrame))
{
    return jsBufferConstructorFunction_allocUnsafeSlowBody(lexicalGlobalObject, callFrame);
}

JSC_DEFINE_HOST_FUNCTION(jsBufferConstructorFunction_byteLength, (JSGlobalObject * lexicalGlobalObject, CallFrame* callFrame))
{
    return jsBufferConstructorFunction_byteLengthBody(lexicalGlobalObject, callFrame);
}

class JSBufferConstructor final : public JSC::InternalFunction {
public:
    using Base = JSC::InternalFunction;
    static constexpr unsigned StructureFlags = Base::StructureFlags | HasStaticPropertyTable;

    ~JSBufferConstructor() = default;

    static void destroy(JSC::JSCell* cell)
    {
        static_cast<JSBufferConstructor*>(cell)->JSBufferConstructor::~JSBufferConstructor();
    }

    static JSC::Structure* createStructure(JSC::VM& vm, JSC::JSGlobalObject* globalObject)
    {
        JSValue prototype = globalObject->m_typedArrayUint8.constructorInitializedOnMainThread(globalObject);
        return JSC::Structure::create(vm, globalObject, prototype, JSC::TypeInfo(prototype.asCell()->type(), StructureFlags), info());
    }

    DECLARE_INFO;

    static JSBufferConstructor* create(JSC::VM& vm, JSC::JSGlobalObject* globalObject, JSC::Structure* structure, JSC::JSObject* prototype)
    {
        JSBufferConstructor* constructor = new (NotNull, JSC::allocateCell<JSBufferConstructor>(vm)) JSBufferConstructor(vm, globalObject, structure);
        constructor->finishCreation(vm, globalObject, prototype);
        return constructor;
    }

private:
    JSBufferConstructor(JSC::VM& vm, JSGlobalObject* globalObject, JSC::Structure* structure)
        : Base(vm, structure, callJSBuffer, constructJSBuffer)

    {
    }

    void finishCreation(JSC::VM&, JSGlobalObject*, JSC::JSObject* prototype);

}

JSC_DEFINE_HOST_FUNCTION(jsBufferConstructorFunction_isEncoding, (JSGlobalObject * lexicalGlobalObject, CallFrame* callFrame))
{
    return jsBufferConstructorFunction_isEncodingBody(lexicalGlobalObject, callFrame);
}

JSC_DEFINE_HOST_FUNCTION(jsBufferConstructorFunction_compare, (JSGlobalObject * lexicalGlobalObject, CallFrame* callFrame))
{
    return jsBufferConstructorFunction_compareBody(lexicalGlobalObject, callFrame);
}

JSC_DEFINE_HOST_FUNCTION(jsBufferConstructorFunction_concat, (JSGlobalObject * lexicalGlobalObject, CallFrame* callFrame))
{
    return jsBufferConstructorFunction_concatBody(lexicalGlobalObject, callFrame);
}

JSC_DEFINE_HOST_FUNCTION(jsBufferConstructorFunction_copyBytesFrom, (JSGlobalObject * lexicalGlobalObject, CallFrame* callFrame))
{
    return jsBufferConstructorFunction_copyBytesFromBody(lexicalGlobalObject, callFrame);
}

extern "C" JSC_DECLARE_JIT_OPERATION_WITHOUT_WTF_INTERNAL(jsBufferConstructorAllocWithoutTypeChecks, JSUint8Array*, (JSC::JSGlobalObject * lexicalGlobalObject, void* thisValue, int size));
extern "C" JSC_DECLARE_JIT_OPERATION_WITHOUT_WTF_INTERNAL(jsBufferConstructorAllocUnsafeWithoutTypeChecks, JSUint8Array*, (JSC::JSGlobalObject * lexicalGlobalObject, void* thisValue, int size));
extern "C" JSC_DECLARE_JIT_OPERATION_WITHOUT_WTF_INTERNAL(jsBufferConstructorAllocUnsafeSlowWithoutTypeChecks, JSUint8Array*, (JSC::JSGlobalObject * lexicalGlobalObject, void* thisValue, int size));

JSC_DEFINE_JIT_OPERATION(jsBufferConstructorAllocWithoutTypeChecks, JSUint8Array*, (JSC::JSGlobalObject * lexicalGlobalObject, void* thisValue, int byteLength))
{
    auto& vm = JSC::getVM(lexicalGlobalObject);
    IGNORE_WARNINGS_BEGIN("frame-address")
    CallFrame* callFrame = DECLARE_CALL_FRAME(vm);
    IGNORE_WARNINGS_END
    JSC::JITOperationPrologueCallFrameTracer tracer(vm, callFrame);
    return { allocBuffer(lexicalGlobalObject, byteLength) };
}

JSC_DEFINE_JIT_OPERATION(jsBufferConstructorAllocUnsafeWithoutTypeChecks, JSUint8Array*, (JSC::JSGlobalObject * lexicalGlobalObject, void* thisValue, int byteLength))
{
    auto& vm = JSC::getVM(lexicalGlobalObject);
    IGNORE_WARNINGS_BEGIN("frame-address")
    CallFrame* callFrame = DECLARE_CALL_FRAME(vm);
    IGNORE_WARNINGS_END
    JSC::JITOperationPrologueCallFrameTracer tracer(vm, callFrame);
    return { allocBufferUnsafe(lexicalGlobalObject, byteLength) };
}

JSC_DEFINE_JIT_OPERATION(jsBufferConstructorAllocUnsafeSlowWithoutTypeChecks, JSUint8Array*, (JSC::JSGlobalObject * lexicalGlobalObject, void* thisValue, int byteLength))
{
    auto& vm = JSC::getVM(lexicalGlobalObject);
    IGNORE_WARNINGS_BEGIN("frame-address")
    CallFrame* callFrame = DECLARE_CALL_FRAME(vm);
    IGNORE_WARNINGS_END
    JSC::JITOperationPrologueCallFrameTracer tracer(vm, callFrame);
    return { allocBufferUnsafe(lexicalGlobalObject, byteLength) };
}

JSC_ANNOTATE_HOST_FUNCTION(JSBufferConstructorConstruct, JSBufferConstructor::construct);

class JSBuffer : public JSC::JSNonFinalObject {

    DECLARE_INFO;

    static constexpr JSC::JSTypeRange typeRange = { Uint8ArrayType, Uint8ArrayType };
};

const ClassInfo JSBuffer::s_info = {
    "Buffer"_s,
    JSC::getUint8ArrayClassInfo(),
    nullptr,
    nullptr,
    CREATE_METHOD_TABLE(JSBuffer)
};

JSC_DEFINE_HOST_FUNCTION(jsBufferPrototypeFunction_compare, (JSGlobalObject * lexicalGlobalObject, CallFrame* callFrame))
{
    return IDLOperation<JSArrayBufferView>::call<jsBufferPrototypeFunction_compareBody>(*lexicalGlobalObject, *callFrame, "compare");
}

JSC_DEFINE_HOST_FUNCTION(jsBufferPrototypeFunction_copy, (JSGlobalObject * lexicalGlobalObject, CallFrame* callFrame))
{
    return IDLOperation<JSArrayBufferView>::call<jsBufferPrototypeFunction_copyBody>(*lexicalGlobalObject, *callFrame, "copy");
}

JSC_DEFINE_HOST_FUNCTION(jsBufferPrototypeFunction_equals, (JSGlobalObject * lexicalGlobalObject, CallFrame* callFrame))
{
    return IDLOperation<JSArrayBufferView>::call<jsBufferPrototypeFunction_equalsBody>(*lexicalGlobalObject, *callFrame, "equals");
}

JSC_DEFINE_HOST_FUNCTION(jsBufferPrototypeFunction_fill, (JSGlobalObject * lexicalGlobalObject, CallFrame* callFrame))
{
    return IDLOperation<JSArrayBufferView>::call<jsBufferPrototypeFunction_fillBody>(*lexicalGlobalObject, *callFrame, "fill");
}

JSC_DEFINE_HOST_FUNCTION(jsBufferPrototypeFunction_includes, (JSGlobalObject * lexicalGlobalObject, CallFrame* callFrame))
{
    return IDLOperation<JSArrayBufferView>::call<jsBufferPrototypeFunction_includesBody>(*lexicalGlobalObject, *callFrame, "includes");
}

JSC_DEFINE_HOST_FUNCTION(jsBufferPrototypeFunction_indexOf, (JSGlobalObject * lexicalGlobalObject, CallFrame* callFrame))
{
    return IDLOperation<JSArrayBufferView>::call<jsBufferPrototypeFunction_indexOfBody>(*lexicalGlobalObject, *callFrame, "indexOf");
}

JSC_DEFINE_HOST_FUNCTION(jsBufferPrototypeFunction_inspect, (JSGlobalObject * lexicalGlobalObject, CallFrame* callFrame))
{
    return IDLOperation<JSArrayBufferView>::call<jsBufferPrototypeFunction_inspectBody>(*lexicalGlobalObject, *callFrame, "inspect");
}

JSC_DEFINE_HOST_FUNCTION(jsBufferPrototypeFunction_lastIndexOf, (JSGlobalObject * lexicalGlobalObject, CallFrame* callFrame))
{
    return IDLOperation<JSArrayBufferView>::call<jsBufferPrototypeFunction_lastIndexOfBody>(*lexicalGlobalObject, *callFrame, "lastIndexOf");
}

JSC_DEFINE_HOST_FUNCTION(jsBufferPrototypeFunction_swap16, (JSGlobalObject * lexicalGlobalObject, CallFrame* callFrame))
{
    return IDLOperation<JSArrayBufferView>::call<jsBufferPrototypeFunction_swap16Body>(*lexicalGlobalObject, *callFrame, "swap16");
}

JSC_DEFINE_HOST_FUNCTION(jsBufferPrototypeFunction_swap32, (JSGlobalObject * lexicalGlobalObject, CallFrame* callFrame))
{
    return IDLOperation<JSArrayBufferView>::call<jsBufferPrototypeFunction_swap32Body>(*lexicalGlobalObject, *callFrame, "swap32");
}

JSC_DEFINE_HOST_FUNCTION(jsBufferPrototypeFunction_swap64, (JSGlobalObject * lexicalGlobalObject, CallFrame* callFrame))
{
    return IDLOperation<JSArrayBufferView>::call<jsBufferPrototypeFunction_swap64Body>(*lexicalGlobalObject, *callFrame, "swap64");
}

JSC_DEFINE_HOST_FUNCTION(jsBufferPrototypeFunction_toString, (JSGlobalObject * lexicalGlobalObject, CallFrame* callFrame))
{
    return IDLOperation<JSArrayBufferView>::call<jsBufferPrototypeFunction_toStringBody>(*lexicalGlobalObject, *callFrame, "toString");
}

JSC_DEFINE_HOST_FUNCTION(jsBufferPrototypeFunction_write, (JSGlobalObject * lexicalGlobalObject, CallFrame* callFrame))
{
    return IDLOperation<JSArrayBufferView>::call<jsBufferPrototypeFunction_writeBody>(*lexicalGlobalObject, *callFrame, "write");
}

JSC_DEFINE_HOST_FUNCTION(jsBufferPrototypeFunction_utf16leWrite, (JSGlobalObject * lexicalGlobalObject, CallFrame* callFrame))
{
    return jsBufferPrototypeFunctionWriteWithEncoding<WebCore::BufferEncodingType::utf16le>(lexicalGlobalObject, callFrame);
}

JSC_DEFINE_HOST_FUNCTION(jsBufferPrototypeFunction_utf8Write, (JSGlobalObject * lexicalGlobalObject, CallFrame* callFrame))
{
    return jsBufferPrototypeFunctionWriteWithEncoding<WebCore::BufferEncodingType::utf8>(lexicalGlobalObject, callFrame);
}

JSC_DEFINE_HOST_FUNCTION(jsBufferPrototypeFunction_latin1Write, (JSGlobalObject * lexicalGlobalObject, CallFrame* callFrame))
{
    return jsBufferPrototypeFunctionWriteWithEncoding<WebCore::BufferEncodingType::latin1>(lexicalGlobalObject, callFrame);
}

JSC_DEFINE_HOST_FUNCTION(jsBufferPrototypeFunction_asciiWrite, (JSGlobalObject * lexicalGlobalObject, CallFrame* callFrame))
{
    return jsBufferPrototypeFunctionWriteWithEncoding<WebCore::BufferEncodingType::ascii>(lexicalGlobalObject, callFrame);
}

JSC_DEFINE_HOST_FUNCTION(jsBufferPrototypeFunction_base64Write, (JSGlobalObject * lexicalGlobalObject, CallFrame* callFrame))
{
    return jsBufferPrototypeFunctionWriteWithEncoding<WebCore::BufferEncodingType::base64>(lexicalGlobalObject, callFrame);
}

JSC_DEFINE_HOST_FUNCTION(jsBufferPrototypeFunction_base64urlWrite, (JSGlobalObject * lexicalGlobalObject, CallFrame* callFrame))
{
    return jsBufferPrototypeFunctionWriteWithEncoding<WebCore::BufferEncodingType::base64url>(lexicalGlobalObject, callFrame);
}

JSC_DEFINE_HOST_FUNCTION(jsBufferPrototypeFunction_hexWrite, (JSGlobalObject * lexicalGlobalObject, CallFrame* callFrame))
{
    return jsBufferPrototypeFunctionWriteWithEncoding<WebCore::BufferEncodingType::hex>(lexicalGlobalObject, callFrame);
}

JSC_DEFINE_HOST_FUNCTION(jsBufferPrototypeFunction_utf8Slice, (JSGlobalObject * lexicalGlobalObject, CallFrame* callFrame))
{
    return jsBufferPrototypeFunction_SliceWithEncoding<WebCore::BufferEncodingType::utf8>(lexicalGlobalObject, callFrame);
}

JSC_DEFINE_HOST_FUNCTION(jsBufferPrototypeFunction_utf16leSlice, (JSGlobalObject * lexicalGlobalObject, CallFrame* callFrame))
{
    return jsBufferPrototypeFunction_SliceWithEncoding<WebCore::BufferEncodingType::utf16le>(lexicalGlobalObject, callFrame);
}

JSC_DEFINE_HOST_FUNCTION(jsBufferPrototypeFunction_latin1Slice, (JSGlobalObject * lexicalGlobalObject, CallFrame* callFrame))
{
    return jsBufferPrototypeFunction_SliceWithEncoding<WebCore::BufferEncodingType::latin1>(lexicalGlobalObject, callFrame);
}

JSC_DEFINE_HOST_FUNCTION(jsBufferPrototypeFunction_asciiSlice, (JSGlobalObject * lexicalGlobalObject, CallFrame* callFrame))
{
    return jsBufferPrototypeFunction_SliceWithEncoding<WebCore::BufferEncodingType::ascii>(lexicalGlobalObject, callFrame);
}

JSC_DEFINE_HOST_FUNCTION(jsBufferPrototypeFunction_base64Slice, (JSGlobalObject * lexicalGlobalObject, CallFrame* callFrame))
{
    return jsBufferPrototypeFunction_SliceWithEncoding<WebCore::BufferEncodingType::base64>(lexicalGlobalObject, callFrame);
}

JSC_DEFINE_HOST_FUNCTION(jsBufferPrototypeFunction_base64urlSlice, (JSGlobalObject * lexicalGlobalObject, CallFrame* callFrame))
{
    return jsBufferPrototypeFunction_SliceWithEncoding<WebCore::BufferEncodingType::base64url>(lexicalGlobalObject, callFrame);
}

JSC_DEFINE_HOST_FUNCTION(jsBufferPrototypeFunction_hexSlice, (JSGlobalObject * lexicalGlobalObject, CallFrame* callFrame))
{
    return jsBufferPrototypeFunction_SliceWithEncoding<WebCore::BufferEncodingType::hex>(lexicalGlobalObject, callFrame);
}

/* */

/* Hash table for prototype */

static const HashTableValue JSBufferPrototypeTableValues[]
    = {
          { "asciiSlice"_s, static_cast<unsigned>(JSC::PropertyAttribute::Function), NoIntrinsic, { HashTableValue::NativeFunctionType, jsBufferPrototypeFunction_asciiSlice, 2 } },
          { "asciiWrite"_s, static_cast<unsigned>(JSC::PropertyAttribute::Function), NoIntrinsic, { HashTableValue::NativeFunctionType, jsBufferPrototypeFunction_asciiWrite, 3 } },
          { "base64Slice"_s, static_cast<unsigned>(JSC::PropertyAttribute::Function), NoIntrinsic, { HashTableValue::NativeFunctionType, jsBufferPrototypeFunction_base64Slice, 2 } },
          { "base64Write"_s, static_cast<unsigned>(JSC::PropertyAttribute::Function), NoIntrinsic, { HashTableValue::NativeFunctionType, jsBufferPrototypeFunction_base64Write, 3 } },
          { "base64urlSlice"_s, static_cast<unsigned>(JSC::PropertyAttribute::Function), NoIntrinsic, { HashTableValue::NativeFunctionType, jsBufferPrototypeFunction_base64urlSlice, 2 } },
          { "base64urlWrite"_s, static_cast<unsigned>(JSC::PropertyAttribute::Function), NoIntrinsic, { HashTableValue::NativeFunctionType, jsBufferPrototypeFunction_base64urlWrite, 3 } },
          { "compare"_s, static_cast<unsigned>(JSC::PropertyAttribute::Function), NoIntrinsic, { HashTableValue::NativeFunctionType, jsBufferPrototypeFunction_compare, 5 } },
          { "copy"_s, static_cast<unsigned>(JSC::PropertyAttribute::Function), NoIntrinsic, { HashTableValue::NativeFunctionType, jsBufferPrototypeFunction_copy, 4 } },
          { "equals"_s, static_cast<unsigned>(JSC::PropertyAttribute::Function), NoIntrinsic, { HashTableValue::NativeFunctionType, jsBufferPrototypeFunction_equals, 1 } },
          { "fill"_s, static_cast<unsigned>(JSC::PropertyAttribute::Function), NoIntrinsic, { HashTableValue::NativeFunctionType, jsBufferPrototypeFunction_fill, 4 } },
          { "hexSlice"_s, static_cast<unsigned>(JSC::PropertyAttribute::Function), NoIntrinsic, { HashTableValue::NativeFunctionType, jsBufferPrototypeFunction_hexSlice, 2 } },
          { "hexWrite"_s, static_cast<unsigned>(JSC::PropertyAttribute::Function), NoIntrinsic, { HashTableValue::NativeFunctionType, jsBufferPrototypeFunction_hexWrite, 3 } },
          { "includes"_s, static_cast<unsigned>(JSC::PropertyAttribute::Function), NoIntrinsic, { HashTableValue::NativeFunctionType, jsBufferPrototypeFunction_includes, 3 } },
          { "indexOf"_s, static_cast<unsigned>(JSC::PropertyAttribute::Function), NoIntrinsic, { HashTableValue::NativeFunctionType, jsBufferPrototypeFunction_indexOf, 3 } },
          { "inspect"_s, static_cast<unsigned>(JSC::PropertyAttribute::Function), NoIntrinsic, { HashTableValue::NativeFunctionType, jsBufferPrototypeFunction_inspect, 2 } },
          { "lastIndexOf"_s, static_cast<unsigned>(JSC::PropertyAttribute::Function), NoIntrinsic, { HashTableValue::NativeFunctionType, jsBufferPrototypeFunction_lastIndexOf, 3 } },
          { "latin1Slice"_s, static_cast<unsigned>(JSC::PropertyAttribute::Function), NoIntrinsic, { HashTableValue::NativeFunctionType, jsBufferPrototypeFunction_latin1Slice, 2 } },
          { "latin1Write"_s, static_cast<unsigned>(JSC::PropertyAttribute::Function), NoIntrinsic, { HashTableValue::NativeFunctionType, jsBufferPrototypeFunction_latin1Write, 3 } },
          { "offset"_s, static_cast<unsigned>(JSC::PropertyAttribute::DontEnum | JSC::PropertyAttribute::ReadOnly | JSC::PropertyAttribute::Accessor | JSC::PropertyAttribute::Builtin), NoIntrinsic, { HashTableValue::BuiltinAccessorType, jsBufferPrototypeOffsetCodeGenerator, 0 } },
          { "parent"_s, static_cast<unsigned>(JSC::PropertyAttribute::DontEnum | JSC::PropertyAttribute::ReadOnly | JSC::PropertyAttribute::Accessor | JSC::PropertyAttribute::Builtin), NoIntrinsic, { HashTableValue::BuiltinAccessorType, jsBufferPrototypeParentCodeGenerator, 0 } },
          { "readBigInt64"_s, static_cast<unsigned>(JSC::PropertyAttribute::Builtin), NoIntrinsic, { HashTableValue::BuiltinGeneratorType, jsBufferPrototypeReadBigInt64LECodeGenerator, 1 } },
          { "readBigInt64BE"_s, static_cast<unsigned>(JSC::PropertyAttribute::Builtin), NoIntrinsic, { HashTableValue::BuiltinGeneratorType, jsBufferPrototypeReadBigInt64BECodeGenerator, 1 } },
          { "readBigInt64LE"_s, static_cast<unsigned>(JSC::PropertyAttribute::Builtin), NoIntrinsic, { HashTableValue::BuiltinGeneratorType, jsBufferPrototypeReadBigInt64LECodeGenerator, 1 } },
          { "readBigUInt64"_s, static_cast<unsigned>(JSC::PropertyAttribute::Builtin), NoIntrinsic, { HashTableValue::BuiltinGeneratorType, jsBufferPrototypeReadBigUInt64LECodeGenerator, 1 } },
          { "readBigUInt64BE"_s, static_cast<unsigned>(JSC::PropertyAttribute::Builtin), NoIntrinsic, { HashTableValue::BuiltinGeneratorType, jsBufferPrototypeReadBigUInt64BECodeGenerator, 1 } },
          { "readBigUInt64LE"_s, static_cast<unsigned>(JSC::PropertyAttribute::Builtin), NoIntrinsic, { HashTableValue::BuiltinGeneratorType, jsBufferPrototypeReadBigUInt64LECodeGenerator, 1 } },
          { "readDouble"_s, static_cast<unsigned>(JSC::PropertyAttribute::Builtin), NoIntrinsic, { HashTableValue::BuiltinGeneratorType, jsBufferPrototypeReadDoubleLECodeGenerator, 1 } },
          { "readDoubleBE"_s, static_cast<unsigned>(JSC::PropertyAttribute::Builtin), NoIntrinsic, { HashTableValue::BuiltinGeneratorType, jsBufferPrototypeReadDoubleBECodeGenerator, 1 } },
          { "readDoubleLE"_s, static_cast<unsigned>(JSC::PropertyAttribute::Builtin), NoIntrinsic, { HashTableValue::BuiltinGeneratorType, jsBufferPrototypeReadDoubleLECodeGenerator, 1 } },
          { "readFloat"_s, static_cast<unsigned>(JSC::PropertyAttribute::Builtin), NoIntrinsic, { HashTableValue::BuiltinGeneratorType, jsBufferPrototypeReadFloatLECodeGenerator, 1 } },
          { "readFloatBE"_s, static_cast<unsigned>(JSC::PropertyAttribute::Builtin), NoIntrinsic, { HashTableValue::BuiltinGeneratorType, jsBufferPrototypeReadFloatBECodeGenerator, 1 } },
          { "readFloatLE"_s, static_cast<unsigned>(JSC::PropertyAttribute::Builtin), NoIntrinsic, { HashTableValue::BuiltinGeneratorType, jsBufferPrototypeReadFloatLECodeGenerator, 1 } },
          { "readInt16"_s, static_cast<unsigned>(JSC::PropertyAttribute::Builtin), NoIntrinsic, { HashTableValue::BuiltinGeneratorType, jsBufferPrototypeReadInt16LECodeGenerator, 1 } },
          { "readInt16BE"_s, static_cast<unsigned>(JSC::PropertyAttribute::Builtin), NoIntrinsic, { HashTableValue::BuiltinGeneratorType, jsBufferPrototypeReadInt16BECodeGenerator, 1 } },
          { "readInt16LE"_s, static_cast<unsigned>(JSC::PropertyAttribute::Builtin), NoIntrinsic, { HashTableValue::BuiltinGeneratorType, jsBufferPrototypeReadInt16LECodeGenerator, 1 } },
          { "readInt32"_s, static_cast<unsigned>(JSC::PropertyAttribute::Builtin), NoIntrinsic, { HashTableValue::BuiltinGeneratorType, jsBufferPrototypeReadInt32LECodeGenerator, 1 } },
          { "readInt32BE"_s, static_cast<unsigned>(JSC::PropertyAttribute::Builtin), NoIntrinsic, { HashTableValue::BuiltinGeneratorType, jsBufferPrototypeReadInt32BECodeGenerator, 1 } },
          { "readInt32LE"_s, static_cast<unsigned>(JSC::PropertyAttribute::Builtin), NoIntrinsic, { HashTableValue::BuiltinGeneratorType, jsBufferPrototypeReadInt32LECodeGenerator, 1 } },
          { "readInt8"_s, static_cast<unsigned>(JSC::PropertyAttribute::Builtin), NoIntrinsic, { HashTableValue::BuiltinGeneratorType, jsBufferPrototypeReadInt8CodeGenerator, 2 } },
          { "readIntBE"_s, static_cast<unsigned>(JSC::PropertyAttribute::Builtin), NoIntrinsic, { HashTableValue::BuiltinGeneratorType, jsBufferPrototypeReadIntBECodeGenerator, 1 } },
          { "readIntLE"_s, static_cast<unsigned>(JSC::PropertyAttribute::Builtin), NoIntrinsic, { HashTableValue::BuiltinGeneratorType, jsBufferPrototypeReadIntLECodeGenerator, 1 } },
          { "readUInt16BE"_s, static_cast<unsigned>(JSC::PropertyAttribute::Builtin), NoIntrinsic, { HashTableValue::BuiltinGeneratorType, jsBufferPrototypeReadUInt16BECodeGenerator, 1 } },
          { "readUInt16LE"_s, static_cast<unsigned>(JSC::PropertyAttribute::Builtin), NoIntrinsic, { HashTableValue::BuiltinGeneratorType, jsBufferPrototypeReadUInt16LECodeGenerator, 1 } },
          { "readUInt32BE"_s, static_cast<unsigned>(JSC::PropertyAttribute::Builtin), NoIntrinsic, { HashTableValue::BuiltinGeneratorType, jsBufferPrototypeReadUInt32BECodeGenerator, 1 } },
          { "readUInt32LE"_s, static_cast<unsigned>(JSC::PropertyAttribute::Builtin), NoIntrinsic, { HashTableValue::BuiltinGeneratorType, jsBufferPrototypeReadUInt32LECodeGenerator, 1 } },
          { "readUInt8"_s, static_cast<unsigned>(JSC::PropertyAttribute::Builtin), NoIntrinsic, { HashTableValue::BuiltinGeneratorType, jsBufferPrototypeReadUInt8CodeGenerator, 1 } },
          { "readUIntBE"_s, static_cast<unsigned>(JSC::PropertyAttribute::Builtin), NoIntrinsic, { HashTableValue::BuiltinGeneratorType, jsBufferPrototypeReadUIntBECodeGenerator, 1 } },
          { "readUIntLE"_s, static_cast<unsigned>(JSC::PropertyAttribute::Builtin), NoIntrinsic, { HashTableValue::BuiltinGeneratorType, jsBufferPrototypeReadUIntLECodeGenerator, 1 } },

          { "slice"_s, static_cast<unsigned>(JSC::PropertyAttribute::Builtin), NoIntrinsic, { HashTableValue::BuiltinGeneratorType, jsBufferPrototypeSliceCodeGenerator, 2 } },
          { "subarray"_s, static_cast<unsigned>(JSC::PropertyAttribute::Builtin), NoIntrinsic, { HashTableValue::BuiltinGeneratorType, jsBufferPrototypeSliceCodeGenerator, 2 } },
          { "swap16"_s, static_cast<unsigned>(JSC::PropertyAttribute::Function), NoIntrinsic, { HashTableValue::NativeFunctionType, jsBufferPrototypeFunction_swap16, 0 } },
          { "swap32"_s, static_cast<unsigned>(JSC::PropertyAttribute::Function), NoIntrinsic, { HashTableValue::NativeFunctionType, jsBufferPrototypeFunction_swap32, 0 } },
          { "swap64"_s, static_cast<unsigned>(JSC::PropertyAttribute::Function), NoIntrinsic, { HashTableValue::NativeFunctionType, jsBufferPrototypeFunction_swap64, 0 } },
          { "toJSON"_s, static_cast<unsigned>(JSC::PropertyAttribute::Builtin), NoIntrinsic, { HashTableValue::BuiltinGeneratorType, jsBufferPrototypeToJSONCodeGenerator, 1 } },
          { "toLocaleString"_s, static_cast<unsigned>(JSC::PropertyAttribute::Function), NoIntrinsic, { HashTableValue::NativeFunctionType, jsBufferPrototypeFunction_toString, 4 } },
          { "toString"_s, static_cast<unsigned>(JSC::PropertyAttribute::Function), NoIntrinsic, { HashTableValue::NativeFunctionType, jsBufferPrototypeFunction_toString, 4 } },
          { "ucs2Slice"_s, static_cast<unsigned>(JSC::PropertyAttribute::Function), NoIntrinsic, { HashTableValue::NativeFunctionType, jsBufferPrototypeFunction_utf16leSlice, 2 } },
          { "ucs2Write"_s, static_cast<unsigned>(JSC::PropertyAttribute::Function), NoIntrinsic, { HashTableValue::NativeFunctionType, jsBufferPrototypeFunction_utf16leWrite, 3 } },
          { "utf16leSlice"_s, static_cast<unsigned>(JSC::PropertyAttribute::Function), NoIntrinsic, { HashTableValue::NativeFunctionType, jsBufferPrototypeFunction_utf16leSlice, 2 } },
          { "utf16leWrite"_s, static_cast<unsigned>(JSC::PropertyAttribute::Function), NoIntrinsic, { HashTableValue::NativeFunctionType, jsBufferPrototypeFunction_utf16leWrite, 3 } },
          { "utf8Slice"_s, static_cast<unsigned>(JSC::PropertyAttribute::Function), NoIntrinsic, { HashTableValue::NativeFunctionType, jsBufferPrototypeFunction_utf8Slice, 2 } },
          { "utf8Write"_s, static_cast<unsigned>(JSC::PropertyAttribute::Function), NoIntrinsic, { HashTableValue::NativeFunctionType, jsBufferPrototypeFunction_utf8Write, 3 } },
          { "write"_s, static_cast<unsigned>(JSC::PropertyAttribute::Function), NoIntrinsic, { HashTableValue::NativeFunctionType, jsBufferPrototypeFunction_write, 4 } },
          { "writeBigInt64BE"_s, static_cast<unsigned>(JSC::PropertyAttribute::Builtin), NoIntrinsic, { HashTableValue::BuiltinGeneratorType, jsBufferPrototypeWriteBigInt64BECodeGenerator, 1 } },
          { "writeBigInt64LE"_s, static_cast<unsigned>(JSC::PropertyAttribute::Builtin), NoIntrinsic, { HashTableValue::BuiltinGeneratorType, jsBufferPrototypeWriteBigInt64LECodeGenerator, 1 } },
          { "writeBigUInt64BE"_s, static_cast<unsigned>(JSC::PropertyAttribute::Builtin), NoIntrinsic, { HashTableValue::BuiltinGeneratorType, jsBufferPrototypeWriteBigUInt64BECodeGenerator, 1 } },
          { "writeBigUInt64LE"_s, static_cast<unsigned>(JSC::PropertyAttribute::Builtin), NoIntrinsic, { HashTableValue::BuiltinGeneratorType, jsBufferPrototypeWriteBigUInt64LECodeGenerator, 1 } },
          { "writeDouble"_s, static_cast<unsigned>(JSC::PropertyAttribute::Builtin), NoIntrinsic, { HashTableValue::BuiltinGeneratorType, jsBufferPrototypeWriteDoubleLECodeGenerator, 1 } },
          { "writeDoubleBE"_s, static_cast<unsigned>(JSC::PropertyAttribute::Builtin), NoIntrinsic, { HashTableValue::BuiltinGeneratorType, jsBufferPrototypeWriteDoubleBECodeGenerator, 1 } },
          { "writeDoubleLE"_s, static_cast<unsigned>(JSC::PropertyAttribute::Builtin), NoIntrinsic, { HashTableValue::BuiltinGeneratorType, jsBufferPrototypeWriteDoubleLECodeGenerator, 1 } },
          { "writeFloat"_s, static_cast<unsigned>(JSC::PropertyAttribute::Builtin), NoIntrinsic, { HashTableValue::BuiltinGeneratorType, jsBufferPrototypeWriteFloatLECodeGenerator, 1 } },
          { "writeFloatBE"_s, static_cast<unsigned>(JSC::PropertyAttribute::Builtin), NoIntrinsic, { HashTableValue::BuiltinGeneratorType, jsBufferPrototypeWriteFloatBECodeGenerator, 1 } },
          { "writeFloatLE"_s, static_cast<unsigned>(JSC::PropertyAttribute::Builtin), NoIntrinsic, { HashTableValue::BuiltinGeneratorType, jsBufferPrototypeWriteFloatLECodeGenerator, 1 } },
          { "writeInt16BE"_s, static_cast<unsigned>(JSC::PropertyAttribute::Builtin), NoIntrinsic, { HashTableValue::BuiltinGeneratorType, jsBufferPrototypeWriteInt16BECodeGenerator, 1 } },
          { "writeInt16LE"_s, static_cast<unsigned>(JSC::PropertyAttribute::Builtin), NoIntrinsic, { HashTableValue::BuiltinGeneratorType, jsBufferPrototypeWriteInt16LECodeGenerator, 1 } },
          { "writeInt32BE"_s, static_cast<unsigned>(JSC::PropertyAttribute::Builtin), NoIntrinsic, { HashTableValue::BuiltinGeneratorType, jsBufferPrototypeWriteInt32BECodeGenerator, 1 } },
          { "writeInt32LE"_s, static_cast<unsigned>(JSC::PropertyAttribute::Builtin), NoIntrinsic, { HashTableValue::BuiltinGeneratorType, jsBufferPrototypeWriteInt32LECodeGenerator, 1 } },
          { "writeInt8"_s, static_cast<unsigned>(JSC::PropertyAttribute::Builtin), NoIntrinsic, { HashTableValue::BuiltinGeneratorType, jsBufferPrototypeWriteInt8CodeGenerator, 1 } },
          { "writeIntBE"_s, static_cast<unsigned>(JSC::PropertyAttribute::Builtin), NoIntrinsic, { HashTableValue::BuiltinGeneratorType, jsBufferPrototypeWriteIntBECodeGenerator, 1 } },
          { "writeIntLE"_s, static_cast<unsigned>(JSC::PropertyAttribute::Builtin), NoIntrinsic, { HashTableValue::BuiltinGeneratorType, jsBufferPrototypeWriteIntLECodeGenerator, 1 } },
          { "writeUInt16"_s, static_cast<unsigned>(JSC::PropertyAttribute::Builtin), NoIntrinsic, { HashTableValue::BuiltinGeneratorType, jsBufferPrototypeWriteUInt16LECodeGenerator, 1 } },
          { "writeUInt16BE"_s, static_cast<unsigned>(JSC::PropertyAttribute::Builtin), NoIntrinsic, { HashTableValue::BuiltinGeneratorType, jsBufferPrototypeWriteUInt16BECodeGenerator, 1 } },
          { "writeUInt16LE"_s, static_cast<unsigned>(JSC::PropertyAttribute::Builtin), NoIntrinsic, { HashTableValue::BuiltinGeneratorType, jsBufferPrototypeWriteUInt16LECodeGenerator, 1 } },
          { "writeUInt32"_s, static_cast<unsigned>(JSC::PropertyAttribute::Builtin), NoIntrinsic, { HashTableValue::BuiltinGeneratorType, jsBufferPrototypeWriteUInt32LECodeGenerator, 1 } },
          { "writeUInt32BE"_s, static_cast<unsigned>(JSC::PropertyAttribute::Builtin), NoIntrinsic, { HashTableValue::BuiltinGeneratorType, jsBufferPrototypeWriteUInt32BECodeGenerator, 1 } },
          { "writeUInt32LE"_s, static_cast<unsigned>(JSC::PropertyAttribute::Builtin), NoIntrinsic, { HashTableValue::BuiltinGeneratorType, jsBufferPrototypeWriteUInt32LECodeGenerator, 1 } },
          { "writeUInt8"_s, static_cast<unsigned>(JSC::PropertyAttribute::Builtin), NoIntrinsic, { HashTableValue::BuiltinGeneratorType, jsBufferPrototypeWriteUInt8CodeGenerator, 1 } },
          { "writeUIntBE"_s, static_cast<unsigned>(JSC::PropertyAttribute::Builtin), NoIntrinsic, { HashTableValue::BuiltinGeneratorType, jsBufferPrototypeWriteUIntBECodeGenerator, 1 } },
          { "writeUIntLE"_s, static_cast<unsigned>(JSC::PropertyAttribute::Builtin), NoIntrinsic, { HashTableValue::BuiltinGeneratorType, jsBufferPrototypeWriteUIntLECodeGenerator, 1 } },
      };

// TODO: add this as a feature to the hash table generator mechanism above so that we can avoid all the unnecessary extra calls to `Identifier::fromString` and `this->getDirect`.
#define ALIAS(to, from)                                                                          \
    do {                                                                                         \
        auto original_ident = Identifier::fromString(vm, ASCIILiteral::fromLiteralUnsafe(from)); \
        auto original = this->getDirect(vm, original_ident);                                     \
        auto alias_ident = Identifier::fromString(vm, ASCIILiteral::fromLiteralUnsafe(to));      \
        this->putDirect(vm, alias_ident, original, PropertyAttribute::Builtin | 0);              \
    } while (false);

void JSBufferPrototype::finishCreation(VM& vm, JSC::JSGlobalObject* globalThis)
{
    Base::finishCreation(vm);
    JSC_TO_STRING_TAG_WITHOUT_TRANSITION();
    reifyStaticProperties(vm, JSBuffer::info(), JSBufferPrototypeTableValues, *this);

    ALIAS("toLocaleString", "toString");

    ALIAS("readUintBE", "readUIntBE");
    ALIAS("readUintLE", "readUIntLE");
    ALIAS("readUint8", "readUInt8");
    ALIAS("readUint16BE", "readUInt16BE");
    ALIAS("readUint16LE", "readUInt16LE");
    ALIAS("readUint32BE", "readUInt32BE");
    ALIAS("readUint32LE", "readUInt32LE");
    ALIAS("readBigUint64BE", "readBigUInt64BE");
    ALIAS("readBigUint64LE", "readBigUInt64LE");

    ALIAS("writeUintBE", "writeUIntBE");
    ALIAS("writeUintLE", "writeUIntLE");
    ALIAS("writeUint8", "writeUInt8");
    ALIAS("writeUint16", "writeUInt16");
    ALIAS("writeUint16BE", "writeUInt16BE");
    ALIAS("writeUint16LE", "writeUInt16LE");
    ALIAS("writeUint32", "writeUInt32");
    ALIAS("writeUint32BE", "writeUInt32BE");
    ALIAS("writeUint32LE", "writeUInt32LE");
    ALIAS("writeBigUint64BE", "writeBigUInt64BE");
    ALIAS("writeBigUint64LE", "writeBigUInt64LE");

    this->putDirect(vm, Identifier::fromUid(vm.symbolRegistry().symbolForKey("nodejs.util.inspect.custom"_s)), this->getDirect(vm, Identifier::fromString(vm, "inspect"_s)), PropertyAttribute::Builtin | 0);
}

const ClassInfo JSBufferPrototype::s_info = {
    // In Node.js, Object.prototype.toString.call(new Buffer(0)) returns "[object Uint8Array]".
    // We must use the same naming convention to match Node
    // Some packages (like MongoDB's official Node.js client) rely on this behavior.
    "Uint8Array"_s,
    &Base::s_info, nullptr, nullptr, CREATE_METHOD_TABLE(JSBufferPrototype)
};

/* Source for JSBuffer.lut.h
@begin jsBufferConstructorTable
    alloc           jsBufferConstructorFunction_alloc              Constructable|Function 1
    allocUnsafe     jsBufferConstructorFunction_allocUnsafe        Constructable|Function 1
    allocUnsafeSlow jsBufferConstructorFunction_allocUnsafeSlow    Constructable|Function 1
    byteLength      jsBufferConstructorFunction_byteLength         Function 2
    compare         jsBufferConstructorFunction_compare            Function 2
    concat          jsBufferConstructorFunction_concat             Function 2
    copyBytesFrom   jsBufferConstructorFunction_copyBytesFrom      Function 1
    from            JSBuiltin                                      Builtin|Function 1
    isBuffer        JSBuiltin                                      Builtin|Function 1
    isEncoding      jsBufferConstructorFunction_isEncoding         Function 1
@end
*/
#include "JSBuffer.lut.h"

const ClassInfo JSBufferConstructor::s_info = { "Buffer"_s, &Base::s_info, &jsBufferConstructorTable, nullptr, CREATE_METHOD_TABLE(JSBufferConstructor) };

void JSBufferConstructor::finishCreation(VM& vm, JSGlobalObject* globalObject, JSC::JSObject* prototype)
{
    Base::finishCreation(vm, 3, "Buffer"_s, PropertyAdditionMode::WithoutStructureTransition);
    putDirectWithoutTransition(vm, vm.propertyNames->prototype, prototype, PropertyAttribute::DontEnum | PropertyAttribute::DontDelete | PropertyAttribute::ReadOnly);
    prototype->putDirect(vm, vm.propertyNames->speciesSymbol, this, PropertyAttribute::DontDelete | PropertyAttribute::ReadOnly);
    putDirectWithoutTransition(vm, Identifier::fromString(vm, "poolSize"_s), jsNumber(8192));
}

JSC::Structure* createBufferStructure(JSC::VM& vm, JSC::JSGlobalObject* globalObject, JSC::JSValue prototype)
{
    return JSBuffer::createStructure(vm, globalObject, prototype);
}

JSC::JSObject* createBufferPrototype(JSC::VM& vm, JSC::JSGlobalObject* globalObject)
{
    return JSBufferPrototype::create(vm, globalObject, JSBufferPrototype::createStructure(vm, globalObject, globalObject->m_typedArrayUint8.prototype(globalObject)));
}

JSC::JSObject* createBufferConstructor(JSC::VM& vm, JSC::JSGlobalObject* globalObject, JSC::JSObject* bufferPrototype)
{
    return JSBufferConstructor::create(
        vm,
        globalObject,
        JSBufferConstructor::createStructure(vm, globalObject),
        bufferPrototype);
}

} // namespace WebCore

EncodedJSValue constructBufferFromArray(JSC::ThrowScope& throwScope, JSGlobalObject* lexicalGlobalObject, JSValue arrayValue)
{
    auto* globalObject = defaultGlobalObject(lexicalGlobalObject);

    auto* constructor = lexicalGlobalObject->m_typedArrayUint8.constructor(lexicalGlobalObject);
    MarkedArgumentBuffer argsBuffer;
    argsBuffer.append(arrayValue);
    JSValue target = globalObject->JSBufferConstructor();
    // TODO: I wish we could avoid this - it adds ~30ns of overhead just using JSC::construct.
    auto* object = JSC::construct(lexicalGlobalObject, constructor, target, argsBuffer, "Buffer failed to construct"_s);
    RETURN_IF_EXCEPTION(throwScope, {});
    RELEASE_AND_RETURN(throwScope, JSC::JSValue::encode(object));
}

EncodedJSValue constructBufferFromArrayBuffer(JSC::ThrowScope& throwScope, JSGlobalObject* lexicalGlobalObject, size_t argsCount, JSValue arrayBufferValue, JSValue offsetValue, JSValue lengthValue)
{
    auto* globalObject = defaultGlobalObject(lexicalGlobalObject);

    auto* jsBuffer = jsCast<JSC::JSArrayBuffer*>(arrayBufferValue.asCell());
    RefPtr<ArrayBuffer> buffer = jsBuffer->impl();
    if (buffer->isDetached()) {
        return throwVMTypeError(globalObject, throwScope, "Buffer is detached"_s);
    }
    size_t byteLength = buffer->byteLength();
    size_t offset = 0;
    size_t length = byteLength;

    if (!offsetValue.isUndefined()) {
        double offsetD = offsetValue.toNumber(lexicalGlobalObject);
        RETURN_IF_EXCEPTION(throwScope, {});
        if (std::isnan(offsetD)) offsetD = 0;
        offset = offsetD;
        if (offset > byteLength) return Bun::ERR::BUFFER_OUT_OF_BOUNDS(throwScope, lexicalGlobalObject, "offset"_s);
        length -= offset;
    }

    if (!lengthValue.isUndefined()) {
        double lengthD = lengthValue.toNumber(lexicalGlobalObject);
        RETURN_IF_EXCEPTION(throwScope, {});
        if (std::isnan(lengthD)) lengthD = 0;
        length = lengthD;
        if (length > byteLength - offset) return Bun::ERR::BUFFER_OUT_OF_BOUNDS(throwScope, lexicalGlobalObject, "length"_s);
    }

    auto* subclassStructure = globalObject->JSBufferSubclassStructure();
    auto* uint8Array = JSC::JSUint8Array::create(lexicalGlobalObject, subclassStructure, WTFMove(buffer), offset, length);
    if (UNLIKELY(!uint8Array)) {
        throwOutOfMemoryError(globalObject, throwScope);
        return {};
    }

    RELEASE_AND_RETURN(throwScope, JSC::JSValue::encode(uint8Array));
}

static inline JSC::EncodedJSValue createJSBufferFromJS(JSC::JSGlobalObject* lexicalGlobalObject, JSValue newTarget, ArgList args)
{
    auto& vm = JSC::getVM(lexicalGlobalObject);
    auto throwScope = DECLARE_THROW_SCOPE(vm);

    size_t argsCount = args.size();
    if (argsCount == 0) {
        RELEASE_AND_RETURN(throwScope, constructBufferEmpty(lexicalGlobalObject));
    }
    JSValue distinguishingArg = args.at(0);
    JSValue encodingArg = argsCount > 1 ? args.at(1) : JSValue();
    auto* globalObject = defaultGlobalObject(lexicalGlobalObject);
    if (distinguishingArg.isAnyInt()) {
        throwScope.release();
        if (args.at(1).isString()) {
            return Bun::ERR::INVALID_ARG_TYPE(throwScope, lexicalGlobalObject, "string"_s, "string"_s, distinguishingArg);
        }
        auto anyint = distinguishingArg.asAnyInt();
        if (anyint < 0 or anyint > Bun::Buffer::kMaxLength) return Bun::ERR::OUT_OF_RANGE(throwScope, lexicalGlobalObject, "size"_s, 0, Bun::Buffer::kMaxLength, distinguishingArg);
        return JSValue::encode(allocBuffer(lexicalGlobalObject, anyint));
    } else if (distinguishingArg.isNumber()) {
        JSValue lengthValue = distinguishingArg;
        Bun::V::validateNumber(throwScope, lexicalGlobalObject, lengthValue, "size"_s, jsNumber(0), jsNumber(Bun::Buffer::kMaxLength));
        RETURN_IF_EXCEPTION(throwScope, {});
        size_t length = lengthValue.toLength(lexicalGlobalObject);
        return JSValue::encode(allocBuffer(lexicalGlobalObject, length));
    } else if (distinguishingArg.isUndefinedOrNull() || distinguishingArg.isBoolean()) {
        auto arg_string = distinguishingArg.toWTFString(globalObject);
        auto message = makeString("The first argument must be of type string or an instance of Buffer, ArrayBuffer, Array or an Array-like object. Received "_s, arg_string);
        return throwVMTypeError(globalObject, throwScope, message);
    } else if (distinguishingArg.isCell()) {
        auto type = distinguishingArg.asCell()->type();
        switch (type) {
        case StringType:
        case StringObjectType:
        case DerivedStringObjectType: {
            throwScope.release();
            return constructBufferFromStringAndEncoding(lexicalGlobalObject, distinguishingArg, encodingArg);
        }
        case Uint16ArrayType:
        case Uint32ArrayType:
        case Int8ArrayType:
        case Int16ArrayType:
        case Int32ArrayType:
        case Float16ArrayType:
        case Float32ArrayType:
        case Float64ArrayType:
        case BigInt64ArrayType:
        case BigUint64ArrayType: {
            // byteOffset and byteLength are ignored in this case, which is consitent with Node.js and new Uint8Array()
            JSC::JSArrayBufferView* view = jsCast<JSC::JSArrayBufferView*>(distinguishingArg.asCell());
            void* data = view->vector();
            size_t byteLength = view->length();
            if (UNLIKELY(!data)) {
                throwException(globalObject, throwScope, createRangeError(globalObject, "Buffer is detached"_s));
                return {};
            }
            auto* uint8Array = createUninitializedBuffer(lexicalGlobalObject, byteLength);
            if (UNLIKELY(!uint8Array)) {
                ASSERT(throwScope.exception());
                return {};
            }
            if (byteLength) {
                uint8Array->setFromTypedArray(lexicalGlobalObject, 0, view, 0, byteLength, CopyType::LeftToRight);
            }
            RELEASE_AND_RETURN(throwScope, JSC::JSValue::encode(uint8Array));
            break;
        }
        case DataViewType:
        case Uint8ArrayType:
        case Uint8ClampedArrayType: {
            // byteOffset and byteLength are ignored in this case, which is consitent with Node.js and new Uint8Array()
            JSC::JSArrayBufferView* view = jsCast<JSC::JSArrayBufferView*>(distinguishingArg.asCell());
            void* data = view->vector();
            size_t byteLength = view->byteLength();
            if (UNLIKELY(!data)) {
                throwException(globalObject, throwScope, createRangeError(globalObject, "Buffer is detached"_s));
                return {};
            }
            auto* uint8Array = createBuffer(lexicalGlobalObject, static_cast<uint8_t*>(data), byteLength);
            RELEASE_AND_RETURN(throwScope, JSC::JSValue::encode(uint8Array));
        }
        case ArrayBufferType: {
            // This closely matches `new Uint8Array(buffer, byteOffset, length)` in JavaScriptCore's implementation.
            // See Source/JavaScriptCore/runtime/JSGenericTypedArrayViewConstructorInlines.h
            return constructBufferFromArrayBuffer(throwScope, lexicalGlobalObject, args.size(), distinguishingArg, args.at(1), args.at(2));
        }
        default: {
            break;
        }
        }
    }

    return constructBufferFromArray(throwScope, lexicalGlobalObject, distinguishingArg);
}
JSC_DEFINE_HOST_FUNCTION(callJSBuffer, (JSC::JSGlobalObject * lexicalGlobalObject, JSC::CallFrame* callFrame))
{
    return createJSBufferFromJS(lexicalGlobalObject, callFrame->thisValue(), ArgList(callFrame));
}

JSC_DEFINE_HOST_FUNCTION(constructJSBuffer, (JSC::JSGlobalObject * lexicalGlobalObject, JSC::CallFrame* callFrame))
{
    return createJSBufferFromJS(lexicalGlobalObject, callFrame->newTarget(), ArgList(callFrame));
}

bool JSBuffer__isBuffer(JSC::JSGlobalObject* lexicalGlobalObject, JSC::EncodedJSValue value)
{
    auto& vm = JSC::getVM(lexicalGlobalObject);

    JSC::JSValue jsValue = JSC::JSValue::decode(value);
    if (!jsValue || !jsValue.isCell())
        return false;

    JSC::JSUint8Array* cell = jsDynamicCast<JSC::JSUint8Array*>(jsValue.asCell());
    if (!cell)
        return false;

    JSValue prototype = cell->getPrototype(vm, lexicalGlobalObject);
    return prototype.inherits<WebCore::JSBufferPrototype>();
}
