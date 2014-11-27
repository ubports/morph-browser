set(XVFB_COMMAND)
find_program(XVFBRUN xvfb-run)
if(XVFBRUN)
  set(XVFB_COMMAND ${XVFBRUN} -s "-screen 0 640x480x24" -a)
else()
  message(WARNING "Cannot find xvfb-run.")
endif()

set(TEST tst_QmlTests)
set(SOURCES
    ${webbrowser-app_SOURCE_DIR}/item-capture.cpp
    tst_QmlTests.cpp
)
add_executable(${TEST} ${SOURCES})
qt5_use_modules(${TEST} Qml Quick QuickTest)
include_directories(${webbrowser-app_SOURCE_DIR} ${Qt5Quick_PRIVATE_INCLUDE_DIRS})
add_test(${TEST} ${XVFB_COMMAND} ${CMAKE_CURRENT_BINARY_DIR}/${TEST}
         -input ${CMAKE_CURRENT_SOURCE_DIR}
         -import ${CMAKE_BINARY_DIR}/src)
