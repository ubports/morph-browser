set(TEST tst_IntentFilterTests)
set(SOURCES
    ${webapp-container_SOURCE_DIR}/intent-filter.cpp
    tst_IntentFilterTests.cpp
)
include_directories(${webapp-container_SOURCE_DIR})
add_executable(${TEST} ${SOURCES})
qt5_use_modules(${TEST} Core Test Qml)
add_test(${TEST} ${CMAKE_CURRENT_BINARY_DIR}/${TEST} -xunitxml -o ${TEST}.xml)
