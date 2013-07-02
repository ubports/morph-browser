set(TEST tst_TabsModelTests)
set(SOURCES
    ${webbrowser-plugin_SOURCE_DIR}/tabs-model.cpp
    tst_TabsModelTests.cpp
)
add_executable(${TEST} ${SOURCES})
include_directories(${webbrowser-plugin_SOURCE_DIR})
qt5_use_modules(${TEST} Core Quick Test)
add_test(${TEST} ${CMAKE_CURRENT_BINARY_DIR}/${TEST})
set_tests_properties(${TEST} PROPERTIES ENVIRONMENT "QT_QPA_PLATFORM=minimal")
