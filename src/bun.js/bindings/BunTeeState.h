#include "root.h"

#include <JavaScriptCore/JSObject.h>
#include <JavaScriptCore/JSObjectInlines.h>
#include <JavaScriptCore/JSPromise.h>
#include <JavaScriptCore/JSFunction.h>

namespace Bun {

// Prefer forward declarations over including headers, to save compile time
class JSReadableStream;
class JSReadableStreamDefaultReader;

using namespace JSC;

class TeeState final : public JSC::JSCell {
public:
    using Base = JSC::JSCell;

    static TeeState* create(VM&, JSGlobalObject*, JSReadableStreamDefaultReader*, JSReadableStream* branch1, JSReadableStream* branch2);
    static Structure* createStructure(VM&, JSGlobalObject*);

    template<typename, JSC::SubspaceAccess mode>
    static JSC::GCClient::IsoSubspace* subspaceFor(JSC::VM& vm)
    {
        if constexpr (mode == JSC::SubspaceAccess::Concurrently)
            return nullptr;
        return subspaceForImpl(vm);
    }
    static JSC::GCClient::IsoSubspace* subspaceForImpl(JSC::VM& vm);

    DECLARE_INFO;
    DECLARE_VISIT_CHILDREN;

    void perform(VM&, JSGlobalObject*); // Start the tee operation

    void pullAlgorithmFulfill(VM&, JSGlobalObject*, JSValue result);
    void pullAlgorithmReject(VM&, JSGlobalObject*, JSValue error);
    void finishCreation(VM&, JSReadableStreamDefaultReader*, JSReadableStream* branch1, JSReadableStream* branch2);

private:
    TeeState(VM&, Structure*);

    void finishCreation(VM&);

    // Called when either branch is canceled
    JSC::JSPromise* cancel(VM&, JSGlobalObject*, JSReadableStream* canceledBranch, JSValue reason);
    void pullAlgorithm(VM&, JSGlobalObject*);

    mutable JSC::WriteBarrier<JSReadableStreamDefaultReader> m_reader;
    mutable JSC::WriteBarrier<JSReadableStream> m_branch1;
    mutable JSC::WriteBarrier<JSReadableStream> m_branch2;
    mutable JSC::WriteBarrier<JSC::Unknown> m_reason1;
    mutable JSC::WriteBarrier<JSC::Unknown> m_reason2;
    mutable JSC::WriteBarrier<JSC::JSPromise> m_cancelPromise;
    mutable JSC::WriteBarrier<JSFunction> m_cancelPromiseResolve;
    mutable JSC::WriteBarrier<JSFunction> m_cancelPromiseReject;
    bool m_canceled1 { false };
    bool m_canceled2 { false };
    bool m_closedOrErrored { false };
    bool m_pullInProgress { false };
};

}
