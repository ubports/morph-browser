project(webbrowser-plugin)

find_package(Qt5Core REQUIRED)
find_package(Qt5Gui REQUIRED)
find_package(Qt5Qml REQUIRED)

set(WEBBROWSER_IMPORTS_DIR "${QT_INSTALL_QML}/Ubuntu/Components/Extras/Browser")

set(PLUGIN ubuntu-ui-extras-browser-plugin)

set(PLUGIN_SRC plugin.cpp)

add_library(${PLUGIN} MODULE ${PLUGIN_SRC})
target_link_libraries(${PLUGIN}
    Qt5::Core
    Qt5::Gui
    Qt5::Qml
)

file(GLOB UA_OVERRIDES_IN RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} ua-overrides-*.js.in)
foreach(_file ${UA_OVERRIDES_IN})
  string(REGEX REPLACE "\\.in$" "" OUTFILE ${_file})
  configure_file(${_file} ${CMAKE_CURRENT_BINARY_DIR}/${OUTFILE} @ONLY)
  install(FILES ${CMAKE_CURRENT_BINARY_DIR}/${OUTFILE}
          DESTINATION ${WEBBROWSER_IMPORTS_DIR})
endforeach(_file)

file(GLOB QML_FILES RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} *.qml qmldir *.js)
install(TARGETS ${PLUGIN} DESTINATION ${WEBBROWSER_IMPORTS_DIR})
install(FILES ${QML_FILES} DESTINATION ${WEBBROWSER_IMPORTS_DIR})

if(NOT ${CMAKE_CURRENT_BINARY_DIR} STREQUAL ${CMAKE_CURRENT_SOURCE_DIR})
  # copy qml files and assets over to build dir to be able to import them uninstalled
  foreach(_file ${QML_FILES})
    add_custom_command(OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${_file}
                       DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/${_file}
                       COMMAND ${CMAKE_COMMAND} -E copy_if_different ${CMAKE_CURRENT_SOURCE_DIR}/${_file} ${CMAKE_CURRENT_BINARY_DIR}/${_file})
  endforeach(_file)
  add_custom_target(copy_files_to_build_dir_legacy DEPENDS ${QML_FILES})
  add_dependencies(${PLUGIN} copy_files_to_build_dir_legacy)
endif()
