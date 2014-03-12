project(webbrowser-common)

configure_file(
    config.h.in
    ${CMAKE_CURRENT_BINARY_DIR}/config.h
    @ONLY)

set(COMMONLIB webbrowser-common)

set(COMMONLIB_SRC
    browserapplication.cpp
    webbrowser-window.cpp
    webthumbnail-provider.cpp
    webthumbnail-utils.cpp
    webview-thumbnailer.cpp
)

include_directories(${srcdir_SOURCE_DIR})

add_library(${COMMONLIB} STATIC ${COMMONLIB_SRC})

qt5_use_modules(${COMMONLIB} Core Quick WebKit Widgets)

# work around the lack of a public cmake module for Qt5V8
set(Qt5V8_PRIVATE_INCLUDE_DIRS
    "/usr/include/qt5/QtV8/${Qt5Qml_VERSION_STRING}"
    "/usr/include/qt5/QtV8/${Qt5Qml_VERSION_STRING}/QtV8")
include_directories(${Qt5Core_PRIVATE_INCLUDE_DIRS}
                    ${Qt5V8_PRIVATE_INCLUDE_DIRS}
                    ${Qt5Quick_PRIVATE_INCLUDE_DIRS}
                    ${Qt5WebKit_PRIVATE_INCLUDE_DIRS})

file(GLOB QML_FILES *.qml)
install(FILES ${QML_FILES} DESTINATION ${CMAKE_INSTALL_DATADIR}/webbrowser-app)
install(DIRECTORY actions DESTINATION ${CMAKE_INSTALL_DATADIR}/webbrowser-app
        FILES_MATCHING PATTERN *.qml)

install(DIRECTORY assets DESTINATION ${CMAKE_INSTALL_DATADIR}/webbrowser-app
        FILES_MATCHING PATTERN *.png)

add_subdirectory(webbrowser)
add_subdirectory(webcontainer)
