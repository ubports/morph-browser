project(webbrowser-app)

include_directories(
    ${CMAKE_BINARY_DIR}
    ${webbrowser-common_SOURCE_DIR}
    ${webbrowser-common_BINARY_DIR}
    ${srcdir_SOURCE_DIR}
)

set(WEBBROWSER_APP webbrowser-app)

set(WEBBROWSER_APP_SRC
    history-model.cpp
    history-matches-model.cpp
    history-timeframe-model.cpp
    history-domain-model.cpp
    history-domainlist-model.cpp
    history-domainlist-chronological-model.cpp
    tabs-model.cpp
    bookmarks-model.cpp
    settings.cpp
    webbrowser-app.cpp
    webthumbnail-provider.cpp
    webthumbnail-utils.cpp
    webview-thumbnailer.cpp
)

add_executable(${WEBBROWSER_APP} ${WEBBROWSER_APP_SRC})

target_link_libraries(${WEBBROWSER_APP} ${COMMONLIB})

qt5_use_modules(${WEBBROWSER_APP} Core Gui Quick Sql WebKit)

# work around the lack of a public cmake module for Qt5V8
set(Qt5V8_PRIVATE_INCLUDE_DIRS
    "/usr/include/qt5/QtV8/${Qt5Qml_VERSION_STRING}"
    "/usr/include/qt5/QtV8/${Qt5Qml_VERSION_STRING}/QtV8")
include_directories(${Qt5Core_PRIVATE_INCLUDE_DIRS}
                    ${Qt5V8_PRIVATE_INCLUDE_DIRS}
                    ${Qt5Quick_PRIVATE_INCLUDE_DIRS}
                    ${Qt5WebKit_PRIVATE_INCLUDE_DIRS})

install(TARGETS ${WEBBROWSER_APP}
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})

file(GLOB QML_FILES *.qml)
install(FILES ${QML_FILES} DESTINATION ${CMAKE_INSTALL_DATADIR}/webbrowser-app/webbrowser)

install(DIRECTORY assets
        DESTINATION ${CMAKE_INSTALL_DATADIR}/webbrowser-app/webbrowser
        FILES_MATCHING PATTERN *.png)

set(DESKTOP_FILE webbrowser-app.desktop)
configure_file(${DESKTOP_FILE}.in.in ${DESKTOP_FILE}.in @ONLY)
file(REMOVE ${CMAKE_CURRENT_BINARY_DIR}/${DESKTOP_FILE})
file(STRINGS ${CMAKE_CURRENT_BINARY_DIR}/${DESKTOP_FILE}.in DESKTOP_FILE_CONTENTS)
foreach(LINE ${DESKTOP_FILE_CONTENTS})
    string(REGEX REPLACE "tr\\\(\"(.*)\"\\\)" "\\1" LINE "${LINE}")
    file(APPEND ${CMAKE_CURRENT_BINARY_DIR}/${DESKTOP_FILE} "${LINE}\n")
endforeach(LINE)

install(FILES ${CMAKE_CURRENT_BINARY_DIR}/${DESKTOP_FILE}
        DESTINATION ${CMAKE_INSTALL_DATADIR}/applications)

install(FILES "webbrowser-app.url-dispatcher"
        DESTINATION ${CMAKE_INSTALL_DATADIR}/url-dispatcher/urls)
