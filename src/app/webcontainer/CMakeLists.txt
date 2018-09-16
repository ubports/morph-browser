project(webapp-ng)

find_package(Qt5DBus REQUIRED)
find_package(Qt5Sql REQUIRED)

include_directories(
    ${CMAKE_BINARY_DIR}
    ${webbrowser-common_SOURCE_DIR}
    ${webbrowser-common_BINARY_DIR}
)

set(WEBAPP_CONTAINER webapp-ng)

set(WEBAPP_CONTAINER_SRC
    chrome-cookie-store.cpp
    cookie-store.cpp
    online-accounts-cookie-store.cpp
    oxide-cookie-helper.cpp
    local-cookie-store.cpp
    webapp-container.cpp
    webapp-container-helper.cpp
    session-utils.cpp
    url-pattern-utils.cpp
    scheme-filter.cpp
    intent-parser.cpp
)

add_executable(${WEBAPP_CONTAINER} ${WEBAPP_CONTAINER_SRC})

target_link_libraries(${WEBAPP_CONTAINER}
    Qt5::Core
    Qt5::DBus
    Qt5::Gui
    Qt5::Qml
    Qt5::Quick
    Qt5::Sql
    ${COMMONLIB}
)

install(TARGETS ${WEBAPP_CONTAINER}
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})

file(GLOB QML_FILES *.qml *.js)
install(FILES ${QML_FILES} DESTINATION ${CMAKE_INSTALL_DATADIR}/webapp-ng/webcontainer)
install(DIRECTORY actions DESTINATION ${CMAKE_INSTALL_DATADIR}/webapp-ng/webcontainer
        FILES_MATCHING PATTERN *.qml)

install(DIRECTORY assets
        DESTINATION ${CMAKE_INSTALL_DATADIR}/webapp-ng/webcontainer
        FILES_MATCHING PATTERN *.png)

configure_file(${DESKTOP_FILE}.in.in ${DESKTOP_FILE}.in @ONLY)
add_custom_target(${DESKTOP_FILE} ALL
                  COMMENT "Merging translations into ${DESKTOP_FILE}"
                  COMMAND ${INTLTOOL_MERGE} -d -u ${CMAKE_SOURCE_DIR}/po
                          ${CMAKE_CURRENT_BINARY_DIR}/${DESKTOP_FILE}.in ${DESKTOP_FILE})

install(FILES ${CMAKE_CURRENT_BINARY_DIR}/${DESKTOP_FILE}
        DESTINATION ${CMAKE_INSTALL_DATADIR}/applications)

install(FILES "webapp-ng-content-hub.json"
    DESTINATION ${CMAKE_INSTALL_DATADIR}/content-hub/peers
    RENAME webapp-ng
    )

if(${CLICK_MODE})
  message("-- Configuring manifest.json")

  execute_process(
    COMMAND dpkg-architecture -qDEB_HOST_ARCH
    OUTPUT_VARIABLE CLICK_ARCH
    OUTPUT_STRIP_TRAILING_WHITESPACE
  )

  configure_file(manifest.json.in ${CMAKE_CURRENT_BINARY_DIR}/manifest.json)
  install(FILES ${CMAKE_CURRENT_BINARY_DIR}/manifest.json DESTINATION ${CMAKE_INSTALL_PREFIX})
  install(FILES webapp-ng.apparmor DESTINATION ${CMAKE_INSTALL_PREFIX})
endif()
