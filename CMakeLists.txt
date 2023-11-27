cmake_minimum_required(VERSION 3.22)

include(FetchContent)

include(${CMAKE_CURRENT_LIST_DIR}/version.cmake)
project(DkML VERSION ${DKML_VERSION_CMAKEVER} LANGUAGES NONE)

# Project wide setup
list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_LIST_DIR}/cmake)

add_subdirectory(dependencies)
add_subdirectory(pkg)