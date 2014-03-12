set(TEST tst_HistoryDomainListModelTests)
set(SOURCES
    ${webbrowser-app_SOURCE_DIR}/history-domain-model.cpp
    ${webbrowser-app_SOURCE_DIR}/history-domainlist-model.cpp
    ${webbrowser-app_SOURCE_DIR}/history-model.cpp
    ${webbrowser-app_SOURCE_DIR}/history-timeframe-model.cpp
    tst_HistoryDomainListModelTests.cpp
)
add_executable(${TEST} ${SOURCES})
include_directories(${srcdir_SOURCE_DIR} ${webbrowser-app_SOURCE_DIR})
qt5_use_modules(${TEST} Core Sql Test)
add_test(${TEST} ${CMAKE_CURRENT_BINARY_DIR}/${TEST} -xunitxml -o ${TEST}.xml)
