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

#include "JSCryptoHmacKeyAlgorithm.h"

#include "JSCryptoKeyAlgorithm.h"
#include "JSDOMConvertNumbers.h"
#include "JSDOMConvertStrings.h"
#include "JSDOMGlobalObject.h"
#include <JavaScriptCore/JSCInlines.h>
#include <JavaScriptCore/ObjectConstructor.h>

namespace WebCore {
using namespace JSC;

#if ENABLE(WEB_CRYPTO)

template<> CryptoHmacKeyAlgorithm convertDictionary<CryptoHmacKeyAlgorithm>(JSGlobalObject& lexicalGlobalObject, JSValue value)
{
    auto& vm = JSC::getVM(&lexicalGlobalObject);
    auto throwScope = DECLARE_THROW_SCOPE(vm);
    bool isNullOrUndefined = value.isUndefinedOrNull();
    auto* object = isNullOrUndefined ? nullptr : value.getObject();
    if (UNLIKELY(!isNullOrUndefined && !object)) {
        throwTypeError(&lexicalGlobalObject, throwScope);
        return {};
    }
    CryptoHmacKeyAlgorithm result;
    JSValue nameValue;
    if (isNullOrUndefined)
        nameValue = jsUndefined();
    else {
        nameValue = object->get(&lexicalGlobalObject, vm.propertyNames->name);
        RETURN_IF_EXCEPTION(throwScope, {});
    }
    if (!nameValue.isUndefined()) {
        result.name = convert<IDLDOMString>(lexicalGlobalObject, nameValue);
        RETURN_IF_EXCEPTION(throwScope, {});
    } else {
        throwRequiredMemberTypeError(lexicalGlobalObject, throwScope, "name"_s, "CryptoHmacKeyAlgorithm"_s, "DOMString"_s);
        return {};
    }
    JSValue hashValue;
    if (isNullOrUndefined)
        hashValue = jsUndefined();
    else {
        hashValue = object->get(&lexicalGlobalObject, Identifier::fromString(vm, "hash"_s));
        RETURN_IF_EXCEPTION(throwScope, {});
    }
    if (!hashValue.isUndefined()) {
        result.hash = convert<IDLDictionary<CryptoKeyAlgorithm>>(lexicalGlobalObject, hashValue);
        RETURN_IF_EXCEPTION(throwScope, {});
    } else {
        throwRequiredMemberTypeError(lexicalGlobalObject, throwScope, "hash"_s, "CryptoHmacKeyAlgorithm"_s, "CryptoKeyAlgorithm"_s);
        return {};
    }
    JSValue lengthValue;
    if (isNullOrUndefined)
        lengthValue = jsUndefined();
    else {
        lengthValue = object->get(&lexicalGlobalObject, Identifier::fromString(vm, "length"_s));
        RETURN_IF_EXCEPTION(throwScope, {});
    }
    if (!lengthValue.isUndefined()) {
        result.length = convert<IDLUnsignedLong>(lexicalGlobalObject, lengthValue);
        RETURN_IF_EXCEPTION(throwScope, {});
    } else {
        throwRequiredMemberTypeError(lexicalGlobalObject, throwScope, "length"_s, "CryptoHmacKeyAlgorithm"_s, "unsigned long"_s);
        return {};
    }
    return result;
}

JSC::JSObject* convertDictionaryToJS(JSC::JSGlobalObject& lexicalGlobalObject, JSDOMGlobalObject& globalObject, const CryptoHmacKeyAlgorithm& dictionary)
{
    auto& vm = JSC::getVM(&lexicalGlobalObject);
    auto throwScope = DECLARE_THROW_SCOPE(vm);

    auto result = constructEmptyObject(&lexicalGlobalObject, globalObject.objectPrototype());

    auto nameValue = toJS<IDLDOMString>(lexicalGlobalObject, throwScope, dictionary.name);
    RETURN_IF_EXCEPTION(throwScope, {});
    result->putDirect(vm, vm.propertyNames->name, nameValue);
    auto hashValue = toJS<IDLDictionary<CryptoKeyAlgorithm>>(lexicalGlobalObject, globalObject, throwScope, dictionary.hash);
    RETURN_IF_EXCEPTION(throwScope, {});
    result->putDirect(vm, JSC::Identifier::fromString(vm, "hash"_s), hashValue);
    auto lengthValue = toJS<IDLUnsignedLong>(lexicalGlobalObject, throwScope, dictionary.length);
    RETURN_IF_EXCEPTION(throwScope, {});
    result->putDirect(vm, vm.propertyNames->length, lengthValue);
    return result;
}

#endif

} // namespace WebCore

#endif // ENABLE(WEB_CRYPTO)
