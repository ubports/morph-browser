set(TEST tst_WebappContainerHookTests)
set(SOURCES
    ${CMAKE_SOURCE_DIR}/click-hooks/hook-utils.cpp
    tst_WebappContainerHookTests.cpp
)
set(WEBAPP_CONTAINER_HOOK webapp-container-hook)
include_directories(${CMAKE_SOURCE_DIR})
add_definitions(-DCLICK_HOOK_EXEC_BIN="${CMAKE_BINARY_DIR}/click-hooks/${WEBAPP_CONTAINER_HOOK}")
add_executable(${TEST} ${SOURCES})
qt5_use_modules(${TEST} Core Test)
add_test(${TEST} ${CMAKE_CURRENT_BINARY_DIR}/${TEST} -xunitxml -o ${TEST}.xml)
