project(ubuntu-browser-plugin)

set(PLUGIN ubuntubrowser)

set(PLUGIN_SRC
    plugin.cpp
)

add_library(${PLUGIN} MODULE ${PLUGIN_SRC})

qt5_use_modules(${PLUGIN} Qml)

file(GLOB QML_FILES *.qml)
install(TARGETS ${PLUGIN} DESTINATION ${UBUNTU_BROWSER_IMPORTS_DIR})
install(FILES ${QML_FILES} DESTINATION ${UBUNTU_BROWSER_IMPORTS_DIR})
install(FILES qmldir DESTINATION ${UBUNTU_BROWSER_IMPORTS_DIR})

