project(webbrowser-common)

find_package(Qt5Core REQUIRED)
find_package(Qt5Gui REQUIRED)
find_package(Qt5Network REQUIRED)
find_package(Qt5Qml REQUIRED)
find_package(Qt5Quick REQUIRED)
find_package(Qt5Widgets REQUIRED)
#find_package(Qt5WebEngine REQUIRED)

include(FindPkgConfig)
pkg_check_modules(LIBAPPARMOR libapparmor REQUIRED)

configure_file(
    config.h.in
    ${CMAKE_CURRENT_BINARY_DIR}/config.h
    @ONLY)

set(COMMONLIB webbrowser-common)

set(COMMONLIB_SRC
    browserapplication.cpp
    browser-utils.cpp
    domain-permissions-model.cpp
    domain-settings-model.cpp
    domain-settings-sorted-model.cpp
    domain-settings-user-agents-model.cpp
    downloads-model.cpp
    favicon-fetcher.cpp
    file-operations.cpp
    input-method-handler.cpp
    meminfo.cpp
    mime-database.cpp
    notifications-proxy.cpp
    pushclient/pushclient.cpp
    session-storage.cpp
    single-instance-manager.cpp
)

add_library(${COMMONLIB} STATIC ${COMMONLIB_SRC})

include_directories(${LIBAPPARMOR_INCLUDE_DIRS})
target_link_libraries(${COMMONLIB}
    Qt5::Core
    Qt5::Gui
    Qt5::Network
    Qt5::Qml
    Qt5::Quick
    Qt5::Widgets
    Qt5DBus
    Qt5WebEngine
    Qt5WebEngineCore
    ${LIBAPPARMOR_LDFLAGS}
)

file(GLOB QML_FILES *.qml qmldir)
install(FILES ${QML_FILES} DESTINATION ${CMAKE_INSTALL_DATADIR}/morph-browser)
file(GLOB JS_FILES *.js)
install(FILES ${JS_FILES} DESTINATION ${CMAKE_INSTALL_DATADIR}/morph-browser)
install(DIRECTORY actions DESTINATION ${CMAKE_INSTALL_DATADIR}/morph-browser
        FILES_MATCHING PATTERN *.qml)

add_subdirectory(webbrowser)
add_subdirectory(webcontainer)
