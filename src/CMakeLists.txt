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
    webbrowser-app.cpp
    main.cpp
)

add_executable(${WEBBROWSER_APP}
    ${WEBBROWSER_SRC}
)

include_directories(
    ${CMAKE_BINARY_DIR}
)

qt5_use_modules(${WEBBROWSER_APP} Core Widgets Quick)

install(TARGETS ${WEBBROWSER_APP}
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})

install(FILES ubuntu-browser.desktop
        DESTINATION ${CMAKE_INSTALL_DATADIR}/applications)
