include(Macros)

register_repository(
  NAME
    boringssl
  REPOSITORY
    oven-sh/boringssl
  COMMIT
    29a2cd359458c9384694b75456026e4b57e3e567
)

register_cmake_command(
  TARGET
    boringssl
  LIBRARIES
    crypto
    ssl
    decrepit
  ARGS
    -DBUILD_SHARED_LIBS=OFF
  INCLUDES
    include
)
