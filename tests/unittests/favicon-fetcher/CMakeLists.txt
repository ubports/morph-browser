find_package(Qt5Core REQUIRED)
find_package(Qt5Gui REQUIRED)
find_package(Qt5Network REQUIRED)
find_package(Qt5Test REQUIRED)
set(TEST tst_FaviconFetcherTests)
set(SOURCES
    ${webbrowser-common_SOURCE_DIR}/favicon-fetcher.cpp
    tst_FaviconFetcherTests.cpp
)
add_executable(${TEST} ${SOURCES})
include_directories(${webbrowser-common_SOURCE_DIR})
target_link_libraries(${TEST}
    Qt5::Core
    Qt5::Gui
    Qt5::Network
    Qt5::Test
)
add_test(${TEST} ${CMAKE_CURRENT_BINARY_DIR}/${TEST})
set_tests_properties(${TEST} PROPERTIES ENVIRONMENT "QT_QPA_PLATFORM=minimal")
