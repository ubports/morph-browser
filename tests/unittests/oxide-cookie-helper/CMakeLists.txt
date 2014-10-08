set(TEST tst_OxideCookieHelperTests)
set(SOURCES
    ${webapp-container_SOURCE_DIR}/oxide-cookie-helper.cpp
    tst_OxideCookieHelper.cpp
)
add_executable(${TEST} ${SOURCES})
include_directories(${webapp-container_SOURCE_DIR})
qt5_use_modules(${TEST} Core Network Test)
add_test(${TEST} ${CMAKE_CURRENT_BINARY_DIR}/${TEST} -xunitxml -o ${TEST}.xml)
