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

#include "config.h"
#include "JSPerformanceServerTiming.h"

#include "ActiveDOMObject.h"
#include "ExtendedDOMClientIsoSubspaces.h"
#include "ExtendedDOMIsoSubspaces.h"
#include "JSDOMAttribute.h"
#include "JSDOMBinding.h"
#include "JSDOMConstructorNotConstructable.h"
#include "JSDOMConvertNumbers.h"
#include "JSDOMConvertStrings.h"
#include "JSDOMExceptionHandling.h"
#include "JSDOMGlobalObjectInlines.h"
#include "JSDOMOperation.h"
#include "JSDOMWrapperCache.h"
#include "ScriptExecutionContext.h"
#include "WebCoreJSClientData.h"
#include <JavaScriptCore/FunctionPrototype.h>
#include <JavaScriptCore/HeapAnalyzer.h>
#include <JavaScriptCore/JSCInlines.h>
#include <JavaScriptCore/JSDestructibleObjectHeapCellType.h>
#include <JavaScriptCore/ObjectConstructor.h>
#include <JavaScriptCore/SlotVisitorMacros.h>
#include <JavaScriptCore/SubspaceInlines.h>
#include <wtf/GetPtr.h>
#include <wtf/PointerPreparations.h>
#include <wtf/URL.h>

namespace WebCore {
using namespace JSC;

// Functions

static JSC_DECLARE_HOST_FUNCTION(jsPerformanceServerTimingPrototypeFunction_toJSON);

// Attributes

static JSC_DECLARE_CUSTOM_GETTER(jsPerformanceServerTimingConstructor);
static JSC_DECLARE_CUSTOM_GETTER(jsPerformanceServerTiming_name);
static JSC_DECLARE_CUSTOM_GETTER(jsPerformanceServerTiming_duration);
static JSC_DECLARE_CUSTOM_GETTER(jsPerformanceServerTiming_description);

class JSPerformanceServerTimingPrototype final : public JSC::JSNonFinalObject {
public:
    using Base = JSC::JSNonFinalObject;
    static JSPerformanceServerTimingPrototype* create(JSC::VM& vm, JSDOMGlobalObject* globalObject, JSC::Structure* structure)
    {
        JSPerformanceServerTimingPrototype* ptr = new (NotNull, JSC::allocateCell<JSPerformanceServerTimingPrototype>(vm)) JSPerformanceServerTimingPrototype(vm, globalObject, structure);
        ptr->finishCreation(vm);
        return ptr;
    }

    DECLARE_INFO;
    template<typename CellType, JSC::SubspaceAccess>
    static JSC::GCClient::IsoSubspace* subspaceFor(JSC::VM& vm)
    {
        STATIC_ASSERT_ISO_SUBSPACE_SHARABLE(JSPerformanceServerTimingPrototype, Base);
        return &vm.plainObjectSpace();
    }
    static JSC::Structure* createStructure(JSC::VM& vm, JSC::JSGlobalObject* globalObject, JSC::JSValue prototype)
    {
        return JSC::Structure::create(vm, globalObject, prototype, JSC::TypeInfo(JSC::ObjectType, StructureFlags), info());
    }

private:
    JSPerformanceServerTimingPrototype(JSC::VM& vm, JSC::JSGlobalObject*, JSC::Structure* structure)
        : JSC::JSNonFinalObject(vm, structure)
    {
    }

