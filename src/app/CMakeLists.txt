project(webbrowser-app)

configure_file(
    config.h.in
    ${CMAKE_CURRENT_BINARY_DIR}/config.h
    @ONLY)

include_directories(
    ${CMAKE_BINARY_DIR}
)

set(WEBBROWSER_APP webbrowser-app)

set(WEBBROWSER_APP_SRC
    browserapplication.cpp
    settings.cpp
    webbrowser-app.cpp
    webbrowser-window.cpp
)

add_executable(${WEBBROWSER_APP}
    ${WEBBROWSER_APP_SRC}
)

qt5_use_modules(${WEBBROWSER_APP} Core Widgets Quick)

set(WEBAPP_CONTAINER webapp-container)

set(WEBAPP_CONTAINER_SRC
    browserapplication.cpp
    webapp-container.cpp
    webbrowser-window.cpp
)

add_executable(${WEBAPP_CONTAINER}
    ${WEBAPP_CONTAINER_SRC}
)

qt5_use_modules(${WEBAPP_CONTAINER} Core Widgets Quick)

install(TARGETS ${WEBBROWSER_APP} ${WEBAPP_CONTAINER}
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})

file(GLOB QML_FILES *.qml)
install(FILES ${QML_FILES} DESTINATION ${CMAKE_INSTALL_DATADIR}/webbrowser-app)
install(DIRECTORY actions DESTINATION ${CMAKE_INSTALL_DATADIR}/webbrowser-app
        FILES_MATCHING PATTERN *.qml)

install(DIRECTORY assets DESTINATION ${CMAKE_INSTALL_DATADIR}/webbrowser-app
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
