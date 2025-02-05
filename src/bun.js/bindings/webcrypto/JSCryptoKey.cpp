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

#if ENABLE(WEB_CRYPTO)

#include "JSCryptoKey.h"

#include "ActiveDOMObject.h"
#include "ExtendedDOMClientIsoSubspaces.h"
#include "ExtendedDOMIsoSubspaces.h"
#include "JSCryptoAesKeyAlgorithm.h"
#include "JSCryptoEcKeyAlgorithm.h"
#include "JSCryptoHmacKeyAlgorithm.h"
#include "JSCryptoKeyAlgorithm.h"
#include "JSCryptoKeyUsage.h"
#include "JSCryptoRsaHashedKeyAlgorithm.h"
#include "JSCryptoRsaKeyAlgorithm.h"
#include "JSDOMAttribute.h"
#include "JSDOMBinding.h"
#include "JSDOMConstructorNotConstructable.h"
#include "JSDOMConvertBoolean.h"
#include "JSDOMConvertDictionary.h"
#include "JSDOMConvertSequences.h"
#include "JSDOMConvertUnion.h"
#include "JSDOMExceptionHandling.h"
#include "JSDOMGlobalObject.h"
#include "JSDOMGlobalObjectInlines.h"
#include "JSDOMWrapperCache.h"
#include "ScriptExecutionContext.h"
#include "WebCoreJSClientData.h"
#include "WebCoreOpaqueRoot.h"
#include <JavaScriptCore/FunctionPrototype.h>
#include <JavaScriptCore/HeapAnalyzer.h>
#include <JavaScriptCore/JSArray.h>
#include <JavaScriptCore/JSCInlines.h>
#include <JavaScriptCore/JSDestructibleObjectHeapCellType.h>
#include <JavaScriptCore/JSString.h>
#include <JavaScriptCore/SlotVisitorMacros.h>
#include <JavaScriptCore/SubspaceInlines.h>
#include <variant>
#include <wtf/GetPtr.h>
#include <wtf/PointerPreparations.h>
#include <wtf/SortedArrayMap.h>
#include <wtf/URL.h>

namespace WebCore {
using namespace JSC;

String convertEnumerationToString(CryptoKey::Type enumerationValue)
{
    static const NeverDestroyed<String> values[] = {
        MAKE_STATIC_STRING_IMPL("public"),
        MAKE_STATIC_STRING_IMPL("private"),
        MAKE_STATIC_STRING_IMPL("secret"),
    };
    static_assert(static_cast<size_t>(CryptoKey::Type::Public) == 0, "CryptoKey::Type::Public is not 0 as expected");
    static_assert(static_cast<size_t>(CryptoKey::Type::Private) == 1, "CryptoKey::Type::Private is not 1 as expected");
    static_assert(static_cast<size_t>(CryptoKey::Type::Secret) == 2, "CryptoKey::Type::Secret is not 2 as expected");
    ASSERT(static_cast<size_t>(enumerationValue) < std::size(values));
    return values[static_cast<size_t>(enumerationValue)];
}

template<> JSString* convertEnumerationToJS(JSGlobalObject& lexicalGlobalObject, CryptoKey::Type enumerationValue)
{
    return jsStringWithCache(lexicalGlobalObject.vm(), convertEnumerationToString(enumerationValue));
}

template<> std::optional<CryptoKey::Type> parseEnumeration<CryptoKey::Type>(JSGlobalObject& lexicalGlobalObject, JSValue value)
{
    auto stringValue = value.toWTFString(&lexicalGlobalObject);
    static constexpr std::pair<ComparableASCIILiteral, CryptoKey::Type> mappings[] = {
        { "private"_s, CryptoKey::Type::Private },
        { "public"_s, CryptoKey::Type::Public },
        { "secret"_s, CryptoKey::Type::Secret },
    };
    static constexpr SortedArrayMap enumerationMapping { mappings };
    if (auto* enumerationValue = enumerationMapping.tryGet(stringValue); LIKELY(enumerationValue))
        return *enumerationValue;
    return std::nullopt;
}

template<> ASCIILiteral expectedEnumerationValues<CryptoKey::Type>()
{
    return "\"public\", \"private\", \"secret\""_s;
}

// Attributes

static JSC_DECLARE_CUSTOM_GETTER(jsCryptoKeyConstructor);
static JSC_DECLARE_CUSTOM_GETTER(jsCryptoKey_type);
static JSC_DECLARE_CUSTOM_GETTER(jsCryptoKey_extractable);
static JSC_DECLARE_CUSTOM_GETTER(jsCryptoKey_algorithm);
static JSC_DECLARE_CUSTOM_GETTER(jsCryptoKey_usages);

class JSCryptoKeyPrototype final : public JSC::JSNonFinalObject {
public:
    using Base = JSC::JSNonFinalObject;
    static JSCryptoKeyPrototype* create(JSC::VM& vm, JSDOMGlobalObject* globalObject, JSC::Structure* structure)
    {
        JSCryptoKeyPrototype* ptr = new (NotNull, JSC::allocateCell<JSCryptoKeyPrototype>(vm)) JSCryptoKeyPrototype(vm, globalObject, structure);
        ptr->finishCreation(vm);
        return ptr;
    }

