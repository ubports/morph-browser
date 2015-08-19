find_package(Qt5Core REQUIRED)
find_package(Qt5Test REQUIRED)
set(TEST tst_SearchEngineTests)
set(SOURCES
    ${webbrowser-app_SOURCE_DIR}/searchengine.cpp
    tst_SearchEngineTests.cpp
)
add_executable(${TEST} ${SOURCES})
include_directories(${webbrowser-app_SOURCE_DIR})
target_link_libraries(${TEST}
    Qt5::Core
    Qt5::Test
)
add_test(${TEST} ${CMAKE_CURRENT_BINARY_DIR}/${TEST} -xunitxml -o ${TEST}.xml)
