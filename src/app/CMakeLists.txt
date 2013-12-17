project(webbrowser-common)

configure_file(
    config.h.in
    ${CMAKE_CURRENT_BINARY_DIR}/config.h
    @ONLY)

file(GLOB QML_FILES *.qml)
install(FILES ${QML_FILES} DESTINATION ${CMAKE_INSTALL_DATADIR}/webbrowser-app)
install(DIRECTORY actions DESTINATION ${CMAKE_INSTALL_DATADIR}/webbrowser-app
        FILES_MATCHING PATTERN *.qml)

install(DIRECTORY assets DESTINATION ${CMAKE_INSTALL_DATADIR}/webbrowser-app
        FILES_MATCHING PATTERN *.png)

add_subdirectory(webbrowser)
add_subdirectory(webcontainer)