    DECLARE_INFO;
    template<typename CellType, JSC::SubspaceAccess>
    static JSC::GCClient::IsoSubspace* subspaceFor(JSC::VM& vm)
    {
        STATIC_ASSERT_ISO_SUBSPACE_SHARABLE(JSCryptoKeyPrototype, Base);
        return &vm.plainObjectSpace();
    }
    static JSC::Structure* createStructure(JSC::VM& vm, JSC::JSGlobalObject* globalObject, JSC::JSValue prototype)
    {
        return JSC::Structure::create(vm, globalObject, prototype, JSC::TypeInfo(JSC::ObjectType, StructureFlags), info());
    }

private:
    JSCryptoKeyPrototype(JSC::VM& vm, JSC::JSGlobalObject*, JSC::Structure* structure)
        : JSC::JSNonFinalObject(vm, structure)
    {
    }

    void finishCreation(JSC::VM&);
};
STATIC_ASSERT_ISO_SUBSPACE_SHARABLE(JSCryptoKeyPrototype, JSCryptoKeyPrototype::Base);

using JSCryptoKeyDOMConstructor = JSDOMConstructorNotConstructable<JSCryptoKey>;

template<> const ClassInfo JSCryptoKeyDOMConstructor::s_info = { "CryptoKey"_s, &Base::s_info, nullptr, nullptr, CREATE_METHOD_TABLE(JSCryptoKeyDOMConstructor) };

template<> JSValue JSCryptoKeyDOMConstructor::prototypeForStructure(JSC::VM& vm, const JSDOMGlobalObject& globalObject)
{
    UNUSED_PARAM(vm);
    return globalObject.functionPrototype();
}

template<> void JSCryptoKeyDOMConstructor::initializeProperties(VM& vm, JSDOMGlobalObject& globalObject)
{
    putDirect(vm, vm.propertyNames->length, jsNumber(0), JSC::PropertyAttribute::ReadOnly | JSC::PropertyAttribute::DontEnum);
    JSString* nameString = jsNontrivialString(vm, "CryptoKey"_s);
    m_originalName.set(vm, this, nameString);
    putDirect(vm, vm.propertyNames->name, nameString, JSC::PropertyAttribute::ReadOnly | JSC::PropertyAttribute::DontEnum);
    putDirect(vm, vm.propertyNames->prototype, JSCryptoKey::prototype(vm, globalObject), JSC::PropertyAttribute::ReadOnly | JSC::PropertyAttribute::DontEnum | JSC::PropertyAttribute::DontDelete);
}

/* Hash table for prototype */

static const HashTableValue JSCryptoKeyPrototypeTableValues[] = {
    { "constructor"_s, static_cast<unsigned>(JSC::PropertyAttribute::DontEnum), NoIntrinsic, { HashTableValue::GetterSetterType, jsCryptoKeyConstructor, 0 } },
    { "type"_s, static_cast<unsigned>(JSC::PropertyAttribute::ReadOnly | JSC::PropertyAttribute::CustomAccessor | JSC::PropertyAttribute::DOMAttribute), NoIntrinsic, { HashTableValue::GetterSetterType, jsCryptoKey_type, 0 } },
    { "extractable"_s, static_cast<unsigned>(JSC::PropertyAttribute::ReadOnly | JSC::PropertyAttribute::CustomAccessor | JSC::PropertyAttribute::DOMAttribute), NoIntrinsic, { HashTableValue::GetterSetterType, jsCryptoKey_extractable, 0 } },
    { "algorithm"_s, static_cast<unsigned>(JSC::PropertyAttribute::ReadOnly | JSC::PropertyAttribute::CustomAccessor | JSC::PropertyAttribute::DOMAttribute), NoIntrinsic, { HashTableValue::GetterSetterType, jsCryptoKey_algorithm, 0 } },
    { "usages"_s, static_cast<unsigned>(JSC::PropertyAttribute::ReadOnly | JSC::PropertyAttribute::CustomAccessor | JSC::PropertyAttribute::DOMAttribute), NoIntrinsic, { HashTableValue::GetterSetterType, jsCryptoKey_usages, 0 } },
};

const ClassInfo JSCryptoKeyPrototype::s_info = { "CryptoKey"_s, &Base::s_info, nullptr, nullptr, CREATE_METHOD_TABLE(JSCryptoKeyPrototype) };

JSCryptoKey* JSCryptoKey::fromJS(JSGlobalObject* globalObject, JSValue value)
{
    if (value.inherits<JSCryptoKey>()) {
        return jsCast<JSCryptoKey*>(value);
    }

    JSObject* object = value.getObject();
    if (!object) {
        return nullptr;
    }

    auto& vm = JSC::getVM(globalObject);

    auto& names = WebCore::builtinNames(vm);

    if (auto nativeValue = object->getIfPropertyExists(globalObject, names.bunNativePtrPrivateName())) {
        return jsDynamicCast<JSCryptoKey*>(nativeValue);
    }

    return nullptr;
}

void JSCryptoKeyPrototype::finishCreation(VM& vm)
{
    Base::finishCreation(vm);
    reifyStaticProperties(vm, JSCryptoKey::info(), JSCryptoKeyPrototypeTableValues, *this);
    JSC_TO_STRING_TAG_WITHOUT_TRANSITION();
}

const ClassInfo JSCryptoKey::s_info = { "CryptoKey"_s, &Base::s_info, nullptr, nullptr, CREATE_METHOD_TABLE(JSCryptoKey) };

JSCryptoKey::JSCryptoKey(Structure* structure, JSDOMGlobalObject& globalObject, Ref<CryptoKey>&& impl)
    : JSDOMWrapper<CryptoKey>(structure, globalObject, WTFMove(impl))
{
}

void JSCryptoKey::finishCreation(VM& vm)
{
    Base::finishCreation(vm);
    ASSERT(inherits(info()));

    // static_assert(!std::is_base_of<ActiveDOMObject, CryptoKey>::value, "Interface is not marked as [ActiveDOMObject] even though implementation class subclasses ActiveDOMObject.");
}

JSObject* JSCryptoKey::createPrototype(VM& vm, JSDOMGlobalObject& globalObject)
{
    auto* structure = JSCryptoKeyPrototype::createStructure(vm, &globalObject, globalObject.objectPrototype());
    structure->setMayBePrototype(true);
    return JSCryptoKeyPrototype::create(vm, &globalObject, structure);
}

JSObject* JSCryptoKey::prototype(VM& vm, JSDOMGlobalObject& globalObject)
{
    return getDOMPrototype<JSCryptoKey>(vm, globalObject);
}

JSValue JSCryptoKey::getConstructor(VM& vm, const JSGlobalObject* globalObject)
{
    return getDOMConstructor<JSCryptoKeyDOMConstructor, DOMConstructorID::CryptoKey>(vm, *jsCast<const JSDOMGlobalObject*>(globalObject));
}

void JSCryptoKey::destroy(JSC::JSCell* cell)
{
    JSCryptoKey* thisObject = static_cast<JSCryptoKey*>(cell);
    thisObject->JSCryptoKey::~JSCryptoKey();
}

JSC_DEFINE_CUSTOM_GETTER(jsCryptoKeyConstructor, (JSGlobalObject * lexicalGlobalObject, JSC::EncodedJSValue thisValue, PropertyName))
{
    auto& vm = JSC::getVM(lexicalGlobalObject);
    auto throwScope = DECLARE_THROW_SCOPE(vm);
    auto* prototype = jsDynamicCast<JSCryptoKeyPrototype*>(JSValue::decode(thisValue));
    if (UNLIKELY(!prototype))
        return throwVMTypeError(lexicalGlobalObject, throwScope);
    return JSValue::encode(JSCryptoKey::getConstructor(JSC::getVM(lexicalGlobalObject), prototype->globalObject()));
}

static inline JSValue jsCryptoKey_typeGetter(JSGlobalObject& lexicalGlobalObject, JSCryptoKey& thisObject)
{
    auto& vm = JSC::getVM(&lexicalGlobalObject);
    auto throwScope = DECLARE_THROW_SCOPE(vm);
    auto& impl = thisObject.wrapped();
    RELEASE_AND_RETURN(throwScope, (toJS<IDLEnumeration<CryptoKey::Type>>(lexicalGlobalObject, throwScope, impl.type())));
}

JSC_DEFINE_CUSTOM_GETTER(jsCryptoKey_type, (JSGlobalObject * lexicalGlobalObject, JSC::EncodedJSValue thisValue, PropertyName attributeName))
{
    return IDLAttribute<JSCryptoKey>::get<jsCryptoKey_typeGetter, CastedThisErrorBehavior::Assert>(*lexicalGlobalObject, thisValue, attributeName);
}

static inline JSValue jsCryptoKey_extractableGetter(JSGlobalObject& lexicalGlobalObject, JSCryptoKey& thisObject)
{
    auto& vm = JSC::getVM(&lexicalGlobalObject);
    auto throwScope = DECLARE_THROW_SCOPE(vm);
    auto& impl = thisObject.wrapped();
    RELEASE_AND_RETURN(throwScope, (toJS<IDLBoolean>(lexicalGlobalObject, throwScope, impl.extractable())));
}

JSC_DEFINE_CUSTOM_GETTER(jsCryptoKey_extractable, (JSGlobalObject * lexicalGlobalObject, JSC::EncodedJSValue thisValue, PropertyName attributeName))
{
    return IDLAttribute<JSCryptoKey>::get<jsCryptoKey_extractableGetter, CastedThisErrorBehavior::Assert>(*lexicalGlobalObject, thisValue, attributeName);
}

static inline JSValue jsCryptoKey_algorithmGetter(JSGlobalObject& lexicalGlobalObject, JSCryptoKey& thisObject)
{
    auto& vm = JSC::getVM(&lexicalGlobalObject);
    auto throwScope = DECLARE_THROW_SCOPE(vm);
    if (JSValue cachedValue = thisObject.m_algorithm.get())
        return cachedValue;
    auto& impl = thisObject.wrapped();
    JSValue result = toJS<IDLUnion<IDLDictionary<CryptoKeyAlgorithm>, IDLDictionary<CryptoAesKeyAlgorithm>, IDLDictionary<CryptoEcKeyAlgorithm>, IDLDictionary<CryptoHmacKeyAlgorithm>, IDLDictionary<CryptoRsaHashedKeyAlgorithm>, IDLDictionary<CryptoRsaKeyAlgorithm>>>(lexicalGlobalObject, *thisObject.globalObject(), throwScope, impl.algorithm());
    RETURN_IF_EXCEPTION(throwScope, {});
    thisObject.m_algorithm.set(JSC::getVM(&lexicalGlobalObject), &thisObject, result);
    return result;
}

JSC_DEFINE_CUSTOM_GETTER(jsCryptoKey_algorithm, (JSGlobalObject * lexicalGlobalObject, JSC::EncodedJSValue thisValue, PropertyName attributeName))
{
    return IDLAttribute<JSCryptoKey>::get<jsCryptoKey_algorithmGetter, CastedThisErrorBehavior::Assert>(*lexicalGlobalObject, thisValue, attributeName);
}

static inline JSValue jsCryptoKey_usagesGetter(JSGlobalObject& lexicalGlobalObject, JSCryptoKey& thisObject)
{
    auto& vm = JSC::getVM(&lexicalGlobalObject);
    auto throwScope = DECLARE_THROW_SCOPE(vm);
    if (JSValue cachedValue = thisObject.m_usages.get())
        return cachedValue;
    auto& impl = thisObject.wrapped();
    JSValue result = toJS<IDLSequence<IDLEnumeration<CryptoKeyUsage>>>(lexicalGlobalObject, *thisObject.globalObject(), throwScope, impl.usages());
    RETURN_IF_EXCEPTION(throwScope, {});
    thisObject.m_usages.set(JSC::getVM(&lexicalGlobalObject), &thisObject, result);
    return result;
}

JSC_DEFINE_CUSTOM_GETTER(jsCryptoKey_usages, (JSGlobalObject * lexicalGlobalObject, JSC::EncodedJSValue thisValue, PropertyName attributeName))
{
    return IDLAttribute<JSCryptoKey>::get<jsCryptoKey_usagesGetter, CastedThisErrorBehavior::Assert>(*lexicalGlobalObject, thisValue, attributeName);
}

JSC::GCClient::IsoSubspace* JSCryptoKey::subspaceForImpl(JSC::VM& vm)
{
    return WebCore::subspaceForImpl<JSCryptoKey, UseCustomHeapCellType::No>(
        vm,
        [](auto& spaces) { return spaces.m_clientSubspaceForCryptoKey.get(); },
        [](auto& spaces, auto&& space) { spaces.m_clientSubspaceForCryptoKey = std::forward<decltype(space)>(space); },
        [](auto& spaces) { return spaces.m_subspaceForCryptoKey.get(); },
        [](auto& spaces, auto&& space) { spaces.m_subspaceForCryptoKey = std::forward<decltype(space)>(space); });
}

template<typename Visitor>
void JSCryptoKey::visitChildrenImpl(JSCell* cell, Visitor& visitor)
{
    auto* thisObject = jsCast<JSCryptoKey*>(cell);
    ASSERT_GC_OBJECT_INHERITS(thisObject, info());
    Base::visitChildren(thisObject, visitor);
    visitor.append(thisObject->m_algorithm);
    visitor.append(thisObject->m_usages);
}

DEFINE_VISIT_CHILDREN(JSCryptoKey);

void JSCryptoKey::analyzeHeap(JSCell* cell, HeapAnalyzer& analyzer)
{
    auto* thisObject = jsCast<JSCryptoKey*>(cell);
    analyzer.setWrappedObjectForCell(cell, &thisObject->wrapped());
    if (thisObject->scriptExecutionContext())
        analyzer.setLabelForCell(cell, makeString("url "_s, thisObject->scriptExecutionContext()->url().string()));
    Base::analyzeHeap(cell, analyzer);
}

bool JSCryptoKeyOwner::isReachableFromOpaqueRoots(JSC::Handle<JSC::Unknown> handle, void* context, AbstractSlotVisitor& visitor, ASCIILiteral* reason)
{
    if (UNLIKELY(reason))
        *reason = "Reachable from CryptoKey"_s;
    return visitor.containsOpaqueRoot(context);
}

void JSCryptoKeyOwner::finalize(JSC::Handle<JSC::Unknown> handle, void* context)
{
    auto* jsCryptoKey = static_cast<JSCryptoKey*>(handle.slot()->asCell());
    auto& world = *static_cast<DOMWrapperWorld*>(context);
    uncacheWrapper(world, &jsCryptoKey->wrapped(), jsCryptoKey);
}

JSC::JSValue toJSNewlyCreated(JSC::JSGlobalObject*, JSDOMGlobalObject* globalObject, Ref<CryptoKey>&& impl)
{
    return createWrapper<CryptoKey>(globalObject, WTFMove(impl));
}

JSC::JSValue toJS(JSC::JSGlobalObject* lexicalGlobalObject, JSDOMGlobalObject* globalObject, CryptoKey& impl)
{
    return wrap(lexicalGlobalObject, globalObject, impl);
}

CryptoKey* JSCryptoKey::toWrapped(JSC::VM&, JSC::JSValue value)
{
    if (auto* wrapper = jsDynamicCast<JSCryptoKey*>(value))
        return &wrapper->wrapped();
    return nullptr;
}

}

#endif // ENABLE(WEB_CRYPTO)
