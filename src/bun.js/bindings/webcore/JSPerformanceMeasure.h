/*
    This file is part of the WebKit open source project.
    This file has been generated by generate-bindings.pl. DO NOT MODIFY!

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Library General Public
    License as published by the Free Software Foundation; either
    version 2 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Library General Public License for more details.

    You should have received a copy of the GNU Library General Public License
    along with this library; see the file COPYING.LIB.  If not, write to
    the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
    Boston, MA 02110-1301, USA.
*/

#pragma once

#include "JSDOMWrapper.h"
#include "JSPerformanceEntry.h"
#include "PerformanceMeasure.h"

namespace WebCore {

class JSPerformanceMeasure : public JSPerformanceEntry {
public:
    using Base = JSPerformanceEntry;
    using DOMWrapped = PerformanceMeasure;
    static JSPerformanceMeasure* create(JSC::Structure* structure, JSDOMGlobalObject* globalObject, Ref<PerformanceMeasure>&& impl)
    {
        JSPerformanceMeasure* ptr = new (NotNull, JSC::allocateCell<JSPerformanceMeasure>(globalObject->vm())) JSPerformanceMeasure(structure, *globalObject, WTFMove(impl));
        ptr->finishCreation(globalObject->vm());
        return ptr;
    }

    static JSC::JSObject* createPrototype(JSC::VM&, JSDOMGlobalObject&);
    static JSC::JSObject* prototype(JSC::VM&, JSDOMGlobalObject&);

    DECLARE_INFO;

    static JSC::Structure* createStructure(JSC::VM& vm, JSC::JSGlobalObject* globalObject, JSC::JSValue prototype)
    {
        return JSC::Structure::create(vm, globalObject, prototype, JSC::TypeInfo(JSC::ObjectType, StructureFlags), info(), JSC::NonArray);
    }

    static JSC::JSValue getConstructor(JSC::VM&, const JSC::JSGlobalObject*);
    mutable JSC::WriteBarrier<JSC::Unknown> m_detail;
    template<typename, JSC::SubspaceAccess mode> static JSC::GCClient::IsoSubspace* subspaceFor(JSC::VM& vm)
    {
        if constexpr (mode == JSC::SubspaceAccess::Concurrently)
            return nullptr;
        return subspaceForImpl(vm);
    }
    static JSC::GCClient::IsoSubspace* subspaceForImpl(JSC::VM& vm);
    DECLARE_VISIT_CHILDREN;

    static void analyzeHeap(JSCell*, JSC::HeapAnalyzer&);
    PerformanceMeasure& wrapped() const
    {
        return static_cast<PerformanceMeasure&>(Base::wrapped());
    }

protected:
    JSPerformanceMeasure(JSC::Structure*, JSDOMGlobalObject&, Ref<PerformanceMeasure>&&);

    DECLARE_DEFAULT_FINISH_CREATION;
};

template<> struct JSDOMWrapperConverterTraits<PerformanceMeasure> {
    using WrapperClass = JSPerformanceMeasure;
    using ToWrappedReturnType = PerformanceMeasure*;
};

} // namespace WebCore
