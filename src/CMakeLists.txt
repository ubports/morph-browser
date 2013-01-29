project(ubuntu-browser)

set(QT_IMPORTS_DIR ${_qt5Quick_install_prefix}/imports)
set(UBUNTU_BROWSER_IMPORTS_DIR "${QT_IMPORTS_DIR}/Ubuntu/Browser")

add_subdirectory(Ubuntu)

configure_file(
    config.h.in
    ${CMAKE_CURRENT_BINARY_DIR}/config.h
    @ONLY)

set(UBUNTU_BROWSER ubuntu-browser)

set(UBUNTU_BROWSER_SRC
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
