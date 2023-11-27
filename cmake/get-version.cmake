include(${CMAKE_CURRENT_LIST_DIR}/../version.cmake)
execute_process(COMMAND ${CMAKE_COMMAND} -E echo "${DKML_VERSION_CMAKEVER}")
