set(TEST tst_HistoryModelTests)
set(SOURCES
    ${webbrowser-app_SOURCE_DIR}/history-model.cpp
    tst_HistoryModelTests.cpp
)
add_executable(${TEST} ${SOURCES})
include_directories(${webbrowser-app_SOURCE_DIR})
qt5_use_modules(${TEST} Core Sql Test)
add_test(${TEST} ${CMAKE_CURRENT_BINARY_DIR}/${TEST} -xunitxml -o ${TEST}.xml)
