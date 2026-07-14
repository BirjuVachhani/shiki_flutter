# Cross-platform download + SHA-256 verify + extract of the pinned Oniguruma
# source release. Runs identically on macOS/Linux/Windows runners with only
# CMake installed. Used by the prebuild-oniguruma workflow.
#
#   cmake -DDEST=<dir> -P fetch_onig.cmake
#
# Produces <dir>/onig-6.9.10/ .

set(ONIG_VERSION "6.9.10")
set(ONIG_URL
  "https://github.com/kkos/oniguruma/releases/download/v${ONIG_VERSION}/onig-${ONIG_VERSION}.tar.gz")
set(ONIG_SHA256
  "2a5cfc5ae259e4e97f86b68dfffc152cdaffe94e2060b770cb827238d769fc05")

if(NOT DEFINED DEST)
  message(FATAL_ERROR "Set -DDEST=<output directory>.")
endif()
file(MAKE_DIRECTORY "${DEST}")

set(_tarball "${DEST}/onig-${ONIG_VERSION}.tar.gz")

foreach(_attempt RANGE 1 3)
  file(DOWNLOAD "${ONIG_URL}" "${_tarball}"
    EXPECTED_HASH SHA256=${ONIG_SHA256}
    INACTIVITY_TIMEOUT 60
    STATUS _status
  )
  list(GET _status 0 _code)
  if(_code EQUAL 0)
    break()
  endif()
  message(WARNING "Download attempt ${_attempt} failed: ${_status}")
  file(REMOVE "${_tarball}")
endforeach()

if(NOT _code EQUAL 0)
  message(FATAL_ERROR "Failed to download ${ONIG_URL}: ${_status}")
endif()

file(ARCHIVE_EXTRACT INPUT "${_tarball}" DESTINATION "${DEST}")
message(STATUS "Oniguruma source ready at ${DEST}/onig-${ONIG_VERSION}")
