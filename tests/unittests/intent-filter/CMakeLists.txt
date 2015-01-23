set(TEST tst_IntentFilterTests.cpp)
set(SOURCES
    ${CMAKE_SOURCE_DIR}/src/app/webcontainer/intent-filter.cpp
    tst_IntentFilterTests.cpp
)
set(WEBAPP_CONTAINER_INTENT_FILTER webapp-container-intent-filter)
include_directories(${CMAKE_SOURCE_DIR})
add_definitions(-DCLICK_HOOK_EXEC_BIN="${CMAKE_BINARY_DIR}/click-hooks/${WEBAPP_CONTAINER_HOOK}")
add_executable(${TEST} ${SOURCES})
qt5_use_modules(${TEST} Core Test Qml)
add_test(${TEST} ${CMAKE_CURRENT_BINARY_DIR}/${TEST} -xunitxml -o ${TEST}.xml)
