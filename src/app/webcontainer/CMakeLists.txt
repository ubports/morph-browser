project(webapp-container)

include_directories(
    ${CMAKE_BINARY_DIR}
    ${webbrowser-common_SOURCE_DIR}
    ${webbrowser-common_BINARY_DIR}
)

set(WEBAPP_CONTAINER webapp-container)

set(WEBAPP_CONTAINER_SRC
    cookiestore.cpp
    onlineaccountscookiestore.cpp
    sqlitecookiestore.cpp
    webapp-container.cpp
)

add_executable(${WEBAPP_CONTAINER} ${WEBAPP_CONTAINER_SRC})

target_link_libraries(${WEBAPP_CONTAINER} ${COMMONLIB})

qt5_use_modules(${WEBAPP_CONTAINER} Core Widgets Quick Sql DBus)

install(TARGETS ${WEBAPP_CONTAINER}
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})

file(GLOB QML_FILES *.qml)
install(FILES ${QML_FILES} DESTINATION ${CMAKE_INSTALL_DATADIR}/webbrowser-app/webcontainer)
install(DIRECTORY actions DESTINATION ${CMAKE_INSTALL_DATADIR}/webbrowser-app/webcontainer
        FILES_MATCHING PATTERN *.qml)

