set(TEST tst_FaviconFetcherTests)
set(SOURCES
    ${webbrowser-common_SOURCE_DIR}/favicon-fetcher.cpp
    tst_FaviconFetcherTests.cpp
)
add_executable(${TEST} ${SOURCES})
include_directories(${webbrowser-common_SOURCE_DIR})
qt5_use_modules(${TEST} Core Gui Network Test)
add_test(${TEST} ${CMAKE_CURRENT_BINARY_DIR}/${TEST} -xunitxml -o ${TEST}.xml)
set_tests_properties(${TEST} PROPERTIES ENVIRONMENT "QT_QPA_PLATFORM=minimal")
