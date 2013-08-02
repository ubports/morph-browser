set(TEST tst_BookmarksModelTests)
set(SOURCES
    ${webbrowser-plugin_SOURCE_DIR}/bookmarks-model.cpp
    tst_BookmarksModelTests.cpp
)
add_executable(${TEST} ${SOURCES})
include_directories(${webbrowser-plugin_SOURCE_DIR})
qt5_use_modules(${TEST} Core Sql Test)
add_test(${TEST} ${CMAKE_CURRENT_BINARY_DIR}/${TEST} -xunitxml -o ${TEST}.xml)
