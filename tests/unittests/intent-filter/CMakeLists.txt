find_package(Qt5Core REQUIRED)
find_package(Qt5Qml REQUIRED)
find_package(Qt5Test REQUIRED)
set(TEST tst_IntentFilterTests)
set(SOURCES
    ${webapp-container_SOURCE_DIR}/intent-parser.cpp
    ${webapp-container_SOURCE_DIR}/scheme-filter.cpp
    tst_IntentFilterTests.cpp
)
include_directories(${webapp-container_SOURCE_DIR})
add_executable(${TEST} ${SOURCES})
target_link_libraries(${TEST}
    Qt5::Core
    Qt5::Qml
    Qt5::Test
)
add_test(${TEST} ${CMAKE_CURRENT_BINARY_DIR}/${TEST})
