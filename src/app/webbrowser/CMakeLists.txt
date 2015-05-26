project(webbrowser-app)

include_directories(
    ${CMAKE_BINARY_DIR}
    ${webbrowser-common_SOURCE_DIR}
    ${webbrowser-common_BINARY_DIR}
)

set(WEBBROWSER_APP_MODELS_SRC
    bookmarks-model.cpp
    bookmarks-folder-model.cpp
    bookmarks-folderlist-model.cpp
    bookmarks-folderlist-chronological-model.cpp
    history-domain-model.cpp
    history-domainlist-chronological-model.cpp
    history-domainlist-model.cpp
    history-model.cpp
    history-timeframe-model.cpp
    limit-proxy-model.cpp
    suggestions-filter-model.cpp
    tabs-model.cpp
    top-sites-model.cpp
)

set(WEBBROWSER_APP_MODELS webbrowser-app-models)

add_library(${WEBBROWSER_APP_MODELS} STATIC ${WEBBROWSER_APP_MODELS_SRC})

qt5_use_modules(${WEBBROWSER_APP_MODELS} Core Sql)

set(WEBBROWSER_APP_SRC
    cache-deleter.cpp
    file-operations.cpp
    searchengine.cpp
    webbrowser-app.cpp
)

set(WEBBROWSER_APP webbrowser-app)

add_executable(${WEBBROWSER_APP} ${WEBBROWSER_APP_SRC})

target_link_libraries(${WEBBROWSER_APP} ${COMMONLIB} ${WEBBROWSER_APP_MODELS})

qt5_use_modules(${WEBBROWSER_APP} Concurrent Core Qml Quick)

install(TARGETS ${WEBBROWSER_APP}
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})

file(GLOB QML_FILES *.qml *.js)
install(FILES ${QML_FILES} DESTINATION ${CMAKE_INSTALL_DATADIR}/webbrowser-app/webbrowser)

install(DIRECTORY assets
        DESTINATION ${CMAKE_INSTALL_DATADIR}/webbrowser-app/webbrowser
        FILES_MATCHING PATTERN *.png)

install(DIRECTORY upstreamcomponents
        DESTINATION ${CMAKE_INSTALL_DATADIR}/webbrowser-app/webbrowser
        FILES_MATCHING PATTERN *.qml)

install(DIRECTORY searchengines
        DESTINATION ${CMAKE_INSTALL_DATADIR}/webbrowser-app/webbrowser
        FILES_MATCHING PATTERN *.xml)

configure_file(${DESKTOP_FILE}.in.in ${DESKTOP_FILE}.in @ONLY)
add_custom_target(${DESKTOP_FILE} ALL
                  COMMENT "Merging translations into ${DESKTOP_FILE}"
                  COMMAND ${INTLTOOL_MERGE} -d -u ${CMAKE_SOURCE_DIR}/po
                          ${CMAKE_CURRENT_BINARY_DIR}/${DESKTOP_FILE}.in ${DESKTOP_FILE})

install(FILES ${CMAKE_CURRENT_BINARY_DIR}/${DESKTOP_FILE}
        DESTINATION ${CMAKE_INSTALL_DATADIR}/applications)

install(FILES "webbrowser-app.url-dispatcher"
        DESTINATION ${CMAKE_INSTALL_DATADIR}/url-dispatcher/urls)
