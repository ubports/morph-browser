set(TEST tst_DomainUtilsTests)
set(SOURCES
    ${webbrowser-plugin_SOURCE_DIR}/domain-utils.cpp
    tst_DomainUtilsTests.cpp
)
add_executable(${TEST} ${SOURCES})
include_directories(${webbrowser-plugin_SOURCE_DIR})
qt5_use_modules(${TEST} Core Test)
add_test(${TEST} ${CMAKE_CURRENT_BINARY_DIR}/${TEST} -xunitxml -o ${TEST}.xml)
