set(TEST tst_HistoryDomainModelTests)
set(SOURCES
    ${webbrowser-plugin_SOURCE_DIR}/domain-utils.cpp
    ${webbrowser-plugin_SOURCE_DIR}/history-domain-model.cpp
    ${webbrowser-plugin_SOURCE_DIR}/history-model.cpp
    ${webbrowser-plugin_SOURCE_DIR}/history-timeframe-model.cpp
    tst_HistoryDomainModelTests.cpp
)
add_executable(${TEST} ${SOURCES})
include_directories(${webbrowser-plugin_SOURCE_DIR})
qt5_use_modules(${TEST} Core Sql Test)
add_test(${TEST} ${CMAKE_CURRENT_BINARY_DIR}/${TEST} -xunitxml -o ${TEST}.xml)
