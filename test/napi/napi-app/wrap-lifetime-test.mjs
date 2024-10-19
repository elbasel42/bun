import { createRequire } from "node:module";
const require = createRequire(import.meta.url);
const tests = require("./build/Debug/napitests.node");

function assert(ok) {
  if (!ok) throw new Error("assertion failed");
}

// try to clobber anything left over on the stack
function recurse(n) {
  if (n == 0) {
    return "";
  }
  return n.toString() + recurse(n - 1);
}

async function reallyGC() {
  recurse(1000);
  for (let i = 0; i < 5; i++) {
    await new Promise(resolve => setTimeout(resolve, 1));
    if (typeof global.gc == "function") {
      global.gc();
    } else if (typeof Bun == "object") {
      Bun.gc(true);
    }
  }
}

async function noRefTest() {
  console.log("/ noRefTest \\");
  let object = { foo: "bar" };
  // ask_for_ref, strong
  assert(tests.create_wrap(object, false, false) === object);

  await reallyGC();

  // still alive as we have object
  assert(tests.get_wrap_data(object) === 42);

  // this frees it
  object = undefined;
  await reallyGC();

  console.log("\\ noRefTest /");
}

async function weakRefTest() {
  console.log("/ weakRefTest \\");

  let object = { foo: "bar" };
  // ask_for_ref, strong
  assert(tests.create_wrap(object, true, false) === object);

  await reallyGC();

  // still alive as we have object
  assert(tests.get_wrap_data(object) === 42);

  // this frees it
  object = undefined;
  await reallyGC();

  console.log("\\ weakRefTest /");
}

async function strongRefTest() {
  console.log("/ strongRefTest \\");
  let object = { foo: "bar" };
  // ask_for_ref, strong
  assert(tests.create_wrap(object, true, true) === object);

  await reallyGC();

  // still alive as we have object
  assert(tests.get_wrap_data(object) === 42);

  // this doesn't free it as it's still ref'd
  object = undefined;
  await reallyGC();
  console.log("no longer referenced from JS");

  // native code can still get the value
  assert(tests.get_wrap_data_from_ref() == 42);

  // this frees it
  tests.unref_wrapped_value();
  await reallyGC();

  console.log("\\ strongRefTest /");
}

async function removeWrapWeakTest() {
  console.log("/ removeWrapWeakTest \\");
  let object = { foo: "bar" };
  // we make a weak ref
  // ask_for_ref, strong
  assert(tests.create_wrap(object, true, false) === object);

  await reallyGC();

  // still alive
  assert(tests.get_wrap_data(object) === 42);

  tests.remove_wrap(object);
  console.log("wrap removed");
  assert(tests.get_wrap_data_from_ref() === undefined);
  await reallyGC();

  // object can still be seen by the native weak ref
  assert(tests.get_object_from_ref() === object);

  // delete our reference
  object = undefined;
  console.log("JS reference gone");
  await reallyGC();

  console.log("\\ removeWrapWeakTest /");

  // no finalizer called :(
}

async function removeWrapStrongTest() {
  console.log("/ removeWrapStrongTest \\");
  let object = { foo: "bar" };
  // we make a strong ref
  // ask_for_ref, strong
  assert(tests.create_wrap(object, true, true) === object);
  console.log("wrapped");

  await reallyGC();
  console.log("gc");

  // still alive
  assert(tests.get_wrap_data(object) === 42);
  console.log("got wrap data");

  tests.remove_wrap(object);
  console.log("wrap removed");
  assert(tests.get_wrap_data_from_ref() === undefined);
  await reallyGC();

  // delete our reference
  object = undefined;
  console.log("no longer referenced from JS");
  await reallyGC();

  // object can still be seen from native reference
  assert(JSON.stringify(tests.get_object_from_ref()) == `{"foo":"bar"}`);

  tests.unref_wrapped_value();
  await reallyGC();

  // no finalizer called :(

  console.log("\\ removeWrapStrongTest /");
}

// await noRefTest();
// await weakRefTest();
// await strongRefTest();
await removeWrapWeakTest();
await removeWrapStrongTest();
