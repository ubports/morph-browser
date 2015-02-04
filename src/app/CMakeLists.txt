project(webbrowser-common)

configure_file(
    config.h.in
    ${CMAKE_CURRENT_BINARY_DIR}/config.h
    @ONLY)

set(COMMONLIB webbrowser-common)

set(COMMONLIB_SRC
    browserapplication.cpp
    favicon-fetcher.cpp
    session-storage.cpp
    webbrowser-window.cpp
)

add_library(${COMMONLIB} STATIC ${COMMONLIB_SRC})

qt5_use_modules(${COMMONLIB} Core Gui Network Qml Quick Widgets)

include_directories(${Qt5Quick_PRIVATE_INCLUDE_DIRS})

include_directories(${unity8_SOURCE_DIR}/libs/UbuntuGestures
                    ${unity8_SOURCE_DIR}/plugins)
target_link_libraries(${COMMONLIB} UbuntuGesturesQml)

file(GLOB QML_FILES *.qml)
install(FILES ${QML_FILES} DESTINATION ${CMAKE_INSTALL_DATADIR}/webbrowser-app)
file(GLOB JS_FILES *.js)
install(FILES ${JS_FILES} DESTINATION ${CMAKE_INSTALL_DATADIR}/webbrowser-app)
install(DIRECTORY actions DESTINATION ${CMAKE_INSTALL_DATADIR}/webbrowser-app
        FILES_MATCHING PATTERN *.qml)

add_subdirectory(unity8)
add_subdirectory(webbrowser)
add_subdirectory(webcontainer)
