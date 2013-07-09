project(webbrowser-plugin)

set(PLUGIN ubuntu-ui-extras-browser-plugin)

set(PLUGIN_SRC
    history-model.cpp
    history-matches-model.cpp
    history-timeframe-model.cpp
    history-host-model.cpp
    history-hostlist-model.cpp
    tabs-model.cpp
    webthumbnail-provider.cpp
    webview-thumbnailer.cpp
    plugin.cpp
)

add_library(${PLUGIN} MODULE ${PLUGIN_SRC})

qt5_use_modules(${PLUGIN} Core Qml Quick Sql WebKit)

# work around the lack of a public cmake module for Qt5V8
set(Qt5V8_PRIVATE_INCLUDE_DIRS
    "/usr/include/qt5/QtV8/${Qt5Qml_VERSION_STRING}"
    "/usr/include/qt5/QtV8/${Qt5Qml_VERSION_STRING}/QtV8")
include_directories(${Qt5V8_PRIVATE_INCLUDE_DIRS}
                    ${Qt5Quick_PRIVATE_INCLUDE_DIRS}
                    ${Qt5WebKit_PRIVATE_INCLUDE_DIRS})

file(GLOB QML_FILES *.qml qmldir *.js)
install(TARGETS ${PLUGIN} DESTINATION ${WEBBROWSER_IMPORTS_DIR})
install(FILES ${QML_FILES} DESTINATION ${WEBBROWSER_IMPORTS_DIR})
install(DIRECTORY assets DESTINATION ${CMAKE_INSTALL_DATADIR}/webbrowser-app
        FILES_MATCHING PATTERN *.png)

# copy qml files over to build dir to be able to import them in tests
foreach(qmlFile ${QML_FILES})
  file(COPY ${qmlFile} DESTINATION ${CMAKE_BINARY_DIR}/src/Ubuntu/Components/Extras/Browser/)
endforeach(qmlFile)
