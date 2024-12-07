optionx(ENABLE_CODESIGN BOOL "Enable code signing" DEFAULT ${CI})

if(ENABLE_CODESIGN AND APPLE)
  find_command(VARIABLE SECURITY_PROGRAM COMMAND security REQUIRED)
  find_command(VARIABLE CODESIGN_PROGRAM COMMAND codesign REQUIRED)
  find_command(VARIABLE DITTO_PROGRAM COMMAND ditto REQUIRED)

  set(DEFAULT_APPLE_CODESIGN_KEYCHAIN_PATH ${BUILD_PATH}/apple-codesign-keychain.db)
  optionx(APPLE_CODESIGN_KEYCHAIN_PATH FILEPATH "Path to the keychain to use for code signing" DEFAULT ${DEFAULT_APPLE_CODESIGN_KEYCHAIN_PATH})
  get_filename_component(APPLE_CODESIGN_KEYCHAIN_FILENAME ${APPLE_CODESIGN_KEYCHAIN_PATH} NAME)

  if(APPLE_CODESIGN_KEYCHAIN_PATH STREQUAL "${DEFAULT_APPLE_CODESIGN_KEYCHAIN_PATH}")
    set(APPLE_CODESIGN_KEYCHAIN_PASSWORD "")
  else()
    optionx(APPLE_CODESIGN_KEYCHAIN_PASSWORD STRING "Password for the keychain" DEFAULT "" SECRET)
  endif()

  if(NOT EXISTS ${APPLE_CODESIGN_KEYCHAIN_PATH})
    execute_process(
      COMMAND ${SECURITY_PROGRAM} create-keychain -p "${APPLE_CODESIGN_KEYCHAIN_PASSWORD}" ${APPLE_CODESIGN_KEYCHAIN_PATH}
      COMMAND_ECHO STDOUT
      OUTPUT_QUIET
      ERROR_VARIABLE CREATE_KEYCHAIN_ERROR
      ERROR_STRIP_TRAILING_WHITESPACE
    )

    if(CREATE_KEYCHAIN_ERROR)
      message(FATAL_ERROR "Failed to create keychain ${APPLE_CODESIGN_KEYCHAIN_FILENAME}: ${CREATE_KEYCHAIN_ERROR}")
    endif()

    execute_process(
      COMMAND ${SECURITY_PROGRAM} set-keychain-settings -l ${APPLE_CODESIGN_KEYCHAIN_PATH}
      COMMAND_ECHO STDOUT
      OUTPUT_QUIET
      ERROR_VARIABLE SET_KEYCHAIN_SETTINGS_ERROR
      ERROR_STRIP_TRAILING_WHITESPACE
    )

    if(SET_KEYCHAIN_SETTINGS_ERROR)
      message(FATAL_ERROR "Failed to set keychain settings for ${APPLE_CODESIGN_KEYCHAIN_FILENAME}: ${SET_KEYCHAIN_SETTINGS_ERROR}")
    endif()
  endif()

  execute_process(
    COMMAND ${SECURITY_PROGRAM} unlock-keychain -p "${APPLE_CODESIGN_KEYCHAIN_PASSWORD}" ${APPLE_CODESIGN_KEYCHAIN_PATH}
    COMMAND_ECHO STDOUT
    OUTPUT_QUIET
    ERROR_VARIABLE UNLOCK_KEYCHAIN_ERROR
    ERROR_STRIP_TRAILING_WHITESPACE
  )

  if(UNLOCK_KEYCHAIN_ERROR)
    message(FATAL_ERROR "Failed to unlock keychain ${APPLE_CODESIGN_KEYCHAIN_FILENAME}: ${UNLOCK_KEYCHAIN_ERROR}")
  endif()

  optionx(APPLE_CODESIGN_IDENTITY STRING "Code signing identity on macOS (e.g. 'FRXF46ZSN')" SECRET)

  if(NOT APPLE_CODESIGN_IDENTITY)
    message(FATAL_ERROR "Code signing is enabled, but no APPLE_CODESIGN_IDENTITY is set.\n"
      "To fix this, either:\n"
      "  - Set ENABLE_CODESIGN=OFF to disable code signing\n"
      "  - Find your identity in your keychain and set APPLE_CODESIGN_IDENTITY to the identity's name\n"
    )
  endif()

  set(DEFAULT_APPLE_CODESIGN_IDENTITY_PATH ${BUILD_PATH}/apple-codesign-identity.p12)
  optionx(APPLE_CODESIGN_IDENTITY_PATH FILEPATH "Path to the code signing identity .p12 file" DEFAULT ${DEFAULT_APPLE_CODESIGN_IDENTITY_PATH})
  optionx(APPLE_CODESIGN_IDENTITY_BASE64 STRING "Base64-encoded code signing identity .p12 file" SECRET)

  if(APPLE_CODESIGN_IDENTITY_BASE64)
    find_command(VARIABLE BASE64_PROGRAM COMMAND base64 REQUIRED)

    file(WRITE ${APPLE_CODESIGN_IDENTITY_PATH}.base64 "${APPLE_CODESIGN_IDENTITY_BASE64}")
    execute_process(
      COMMAND ${BASE64_PROGRAM} --decode -i ${APPLE_CODESIGN_IDENTITY_PATH}.base64 -o ${APPLE_CODESIGN_IDENTITY_PATH}
      COMMAND_ECHO STDOUT
      OUTPUT_QUIET
      ERROR_VARIABLE DECODE_IDENTITY_ERROR
      ERROR_STRIP_TRAILING_WHITESPACE
    )
    file(REMOVE ${APPLE_CODESIGN_IDENTITY_PATH}.base64)

    if(DECODE_IDENTITY_ERROR)
      message(FATAL_ERROR "Failed to decode base64 identity: ${DECODE_IDENTITY_ERROR}")
    endif()
  endif()

  optionx(APPLE_CODESIGN_IDENTITY_PASSWORD STRING "Password for the code signing identity .p12 file" DEFAULT "" SECRET)

  execute_process(
    COMMAND ${SECURITY_PROGRAM} find-identity -v -p codesigning ${APPLE_CODESIGN_KEYCHAIN_PATH}
    COMMAND_ECHO STDOUT
    OUTPUT_VARIABLE FIND_IDENTITY_OUTPUT
    OUTPUT_STRIP_TRAILING_WHITESPACE
    ERROR_VARIABLE FIND_IDENTITY_ERROR
    ERROR_STRIP_TRAILING_WHITESPACE
  )

  if(FIND_IDENTITY_ERROR)
    message(FATAL_ERROR "Failed to find identity ${APPLE_CODESIGN_IDENTITY} in keychain ${APPLE_CODESIGN_KEYCHAIN_FILENAME}: ${FIND_IDENTITY_ERROR}")
  endif()

  if(NOT FIND_IDENTITY_OUTPUT MATCHES "${APPLE_CODESIGN_IDENTITY}")
    execute_process(
      COMMAND ${SECURITY_PROGRAM} import ${APPLE_CODESIGN_IDENTITY_PATH} -k ${APPLE_CODESIGN_KEYCHAIN_PATH} -P "${APPLE_CODESIGN_IDENTITY_PASSWORD}" -T ${CODESIGN_PROGRAM}
      COMMAND_ECHO STDOUT
      OUTPUT_QUIET
      ERROR_VARIABLE IMPORT_IDENTITY_ERROR
      ERROR_STRIP_TRAILING_WHITESPACE
    )

    if(IMPORT_IDENTITY_ERROR)
      message(FATAL_ERROR "Failed to import identity ${APPLE_CODESIGN_IDENTITY_PATH}: ${IMPORT_IDENTITY_ERROR}")
    endif()

    execute_process(
      COMMAND ${SECURITY_PROGRAM} set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "${APPLE_CODESIGN_KEYCHAIN_PASSWORD}" ${APPLE_CODESIGN_KEYCHAIN_PATH}
      COMMAND_ECHO STDOUT
      OUTPUT_QUIET
      ERROR_VARIABLE SET_KEY_PARTITION_LIST_ERROR
      ERROR_STRIP_TRAILING_WHITESPACE
    )

    if(SET_KEY_PARTITION_LIST_ERROR)
      message(FATAL_ERROR "Failed to set key partition list for ${APPLE_CODESIGN_KEYCHAIN_FILENAME}: ${SET_KEY_PARTITION_LIST_ERROR}")
    endif()

    execute_process(
      COMMAND ${SECURITY_PROGRAM} find-identity -v -p codesigning ${APPLE_CODESIGN_KEYCHAIN_PATH}
      COMMAND_ECHO STDOUT
      OUTPUT_VARIABLE FIND_IDENTITY_OUTPUT
      OUTPUT_STRIP_TRAILING_WHITESPACE
      ERROR_VARIABLE FIND_IDENTITY_ERROR
      ERROR_STRIP_TRAILING_WHITESPACE
    )

    if(FIND_IDENTITY_ERROR)
      message(FATAL_ERROR "Failed to find identity ${APPLE_CODESIGN_IDENTITY} in keychain ${APPLE_CODESIGN_KEYCHAIN_FILENAME}: ${FIND_IDENTITY_ERROR}")
    endif()

    if(NOT FIND_IDENTITY_OUTPUT MATCHES "${APPLE_CODESIGN_IDENTITY}")
      message(FATAL_ERROR "Code signing is enabled, but no identity was found in your keychain.\n"
        "To fix this, either:\n"
        "  - Add the identity to your keychain by running 'security import [identity-path] -k [keychain-path] -T ${CODESIGN_PROGRAM}'\n"
        "  - Set APPLE_CODESIGN_IDENTITY_PATH to the path of the .p12 file for the identity\n"
        "  - Set APPLE_CODESIGN_IDENTITY_BASE64 to the base64-encoded .p12 file for the identity\n"
      )
    endif()
  endif()
endif()

if(ENABLE_CODESIGN AND WIN32)
  # TODO: Implement code signing for Windows
endif()
