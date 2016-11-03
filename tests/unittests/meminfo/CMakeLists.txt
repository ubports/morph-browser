find_package(Qt5Core REQUIRED)
find_package(Qt5Test REQUIRED)
set(TEST tst_MemInfoTests)
set(SOURCES
    ${webbrowser-common_SOURCE_DIR}/meminfo.cpp
    tst_MemInfoTests.cpp
)
add_executable(${TEST} ${SOURCES})
include_directories(${webbrowser-common_SOURCE_DIR})
target_link_libraries(${TEST}
    Qt5::Core
    Qt5::Test
)
add_test(${TEST} ${CMAKE_CURRENT_BINARY_DIR}/${TEST})
set_tests_properties(${TEST} PROPERTIES ENVIRONMENT "QT_QPA_PLATFORM=minimal")
