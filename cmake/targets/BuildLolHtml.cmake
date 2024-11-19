register_repository(
  NAME
    lolhtml
  REPOSITORY
    cloudflare/lol-html
  COMMIT
    8d4c273ded322193d017042d1f48df2766b0f88b
)

set(LOLHTML_CWD ${VENDOR_PATH}/lolhtml/c-api)
set(LOLHTML_BUILD_PATH ${BUILD_PATH}/lolhtml)

if(DEBUG)
  set(LOLHTML_BUILD_TYPE debug)
else()
  set(LOLHTML_BUILD_TYPE release)
endif()

if(ARCH STREQUAL "x64")
  set(RUST_ARCH x86_64)
elseif(ARCH STREQUAL "aarch64")
  set(RUST_ARCH aarch64)
else()
  unsupported(ARCH)
endif()

if(WIN32)
  set(RUST_TARGET ${RUST_ARCH}-pc-windows-msvc)
elseif(APPLE)
  set(RUST_TARGET ${RUST_ARCH}-apple-darwin)
elseif(LINUX)
  if(ABI STREQUAL "musl")
    set(RUST_TARGET ${RUST_ARCH}-unknown-linux-musl)
  else()
    set(RUST_TARGET ${RUST_ARCH}-unknown-linux-gnu)
  endif()
else()
  unsupported(CMAKE_SYSTEM_NAME)
endif()

set(LOLHTML_LIBRARY ${LOLHTML_BUILD_PATH}/${LOLHTML_BUILD_TYPE}/${CMAKE_STATIC_LIBRARY_PREFIX}lolhtml${CMAKE_STATIC_LIBRARY_SUFFIX})

set(LOLHTML_BUILD_ARGS
  --target ${RUST_TARGET}
  --target-dir ${BUILD_PATH}/lolhtml
)

if(RELEASE)
  list(APPEND LOLHTML_BUILD_ARGS --release)
endif()

# Windows requires unwind tables, apparently.
if (NOT WIN32)
  # The encoded escape sequences are intentional. They're how you delimit multiple arguments in a single environment variable.
  # Also add rust optimization flag for smaller binary size, but not huge speed penalty.
  set(RUSTFLAGS "-Cpanic=abort-Cdebuginfo=0-Cforce-unwind-tables=no-Copt-level=s")
endif()

# Add these linker flags to generate both .dll and .lib files
if(WIN32)
  set(RUSTFLAGS "-Clink-args=/DEF/IMPLIB:lolhtml.lib")
endif()

register_command(
  TARGET
    lolhtml
  CWD
    ${LOLHTML_CWD}
  COMMAND
    ${CARGO_EXECUTABLE}
      build
      ${LOLHTML_BUILD_ARGS}
  ARTIFACTS
    ${LOLHTML_LIBRARY}
  ENVIRONMENT
    CARGO_TERM_COLOR=always
    CARGO_TERM_VERBOSE=true
    CARGO_TERM_DIAGNOSTIC=true
    CARGO_ENCODED_RUSTFLAGS=${RUSTFLAGS}
)

target_link_libraries(${bun} PRIVATE ${LOLHTML_LIBRARY})
if(BUN_LINK_ONLY)
  target_sources(${bun} PRIVATE ${LOLHTML_LIBRARY})
endif()
