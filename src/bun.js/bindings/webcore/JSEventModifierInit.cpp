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
#include "JSEventModifierInit.h"

#include "JSDOMConvertBoolean.h"
#include "JSDOMConvertInterface.h"
#include "JSDOMConvertNullable.h"
#include "JSDOMConvertNumbers.h"
// #include "JSWindowProxy.h"
#include <JavaScriptCore/JSCInlines.h>

namespace WebCore {
using namespace JSC;

template<> EventModifierInit convertDictionary<EventModifierInit>(JSGlobalObject& lexicalGlobalObject, JSValue value)
{
    auto& vm = JSC::getVM(&lexicalGlobalObject);
    auto throwScope = DECLARE_THROW_SCOPE(vm);
    bool isNullOrUndefined = value.isUndefinedOrNull();
    auto* object = isNullOrUndefined ? nullptr : value.getObject();
    if (UNLIKELY(!isNullOrUndefined && !object)) {
        throwTypeError(&lexicalGlobalObject, throwScope);
        return {};
    }
    EventModifierInit result;
    JSValue bubblesValue;
    if (isNullOrUndefined)
        bubblesValue = jsUndefined();
    else {
        bubblesValue = object->get(&lexicalGlobalObject, Identifier::fromString(vm, "bubbles"_s));
        RETURN_IF_EXCEPTION(throwScope, {});
    }
    if (!bubblesValue.isUndefined()) {
        result.bubbles = convert<IDLBoolean>(lexicalGlobalObject, bubblesValue);
        RETURN_IF_EXCEPTION(throwScope, {});
    } else
        result.bubbles = false;
    JSValue cancelableValue;
    if (isNullOrUndefined)
        cancelableValue = jsUndefined();
    else {
        cancelableValue = object->get(&lexicalGlobalObject, Identifier::fromString(vm, "cancelable"_s));
        RETURN_IF_EXCEPTION(throwScope, {});
    }
    if (!cancelableValue.isUndefined()) {
        result.cancelable = convert<IDLBoolean>(lexicalGlobalObject, cancelableValue);
        RETURN_IF_EXCEPTION(throwScope, {});
    } else
        result.cancelable = false;
    JSValue composedValue;
    if (isNullOrUndefined)
        composedValue = jsUndefined();
    else {
        composedValue = object->get(&lexicalGlobalObject, Identifier::fromString(vm, "composed"_s));
        RETURN_IF_EXCEPTION(throwScope, {});
    }
    if (!composedValue.isUndefined()) {
        result.composed = convert<IDLBoolean>(lexicalGlobalObject, composedValue);
        RETURN_IF_EXCEPTION(throwScope, {});
    } else
        result.composed = false;
    JSValue detailValue;
    if (isNullOrUndefined)
        detailValue = jsUndefined();
    else {
        detailValue = object->get(&lexicalGlobalObject, Identifier::fromString(vm, "detail"_s));
        RETURN_IF_EXCEPTION(throwScope, {});
    }
    if (!detailValue.isUndefined()) {
        result.detail = convert<IDLLong>(lexicalGlobalObject, detailValue);
        RETURN_IF_EXCEPTION(throwScope, {});
    } else
        result.detail = 0;
    JSValue viewValue;
    if (isNullOrUndefined)
        viewValue = jsUndefined();
    else {
        viewValue = object->get(&lexicalGlobalObject, Identifier::fromString(vm, "view"_s));
        RETURN_IF_EXCEPTION(throwScope, {});
    }
    // if (!viewValue.isUndefined()) {
    //     result.view = convert<IDLNullable<IDLInterface<WindowProxy>>>(lexicalGlobalObject, viewValue);
    //     RETURN_IF_EXCEPTION(throwScope, { });
    // } else
    result.view = nullptr;
    JSValue altKeyValue;
    if (isNullOrUndefined)
        altKeyValue = jsUndefined();
    else {
        altKeyValue = object->get(&lexicalGlobalObject, Identifier::fromString(vm, "altKey"_s));
        RETURN_IF_EXCEPTION(throwScope, {});
    }
    if (!altKeyValue.isUndefined()) {
        result.altKey = convert<IDLBoolean>(lexicalGlobalObject, altKeyValue);
        RETURN_IF_EXCEPTION(throwScope, {});
    } else
        result.altKey = false;
    JSValue ctrlKeyValue;
    if (isNullOrUndefined)
        ctrlKeyValue = jsUndefined();
    else {
        ctrlKeyValue = object->get(&lexicalGlobalObject, Identifier::fromString(vm, "ctrlKey"_s));
        RETURN_IF_EXCEPTION(throwScope, {});
    }
    if (!ctrlKeyValue.isUndefined()) {
        result.ctrlKey = convert<IDLBoolean>(lexicalGlobalObject, ctrlKeyValue);
        RETURN_IF_EXCEPTION(throwScope, {});
    } else
        result.ctrlKey = false;
    JSValue metaKeyValue;
    if (isNullOrUndefined)
        metaKeyValue = jsUndefined();
    else {
        metaKeyValue = object->get(&lexicalGlobalObject, Identifier::fromString(vm, "metaKey"_s));
        RETURN_IF_EXCEPTION(throwScope, {});
    }
    if (!metaKeyValue.isUndefined()) {
        result.metaKey = convert<IDLBoolean>(lexicalGlobalObject, metaKeyValue);
        RETURN_IF_EXCEPTION(throwScope, {});
    } else
        result.metaKey = false;
    JSValue modifierAltGraphValue;
    if (isNullOrUndefined)
        modifierAltGraphValue = jsUndefined();
    else {
        modifierAltGraphValue = object->get(&lexicalGlobalObject, Identifier::fromString(vm, "modifierAltGraph"_s));
        RETURN_IF_EXCEPTION(throwScope, {});
    }
    if (!modifierAltGraphValue.isUndefined()) {
        result.modifierAltGraph = convert<IDLBoolean>(lexicalGlobalObject, modifierAltGraphValue);
        RETURN_IF_EXCEPTION(throwScope, {});
    } else
        result.modifierAltGraph = false;
    JSValue modifierCapsLockValue;
    if (isNullOrUndefined)
        modifierCapsLockValue = jsUndefined();
    else {
        modifierCapsLockValue = object->get(&lexicalGlobalObject, Identifier::fromString(vm, "modifierCapsLock"_s));
        RETURN_IF_EXCEPTION(throwScope, {});
    }
    if (!modifierCapsLockValue.isUndefined()) {
        result.modifierCapsLock = convert<IDLBoolean>(lexicalGlobalObject, modifierCapsLockValue);
        RETURN_IF_EXCEPTION(throwScope, {});
    } else
        result.modifierCapsLock = false;
    JSValue shiftKeyValue;
    if (isNullOrUndefined)
        shiftKeyValue = jsUndefined();
    else {
        shiftKeyValue = object->get(&lexicalGlobalObject, Identifier::fromString(vm, "shiftKey"_s));
        RETURN_IF_EXCEPTION(throwScope, {});
    }
    if (!shiftKeyValue.isUndefined()) {
        result.shiftKey = convert<IDLBoolean>(lexicalGlobalObject, shiftKeyValue);
        RETURN_IF_EXCEPTION(throwScope, {});
    } else
        result.shiftKey = false;
    return result;
}

} // namespace WebCore
