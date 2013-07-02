set(TEST tst_HistoryHostModelTests)
set(SOURCES
    ${webbrowser-plugin_SOURCE_DIR}/history-host-model.cpp
    ${webbrowser-plugin_SOURCE_DIR}/history-model.cpp
    ${webbrowser-plugin_SOURCE_DIR}/history-timeframe-model.cpp
    tst_HistoryHostModelTests.cpp
)
add_executable(${TEST} ${SOURCES})
include_directories(${webbrowser-plugin_SOURCE_DIR})
qt5_use_modules(${TEST} Core Sql Test)
add_test(${TEST} ${CMAKE_CURRENT_BINARY_DIR}/${TEST})