    void finishCreation(JSC::VM&);
};
STATIC_ASSERT_ISO_SUBSPACE_SHARABLE(JSPerformanceServerTimingPrototype, JSPerformanceServerTimingPrototype::Base);

using JSPerformanceServerTimingDOMConstructor = JSDOMConstructorNotConstructable<JSPerformanceServerTiming>;

template<> const ClassInfo JSPerformanceServerTimingDOMConstructor::s_info = { "PerformanceServerTiming"_s, &Base::s_info, nullptr, nullptr, CREATE_METHOD_TABLE(JSPerformanceServerTimingDOMConstructor) };

template<> JSValue JSPerformanceServerTimingDOMConstructor::prototypeForStructure(JSC::VM& vm, const JSDOMGlobalObject& globalObject)
{
    UNUSED_PARAM(vm);
    return globalObject.functionPrototype();
}

template<> void JSPerformanceServerTimingDOMConstructor::initializeProperties(VM& vm, JSDOMGlobalObject& globalObject)
{
    putDirect(vm, vm.propertyNames->length, jsNumber(0), JSC::PropertyAttribute::ReadOnly | JSC::PropertyAttribute::DontEnum);
    JSString* nameString = jsNontrivialString(vm, "PerformanceServerTiming"_s);
    m_originalName.set(vm, this, nameString);
    putDirect(vm, vm.propertyNames->name, nameString, JSC::PropertyAttribute::ReadOnly | JSC::PropertyAttribute::DontEnum);
    putDirect(vm, vm.propertyNames->prototype, JSPerformanceServerTiming::prototype(vm, globalObject), JSC::PropertyAttribute::ReadOnly | JSC::PropertyAttribute::DontEnum | JSC::PropertyAttribute::DontDelete);
}

/* Hash table for prototype */

static const HashTableValue JSPerformanceServerTimingPrototypeTableValues[] = {
    { "constructor"_s, static_cast<unsigned>(PropertyAttribute::DontEnum), NoIntrinsic, { HashTableValue::GetterSetterType, jsPerformanceServerTimingConstructor, 0 } },
    { "name"_s, JSC::PropertyAttribute::ReadOnly | JSC::PropertyAttribute::CustomAccessor | JSC::PropertyAttribute::DOMAttribute, NoIntrinsic, { HashTableValue::GetterSetterType, jsPerformanceServerTiming_name, 0 } },
    { "duration"_s, JSC::PropertyAttribute::ReadOnly | JSC::PropertyAttribute::CustomAccessor | JSC::PropertyAttribute::DOMAttribute, NoIntrinsic, { HashTableValue::GetterSetterType, jsPerformanceServerTiming_duration, 0 } },
    { "description"_s, JSC::PropertyAttribute::ReadOnly | JSC::PropertyAttribute::CustomAccessor | JSC::PropertyAttribute::DOMAttribute, NoIntrinsic, { HashTableValue::GetterSetterType, jsPerformanceServerTiming_description, 0 } },
    { "toJSON"_s, static_cast<unsigned>(JSC::PropertyAttribute::Function), NoIntrinsic, { HashTableValue::NativeFunctionType, jsPerformanceServerTimingPrototypeFunction_toJSON, 0 } },
};

const ClassInfo JSPerformanceServerTimingPrototype::s_info = { "PerformanceServerTiming"_s, &Base::s_info, nullptr, nullptr, CREATE_METHOD_TABLE(JSPerformanceServerTimingPrototype) };

void JSPerformanceServerTimingPrototype::finishCreation(VM& vm)
{
    Base::finishCreation(vm);
    reifyStaticProperties(vm, JSPerformanceServerTiming::info(), JSPerformanceServerTimingPrototypeTableValues, *this);
    JSC_TO_STRING_TAG_WITHOUT_TRANSITION();
}

const ClassInfo JSPerformanceServerTiming::s_info = { "PerformanceServerTiming"_s, &Base::s_info, nullptr, nullptr, CREATE_METHOD_TABLE(JSPerformanceServerTiming) };

JSPerformanceServerTiming::JSPerformanceServerTiming(Structure* structure, JSDOMGlobalObject& globalObject, Ref<PerformanceServerTiming>&& impl)
    : JSDOMWrapper<PerformanceServerTiming>(structure, globalObject, WTFMove(impl))
{
}

// static_assert(!std::is_base_of<ActiveDOMObject, PerformanceServerTiming>::value, "Interface is not marked as [ActiveDOMObject] even though implementation class subclasses ActiveDOMObject.");

JSObject* JSPerformanceServerTiming::createPrototype(VM& vm, JSDOMGlobalObject& globalObject)
{
    auto* structure = JSPerformanceServerTimingPrototype::createStructure(vm, &globalObject, globalObject.objectPrototype());
    structure->setMayBePrototype(true);
    return JSPerformanceServerTimingPrototype::create(vm, &globalObject, structure);
}

JSObject* JSPerformanceServerTiming::prototype(VM& vm, JSDOMGlobalObject& globalObject)
{
    return getDOMPrototype<JSPerformanceServerTiming>(vm, globalObject);
}

JSValue JSPerformanceServerTiming::getConstructor(VM& vm, const JSGlobalObject* globalObject)
{
    return getDOMConstructor<JSPerformanceServerTimingDOMConstructor, DOMConstructorID::PerformanceServerTiming>(vm, *jsCast<const JSDOMGlobalObject*>(globalObject));
}

void JSPerformanceServerTiming::destroy(JSC::JSCell* cell)
{
    JSPerformanceServerTiming* thisObject = static_cast<JSPerformanceServerTiming*>(cell);
    thisObject->JSPerformanceServerTiming::~JSPerformanceServerTiming();
}

JSC_DEFINE_CUSTOM_GETTER(jsPerformanceServerTimingConstructor, (JSGlobalObject * lexicalGlobalObject, EncodedJSValue thisValue, PropertyName))
{
    auto& vm = JSC::getVM(lexicalGlobalObject);
    auto throwScope = DECLARE_THROW_SCOPE(vm);
    auto* prototype = jsDynamicCast<JSPerformanceServerTimingPrototype*>(JSValue::decode(thisValue));
    if (UNLIKELY(!prototype))
        return throwVMTypeError(lexicalGlobalObject, throwScope);
    return JSValue::encode(JSPerformanceServerTiming::getConstructor(vm, prototype->globalObject()));
}

static inline JSValue jsPerformanceServerTiming_nameGetter(JSGlobalObject& lexicalGlobalObject, JSPerformanceServerTiming& thisObject)
{
    auto& vm = JSC::getVM(&lexicalGlobalObject);
    auto throwScope = DECLARE_THROW_SCOPE(vm);
    auto& impl = thisObject.wrapped();
    RELEASE_AND_RETURN(throwScope, (toJS<IDLDOMString>(lexicalGlobalObject, throwScope, impl.name())));
}

JSC_DEFINE_CUSTOM_GETTER(jsPerformanceServerTiming_name, (JSGlobalObject * lexicalGlobalObject, EncodedJSValue thisValue, PropertyName attributeName))
{
    return IDLAttribute<JSPerformanceServerTiming>::get<jsPerformanceServerTiming_nameGetter, CastedThisErrorBehavior::Assert>(*lexicalGlobalObject, thisValue, attributeName);
}

static inline JSValue jsPerformanceServerTiming_durationGetter(JSGlobalObject& lexicalGlobalObject, JSPerformanceServerTiming& thisObject)
{
    auto& vm = JSC::getVM(&lexicalGlobalObject);
    auto throwScope = DECLARE_THROW_SCOPE(vm);
    auto& impl = thisObject.wrapped();
    RELEASE_AND_RETURN(throwScope, (toJS<IDLDouble>(lexicalGlobalObject, throwScope, impl.duration())));
}

JSC_DEFINE_CUSTOM_GETTER(jsPerformanceServerTiming_duration, (JSGlobalObject * lexicalGlobalObject, EncodedJSValue thisValue, PropertyName attributeName))
{
    return IDLAttribute<JSPerformanceServerTiming>::get<jsPerformanceServerTiming_durationGetter, CastedThisErrorBehavior::Assert>(*lexicalGlobalObject, thisValue, attributeName);
}

static inline JSValue jsPerformanceServerTiming_descriptionGetter(JSGlobalObject& lexicalGlobalObject, JSPerformanceServerTiming& thisObject)
{
    auto& vm = JSC::getVM(&lexicalGlobalObject);
    auto throwScope = DECLARE_THROW_SCOPE(vm);
    auto& impl = thisObject.wrapped();
    RELEASE_AND_RETURN(throwScope, (toJS<IDLDOMString>(lexicalGlobalObject, throwScope, impl.description())));
}

JSC_DEFINE_CUSTOM_GETTER(jsPerformanceServerTiming_description, (JSGlobalObject * lexicalGlobalObject, EncodedJSValue thisValue, PropertyName attributeName))
{
    return IDLAttribute<JSPerformanceServerTiming>::get<jsPerformanceServerTiming_descriptionGetter, CastedThisErrorBehavior::Assert>(*lexicalGlobalObject, thisValue, attributeName);
}

static inline EncodedJSValue jsPerformanceServerTimingPrototypeFunction_toJSONBody(JSGlobalObject* lexicalGlobalObject, CallFrame*, JSPerformanceServerTiming* castedThis)
{
    auto& vm = JSC::getVM(lexicalGlobalObject);
    auto throwScope = DECLARE_THROW_SCOPE(vm);
    UNUSED_PARAM(throwScope);
    auto& impl = castedThis->wrapped();
    auto* result = constructEmptyObject(lexicalGlobalObject);
    auto nameValue = toJS<IDLDOMString>(*lexicalGlobalObject, throwScope, impl.name());
    RETURN_IF_EXCEPTION(throwScope, {});
    result->putDirect(vm, Identifier::fromString(vm, "name"_s), nameValue);
    auto durationValue = toJS<IDLDouble>(*lexicalGlobalObject, throwScope, impl.duration());
    RETURN_IF_EXCEPTION(throwScope, {});
    result->putDirect(vm, Identifier::fromString(vm, "duration"_s), durationValue);
    auto descriptionValue = toJS<IDLDOMString>(*lexicalGlobalObject, throwScope, impl.description());
    RETURN_IF_EXCEPTION(throwScope, {});
    result->putDirect(vm, Identifier::fromString(vm, "description"_s), descriptionValue);
    return JSValue::encode(result);
}

JSC_DEFINE_HOST_FUNCTION(jsPerformanceServerTimingPrototypeFunction_toJSON, (JSGlobalObject * lexicalGlobalObject, CallFrame* callFrame))
{
    return IDLOperation<JSPerformanceServerTiming>::call<jsPerformanceServerTimingPrototypeFunction_toJSONBody>(*lexicalGlobalObject, *callFrame, "toJSON");
}

JSC::GCClient::IsoSubspace* JSPerformanceServerTiming::subspaceForImpl(JSC::VM& vm)
{
    return WebCore::subspaceForImpl<JSPerformanceServerTiming, UseCustomHeapCellType::No>(vm, [](auto& spaces) { return spaces.m_clientSubspaceForPerformanceServerTiming.get(); }, [](auto& spaces, auto&& space) { spaces.m_clientSubspaceForPerformanceServerTiming = std::forward<decltype(space)>(space); }, [](auto& spaces) { return spaces.m_subspaceForPerformanceServerTiming.get(); }, [](auto& spaces, auto&& space) { spaces.m_subspaceForPerformanceServerTiming = std::forward<decltype(space)>(space); });
}

void JSPerformanceServerTiming::analyzeHeap(JSCell* cell, HeapAnalyzer& analyzer)
{
    auto* thisObject = jsCast<JSPerformanceServerTiming*>(cell);
    analyzer.setWrappedObjectForCell(cell, &thisObject->wrapped());
    if (thisObject->scriptExecutionContext())
        analyzer.setLabelForCell(cell, makeString("url "_s, thisObject->scriptExecutionContext()->url().string()));
    Base::analyzeHeap(cell, analyzer);
}

bool JSPerformanceServerTimingOwner::isReachableFromOpaqueRoots(JSC::Handle<JSC::Unknown> handle, void*, AbstractSlotVisitor& visitor, ASCIILiteral* reason)
{
    UNUSED_PARAM(handle);
    UNUSED_PARAM(visitor);
    UNUSED_PARAM(reason);
    return false;
}

void JSPerformanceServerTimingOwner::finalize(JSC::Handle<JSC::Unknown> handle, void* context)
{
    auto* jsPerformanceServerTiming = static_cast<JSPerformanceServerTiming*>(handle.slot()->asCell());
    auto& world = *static_cast<DOMWrapperWorld*>(context);
    uncacheWrapper(world, jsPerformanceServerTiming->protectedWrapped().ptr(), jsPerformanceServerTiming);
}

#if ENABLE(BINDING_INTEGRITY)
#if PLATFORM(WIN)
#pragma warning(disable : 4483)
extern "C" {
extern void (*const __identifier("??_7PerformanceServerTiming@WebCore@@6B@")[])();
}
#else
extern "C" {
extern void* _ZTVN7WebCore23PerformanceServerTimingE[];
}
#endif
#endif

JSC::JSValue toJSNewlyCreated(JSC::JSGlobalObject*, JSDOMGlobalObject* globalObject, Ref<PerformanceServerTiming>&& impl)
{

    //     if constexpr (std::is_polymorphic_v<PerformanceServerTiming>) {
    // #if ENABLE(BINDING_INTEGRITY)
    //         const void* actualVTablePointer = getVTablePointer(impl.ptr());
    // #if PLATFORM(WIN)
    //         void* expectedVTablePointer = __identifier("??_7PerformanceServerTiming@WebCore@@6B@");
    // #else
    //         void* expectedVTablePointer = &_ZTVN7WebCore23PerformanceServerTimingE[2];
    // #endif

    //         // If you hit this assertion you either have a use after free bug, or
    //         // PerformanceServerTiming has subclasses. If PerformanceServerTiming has subclasses that get passed
    //         // to toJS() we currently require PerformanceServerTiming you to opt out of binding hardening
    //         // by adding the SkipVTableValidation attribute to the interface IDL definition
    //         RELEASE_ASSERT(actualVTablePointer == expectedVTablePointer);
    // #endif
    // }
    return createWrapper<PerformanceServerTiming>(globalObject, WTFMove(impl));
}

JSC::JSValue toJS(JSC::JSGlobalObject* lexicalGlobalObject, JSDOMGlobalObject* globalObject, PerformanceServerTiming& impl)
{
    return wrap(lexicalGlobalObject, globalObject, impl);
}

PerformanceServerTiming* JSPerformanceServerTiming::toWrapped(JSC::VM&, JSC::JSValue value)
{
    if (auto* wrapper = jsDynamicCast<JSPerformanceServerTiming*>(value))
        return &wrapper->wrapped();
    return nullptr;
}

}
