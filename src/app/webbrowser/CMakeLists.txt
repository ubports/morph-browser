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
)

add_executable(${WEBBROWSER_APP} ${WEBBROWSER_APP_SRC})

target_link_libraries(${WEBBROWSER_APP} ${COMMONLIB})

qt5_use_modules(${WEBBROWSER_APP} Core Quick Sql)

install(TARGETS ${WEBBROWSER_APP}
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})

file(GLOB QML_FILES *.qml)
install(FILES ${QML_FILES} DESTINATION ${CMAKE_INSTALL_DATADIR}/webbrowser-app/webbrowser)

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
