project(webbrowser-plugin)

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
set(WEBBROWSER_IMPORTS_DIR "${QT_INSTALL_QML}/Ubuntu/Components/Extras/Browser")

set(PLUGIN ubuntu-ui-extras-browser-plugin)

set(PLUGIN_SRC plugin.cpp)

add_library(${PLUGIN} MODULE ${PLUGIN_SRC})

qt5_use_modules(${PLUGIN} Core Qml)

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
