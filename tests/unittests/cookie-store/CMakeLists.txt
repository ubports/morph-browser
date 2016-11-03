find_package(Qt5Core REQUIRED)
find_package(Qt5Network REQUIRED)
find_package(Qt5Sql REQUIRED)
find_package(Qt5Test REQUIRED)
set(TEST tst_CookieStoreTests)
set(SOURCES
    ${webapp-container_SOURCE_DIR}/chrome-cookie-store.cpp
    ${webapp-container_SOURCE_DIR}/cookie-store.cpp
    ${webapp-container_SOURCE_DIR}/oxide-cookie-helper.cpp
    tst_CookieStore.cpp
)
add_executable(${TEST} ${SOURCES})
include_directories(${webapp-container_SOURCE_DIR})
target_link_libraries(${TEST}
    Qt5::Core
    Qt5::Network
    Qt5::Sql
    Qt5::Test
)
add_test(${TEST} ${CMAKE_CURRENT_BINARY_DIR}/${TEST})
