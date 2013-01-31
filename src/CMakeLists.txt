project(ubuntu-browser)

execute_process(
    COMMAND qmake -query QT_INSTALL_QML
    OUTPUT_VARIABLE QT_INSTALL_QML
    OUTPUT_STRIP_TRAILING_WHITESPACE
)
set(UBUNTU_BROWSER_IMPORTS_DIR "${QT_INSTALL_QML}/Ubuntu/Browser")

add_subdirectory(Ubuntu)

configure_file(
    config.h.in
    ${CMAKE_CURRENT_BINARY_DIR}/config.h
    @ONLY)

set(UBUNTU_BROWSER ubuntu-browser)

set(UBUNTU_BROWSER_SRC
    commandline-parser.cpp
    ubuntu-browser.cpp
    main.cpp
)

add_executable(${UBUNTU_BROWSER}
    ${UBUNTU_BROWSER_SRC}
)

include_directories(
    ${CMAKE_BINARY_DIR}
)

qt5_use_modules(${UBUNTU_BROWSER} Core Widgets Quick)

install(TARGETS ${UBUNTU_BROWSER}
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})

install(FILES ubuntu-browser.desktop
        DESTINATION ${CMAKE_INSTALL_DATADIR}/applications)
