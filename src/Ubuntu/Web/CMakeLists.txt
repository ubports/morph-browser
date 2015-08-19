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

file(GLOB QML_FILES RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} *.qml qmldir *.js)
install(TARGETS ${PLUGIN} DESTINATION ${UBUNTU_WEB_IMPORTS_DIR})
install(FILES ${QML_FILES} DESTINATION ${UBUNTU_WEB_IMPORTS_DIR})
install(DIRECTORY assets
        DESTINATION ${CMAKE_INSTALL_DATADIR}/qtdeclarative5-ubuntu-web-plugin
        FILES_MATCHING PATTERN *.png)

if(NOT ${CMAKE_CURRENT_BINARY_DIR} STREQUAL ${CMAKE_CURRENT_SOURCE_DIR})
  # copy qml files over to build dir to be able to import them uninstalled
  foreach(_file ${QML_FILES})
    add_custom_command(OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${_file}
                       DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/${_file}
                       COMMAND ${CMAKE_COMMAND} -E copy_if_different ${CMAKE_CURRENT_SOURCE_DIR}/${_file} ${CMAKE_CURRENT_BINARY_DIR}/${_file})
  endforeach(_file)
  add_custom_target(copy_files_to_build_dir DEPENDS ${QML_FILES})
  add_dependencies(${PLUGIN} copy_files_to_build_dir)
endif()
