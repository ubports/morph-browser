project(webbrowser-app)

execute_process(
    COMMAND qmake -query QT_INSTALL_QML
    OUTPUT_VARIABLE QT_INSTALL_QML
    OUTPUT_STRIP_TRAILING_WHITESPACE
)
set(WEBBROWSER_IMPORTS_DIR "${QT_INSTALL_QML}/Ubuntu/Browser")

add_subdirectory(Ubuntu)

configure_file(
    config.h.in
    ${CMAKE_CURRENT_BINARY_DIR}/config.h
    @ONLY)

set(WEBBROWSER_APP webbrowser-app)

set(WEBBROWSER_SRC
    commandline-parser.cpp
    history-model.cpp
    history-matches-model.cpp
    webbrowser-app.cpp
    main.cpp
)

add_executable(${WEBBROWSER_APP}
    ${WEBBROWSER_SRC}
)

include_directories(
    ${CMAKE_BINARY_DIR}
)

qt5_use_modules(${WEBBROWSER_APP} Core Sql Widgets Quick)

install(TARGETS ${WEBBROWSER_APP}
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})

set(DESKTOP_FILE webbrowser-app.desktop)
file(REMOVE ${CMAKE_CURRENT_BINARY_DIR}/${DESKTOP_FILE})
file(STRINGS ${DESKTOP_FILE}.in DESKTOP_FILE_CONTENTS)
foreach(LINE ${DESKTOP_FILE_CONTENTS})
    string(REGEX REPLACE "tr\\\(\"(.*)\"\\\)" "\\1" LINE "${LINE}")
    file(APPEND ${CMAKE_CURRENT_BINARY_DIR}/${DESKTOP_FILE} "${LINE}\n")
endforeach(LINE)

install(FILES ${CMAKE_CURRENT_BINARY_DIR}/${DESKTOP_FILE}
        DESTINATION ${CMAKE_INSTALL_DATADIR}/applications)
