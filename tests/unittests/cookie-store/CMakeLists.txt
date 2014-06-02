set(TEST tst_CookieStoreTests)
set(SOURCES
    ${webapp-container_SOURCE_DIR}/chrome-cookie-store.cpp
    ${webapp-container_SOURCE_DIR}/cookie-store.cpp
    ${webapp-container_SOURCE_DIR}/webkit-cookie-store.cpp
    tst_CookieStore.cpp
)
add_executable(${TEST} ${SOURCES})
include_directories(${webapp-container_SOURCE_DIR})
qt5_use_modules(${TEST} Core Network Sql Test)
add_test(${TEST} ${CMAKE_CURRENT_BINARY_DIR}/${TEST} -xunitxml -o ${TEST}.xml)
