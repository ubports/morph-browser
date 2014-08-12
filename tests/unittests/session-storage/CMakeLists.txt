set(TEST tst_SessionStorageTests)
set(SOURCES
    ${webbrowser-common_SOURCE_DIR}/session-storage.cpp
    tst_SessionStorageTests.cpp
)
add_executable(${TEST} ${SOURCES})
include_directories(${webbrowser-common_SOURCE_DIR})
qt5_use_modules(${TEST} Core Test)
add_test(${TEST} ${CMAKE_CURRENT_BINARY_DIR}/${TEST} -xunitxml -o ${TEST}.xml)
