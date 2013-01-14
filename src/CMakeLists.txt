project(ubuntu-browser)

configure_file(
    config.h.in
    ${CMAKE_CURRENT_BINARY_DIR}/config.h
    @ONLY)

set(UBUNTU_BROWSER ubuntu-browser)

set(UBUNTU_BROWSER_SRC
    ubuntu-browser.cpp
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

set(UBUNTU_BROWSER_QML
    Browser.qml
    Chrome.qml
)
install(FILES ${UBUNTU_BROWSER_QML}
    DESTINATION ${CMAKE_INSTALL_DATADIR}/ubuntu-browser
    )
