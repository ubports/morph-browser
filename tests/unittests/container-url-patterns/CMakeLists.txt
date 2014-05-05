set(TEST tst_ContainerUrlPatternsTests)
set(SOURCES
    ${webapp-container_SOURCE_DIR}/url-pattern-utils.cpp
    tst_ContainerUrlPatternsTests.cpp
)
add_executable(${TEST} ${SOURCES})
include_directories(${webapp-container_SOURCE_DIR})
qt5_use_modules(${TEST} Core Test)
add_test(${TEST} ${CMAKE_CURRENT_BINARY_DIR}/${TEST} -xunitxml -o ${TEST}.xml)
