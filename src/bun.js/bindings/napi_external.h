#pragma once

#include "root.h"

#include "BunBuiltinNames.h"
#include "BunClientData.h"
#include "napi.h"

namespace Bun {

using namespace JSC;
using namespace WebCore;

typedef struct {
    /// The result of call to dlopen to load the module
    void* dlopenHandle;
} NapiModuleMeta;

class NapiExternal : public JSC::JSDestructibleObject {
    using Base = JSC::JSDestructibleObject;

public:
    NapiExternal(JSC::VM& vm, JSC::Structure* structure)
        : Base(vm, structure)
    {
    }

    DECLARE_EXPORT_INFO;

    static constexpr unsigned StructureFlags = Base::StructureFlags;

    template<typename, JSC::SubspaceAccess mode> static JSC::GCClient::IsoSubspace* subspaceFor(JSC::VM& vm)
    {
        if constexpr (mode == JSC::SubspaceAccess::Concurrently)
            return nullptr;

        return WebCore::subspaceForImpl<NapiExternal, UseCustomHeapCellType::No>(
            vm,
            [](auto& spaces) { return spaces.m_clientSubspaceForNapiExternal.get(); },
            [](auto& spaces, auto&& space) { spaces.m_clientSubspaceForNapiExternal = std::forward<decltype(space)>(space); },
            [](auto& spaces) { return spaces.m_subspaceForNapiExternal.get(); },
            [](auto& spaces, auto&& space) { spaces.m_subspaceForNapiExternal = std::forward<decltype(space)>(space); });
    }

    ~NapiExternal();

    static JSC::Structure* createStructure(JSC::VM& vm, JSC::JSGlobalObject* globalObject,
        JSC::JSValue prototype)
    {
        return JSC::Structure::create(vm, globalObject, prototype,
            JSC::TypeInfo(JSC::ObjectType, StructureFlags), info());
    }

    // env is needed only if a finalizer is passed, otherwise it may be null
    static NapiExternal* create(JSC::VM& vm, JSC::Structure* structure, void* value, void* finalizer_hint, napi_env env, void* finalizer)
    {
        NapiExternal* accessor = new (NotNull, JSC::allocateCell<NapiExternal>(vm)) NapiExternal(vm, structure);

        accessor->finishCreation(vm, value, finalizer_hint, env, finalizer);

#if BUN_DEBUG
        if (auto* callFrame = vm.topCallFrame) {
            auto origin = callFrame->callerSourceOrigin(vm);
            accessor->sourceOriginURL = origin.string();

            std::unique_ptr<Vector<StackFrame>> stackTrace = makeUnique<Vector<StackFrame>>();
            vm.interpreter.getStackTrace(accessor, *stackTrace, 0, 20);
            if (!stackTrace->isEmpty()) {
                for (auto& frame : *stackTrace) {
                    if (frame.hasLineAndColumnInfo()) {
                        LineColumn lineColumn = frame.computeLineAndColumn();
                        accessor->sourceOriginLine = lineColumn.line;
                        accessor->sourceOriginColumn = lineColumn.column;
                        break;
                    }
                }
            }
        }
#endif
        return accessor;
    }

    void finishCreation(JSC::VM& vm, void* value, void* finalizer_hint, napi_env env, void* finalizer)
    {
        Base::finishCreation(vm);
        m_value = value;
        m_finalizerHint = finalizer_hint;
        m_env = env;
        m_finalizer = finalizer;
    }

    static void destroy(JSC::JSCell* cell);

    void* value() const { return m_value; }

    void* m_value = nullptr;
    void* m_finalizerHint = nullptr;
    void* m_finalizer = nullptr;
    napi_env m_env = nullptr;

#if BUN_DEBUG
    String sourceOriginURL = String();
    unsigned sourceOriginLine = 0;
    unsigned sourceOriginColumn = 0;
#endif
};

} // namespace Zig
