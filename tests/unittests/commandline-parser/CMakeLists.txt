set(TEST tst_CommandLineParserTests)
set(SOURCES
    ${webbrowser-app_SOURCE_DIR}/commandline-parser.cpp
    tst_CommandLineParserTests.cpp
)
add_executable(${TEST} ${SOURCES})
include_directories(${webbrowser-app_SOURCE_DIR} ${webbrowser-app_BINARY_DIR})
qt5_use_modules(${TEST} Core Test)
add_test(${TEST} ${CMAKE_CURRENT_BINARY_DIR}/${TEST} -xunitxml -o ${TEST}.xml)
