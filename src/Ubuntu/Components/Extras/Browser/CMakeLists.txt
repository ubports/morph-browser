project(webbrowser-plugin)

execute_process(
    COMMAND qmake -query QT_INSTALL_QML
    OUTPUT_VARIABLE QT_INSTALL_QML
    OUTPUT_STRIP_TRAILING_WHITESPACE
)
set(WEBBROWSER_IMPORTS_DIR "${QT_INSTALL_QML}/Ubuntu/Components/Extras/Browser")

set(PLUGIN ubuntu-ui-extras-browser-plugin)

set(PLUGIN_SRC
#    webthumbnail-utils.cpp
#    webthumbnail-provider.cpp
#    webview-thumbnailer.cpp
    plugin.cpp
)

include_directories(${srcdir_SOURCE_DIR})

add_library(${PLUGIN} MODULE ${PLUGIN_SRC})

qt5_use_modules(${PLUGIN} Core Qml Quick) #WebKit)

# work around the lack of a public cmake module for Qt5V8
#set(Qt5V8_PRIVATE_INCLUDE_DIRS
#    "/usr/include/qt5/QtV8/${Qt5Qml_VERSION_STRING}"
#    "/usr/include/qt5/QtV8/${Qt5Qml_VERSION_STRING}/QtV8")
#include_directories(${Qt5Core_PRIVATE_INCLUDE_DIRS}
#                    ${Qt5V8_PRIVATE_INCLUDE_DIRS}
#                    ${Qt5Quick_PRIVATE_INCLUDE_DIRS}
#                    ${Qt5WebKit_PRIVATE_INCLUDE_DIRS})

file(GLOB QML_FILES RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} *.qml qmldir *.js)
install(TARGETS ${PLUGIN} DESTINATION ${WEBBROWSER_IMPORTS_DIR})
install(FILES ${QML_FILES} DESTINATION ${WEBBROWSER_IMPORTS_DIR})
install(DIRECTORY assets
        DESTINATION ${CMAKE_INSTALL_DATADIR}/qtdeclarative5-ubuntu-ui-extras-browser-plugin
        FILES_MATCHING PATTERN *.png)

if(NOT ${CMAKE_CURRENT_BINARY_DIR} STREQUAL ${CMAKE_CURRENT_SOURCE_DIR})
  # copy qml files and assets over to build dir to be able to import them uninstalled
  file(GLOB ASSETS RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} assets/*)
  set(copied ${QML_FILES} ${ASSETS})
  foreach(_file ${copied})
    add_custom_command(OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${_file}
                       DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/${_file}
                       COMMAND ${CMAKE_COMMAND} -E copy_if_different ${CMAKE_CURRENT_SOURCE_DIR}/${_file} ${CMAKE_CURRENT_BINARY_DIR}/${_file})
  endforeach(_file)
  add_custom_target(copy_files_to_build_dir DEPENDS ${copied})
  add_dependencies(${PLUGIN} copy_files_to_build_dir)
endif()
