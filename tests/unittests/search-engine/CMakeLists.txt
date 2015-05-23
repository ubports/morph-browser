set(TEST tst_SearchEngineTests)
set(SOURCES
    ${webbrowser-app_SOURCE_DIR}/searchengine.cpp
    tst_SearchEngineTests.cpp
)
add_executable(${TEST} ${SOURCES})
include_directories(${webbrowser-app_SOURCE_DIR})
qt5_use_modules(${TEST} Core Test)
add_test(${TEST} ${CMAKE_CURRENT_BINARY_DIR}/${TEST} -xunitxml -o ${TEST}.xml)
