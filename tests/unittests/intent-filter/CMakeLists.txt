set(TEST tst_IntentFilterTests)
set(SOURCES
    ${CMAKE_SOURCE_DIR}/src/app/webcontainer/intent-filter.cpp
    tst_IntentFilterTests.cpp
)
set(WEBAPP_CONTAINER_INTENT_FILTER webapp-container-intent-filter)
include_directories(${CMAKE_SOURCE_DIR})
add_executable(${TEST} ${SOURCES})
qt5_use_modules(${TEST} Core Test Qml)
add_test(${TEST} ${CMAKE_CURRENT_BINARY_DIR}/${TEST} -xunitxml -o ${TEST}.xml)
