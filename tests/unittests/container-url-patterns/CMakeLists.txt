set(TEST tst_ContainerUrlPatterns)
set(SOURCES
    ${webapp-container_SOURCE_DIR}/url-pattern-utils.cpp
    tst_ContainerUrlPatterns.cpp
)
add_executable(${TEST} ${SOURCES})
include_directories(${webapp-container_SOURCE_DIR})
qt5_use_modules(${TEST} Core Quick Test)
add_test(${TEST} ${CMAKE_CURRENT_BINARY_DIR}/${TEST} -xunitxml -o ${TEST}.xml)
set_tests_properties(${TEST} PROPERTIES ENVIRONMENT "QT_QPA_PLATFORM=minimal")
