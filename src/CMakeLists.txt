project(kalossi-browser)

configure_file(
    config.h.in
    ${CMAKE_CURRENT_BINARY_DIR}/config.h
    @ONLY)

set(KALOSSI_BROWSER kalossi-browser)

set(KALOSSI_SRC
    kalossi-browser.cpp
)

add_executable(${KALOSSI_BROWSER}
    ${KALOSSI_SRC}
)

include_directories(
    ${CMAKE_BINARY_DIR}
)

qt5_use_modules(${KALOSSI_BROWSER} Core Widgets Quick)

install(TARGETS ${KALOSSI_BROWSER}
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})

set(KALOSSI_QML
    Browser.qml
    Chrome.qml
)
install(FILES ${KALOSSI_QML}
    DESTINATION ${CMAKE_INSTALL_DATADIR}/kalossi-browser
    )
