find_package(Qt5Core REQUIRED)
find_package(Qt5Test REQUIRED)
set(TEST tst_ContainerUrlPatternsTests)
set(SOURCES
    ${webapp-container_SOURCE_DIR}/url-pattern-utils.cpp
    tst_ContainerUrlPatternsTests.cpp
)
add_executable(${TEST} ${SOURCES})
include_directories(${webapp-container_SOURCE_DIR})
target_link_libraries(${TEST}
    Qt5::Core
    Qt5::Test
)
add_test(${TEST} ${CMAKE_CURRENT_BINARY_DIR}/${TEST})
