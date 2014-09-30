set(TEST tst_FaviconImageProviderTests)
set(SOURCES
    ${ubuntu-web-plugin_SOURCE_DIR}/favicon-image-provider.cpp
    tst_FaviconImageProviderTests.cpp
)
add_executable(${TEST} ${SOURCES})
include_directories(${ubuntu-web-plugin_SOURCE_DIR})
qt5_use_modules(${TEST} Core Quick Network Test)
add_test(${TEST} ${CMAKE_CURRENT_BINARY_DIR}/${TEST} -xunitxml -o ${TEST}.xml)
