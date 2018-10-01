project(ubuntu-web-plugin)

find_package(Qt5Core REQUIRED)
find_package(Qt5Gui REQUIRED)
find_package(Qt5Qml REQUIRED)

set(UBUNTU_WEB_IMPORTS_DIR "${QT_INSTALL_QML}/Ubuntu/Web")

set(PLUGIN ubuntu-web-plugin)

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
          DESTINATION ${UBUNTU_WEB_IMPORTS_DIR})
endforeach(_file)

file(GLOB PLUGIN_FILES RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} *.qml qmldir *.js *.png)
install(TARGETS ${PLUGIN} DESTINATION ${UBUNTU_WEB_IMPORTS_DIR})
install(FILES ${PLUGIN_FILES} DESTINATION ${UBUNTU_WEB_IMPORTS_DIR})

#if(NOT ${CMAKE_CURRENT_BINARY_DIR} STREQUAL ${CMAKE_CURRENT_SOURCE_DIR})
#  # copy qml files over to build dir to be able to import them uninstalled
#  foreach(_file ${PLUGIN_FILES})
#    add_custom_command(OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${_file}
#                       DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/${_file}
#                       COMMAND ${CMAKE_COMMAND} -E copy_if_different ${CMAKE_CURRENT_SOURCE_DIR}/${_file} ${CMAKE_CURRENT_BINARY_DIR}/${_file})
#  endforeach(_file)
#  add_custom_target(copy_files_to_build_dir DEPENDS ${PLUGIN_FILES})
#  add_dependencies(${PLUGIN} copy_files_to_build_dir)
#endif()
