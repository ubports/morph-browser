project(ubuntu-web-plugin)

if(NOT CMAKE_CROSSCOMPILING)
    find_program(QMAKE_EXECUTABLE qmake)
    if(QMAKE_EXECUTABLE STREQUAL "QMAKE_EXECUTABLE-NOTFOUND")
        message(FATAL_ERROR "qmake not found")
    endif()
    execute_process(
        COMMAND ${QMAKE_EXECUTABLE} -query QT_INSTALL_QML
        RESULT_VARIABLE RESULT
        OUTPUT_VARIABLE QT_INSTALL_QML
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    if(NOT RESULT EQUAL 0)
        message(FATAL_ERROR "Failed to determine QT_INSTALL_QML from qmake")
    endif()
else()
    # qmake isn't multi-arch aware as it installs arch-specific mkspec files
    # in to /usr/share, so we can't use it here (we'd need a qmake binary
    # for the host arch using data for the target arch)
    set(QT_INSTALL_QML "/usr/lib/${CMAKE_LIBRARY_ARCHITECTURE}/qt5/qml")
endif()
set(UBUNTU_WEB_IMPORTS_DIR "${QT_INSTALL_QML}/Ubuntu/Web")

set(PLUGIN ubuntu-web-plugin)

set(PLUGIN_SRC plugin.cpp)

add_library(${PLUGIN} MODULE ${PLUGIN_SRC})

qt5_use_modules(${PLUGIN} Core Gui Qml)

file(GLOB QML_FILES RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} *.qml qmldir *.js)
install(TARGETS ${PLUGIN} DESTINATION ${UBUNTU_WEB_IMPORTS_DIR})
install(FILES ${QML_FILES} DESTINATION ${UBUNTU_WEB_IMPORTS_DIR})

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
