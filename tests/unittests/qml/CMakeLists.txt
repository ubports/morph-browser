find_package(Qt5Core REQUIRED)
find_package(Qt5Gui REQUIRED)
find_package(Qt5Network REQUIRED)
find_package(Qt5Qml REQUIRED)
find_package(Qt5Quick REQUIRED)
find_package(Qt5QuickTest REQUIRED)

set(XVFB_COMMAND)
find_program(XVFBRUN xvfb-run)
if(XVFBRUN)
  set(XVFB_COMMAND ${XVFBRUN} -s "-screen 0 640x480x24" -a)
else()
  message(WARNING "Cannot find xvfb-run.")
endif()

set(TEST tst_QmlTests)
set(SOURCES
    ${webbrowser-common_SOURCE_DIR}/favicon-fetcher.cpp
    ${webbrowser-app_SOURCE_DIR}/file-operations.cpp
    ${webbrowser-app_SOURCE_DIR}/searchengine.cpp
    ${webbrowser-app_SOURCE_DIR}/tabs-model.cpp
    tst_QmlTests.cpp
)
add_executable(${TEST} ${SOURCES})
include_directories(
    ${webbrowser-common_SOURCE_DIR}
    ${webbrowser-app_SOURCE_DIR}
)
target_link_libraries(${TEST}
    Qt5::Core
    Qt5::Gui
    Qt5::Network
    Qt5::Qml
    Qt5::Quick
    Qt5::QuickTest
)
add_test(${TEST} ${XVFB_COMMAND} ${CMAKE_CURRENT_BINARY_DIR}/${TEST}
         -input ${CMAKE_CURRENT_SOURCE_DIR}
         -import ${CMAKE_BINARY_DIR}/src)
