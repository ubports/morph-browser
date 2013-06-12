project(webbrowser-plugin)

set(PLUGIN ubuntubrowser)

set(PLUGIN_SRC
    history-model.cpp
    history-matches-model.cpp
    tabs-model.cpp
    plugin.cpp
)

add_library(${PLUGIN} MODULE ${PLUGIN_SRC})

qt5_use_modules(${PLUGIN} Core Qml Sql)

file(GLOB QML_FILES *.qml qmldir *.js *.qmltheme)
install(TARGETS ${PLUGIN} DESTINATION ${WEBBROWSER_IMPORTS_DIR})
install(FILES ${QML_FILES} DESTINATION ${WEBBROWSER_IMPORTS_DIR})
install(DIRECTORY assets DESTINATION ${WEBBROWSER_IMPORTS_DIR}
        FILES_MATCHING PATTERN *.png)

# copy qml files over to build dir to be able to import them in tests
foreach(qmlFile ${QML_FILES})
  file(COPY ${qmlFile} DESTINATION ${CMAKE_BINARY_DIR}/src/Ubuntu/Browser/)
endforeach(qmlFile)
