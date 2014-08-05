cmake_minimum_required(VERSION 2.8.9)
set(CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

# Standard install paths
include(GNUInstallDirs)

string(TOLOWER "${CMAKE_BUILD_TYPE}" cmake_build_type_lower)

# enable QML debugging
if(CMAKE_BUILD_TYPE MATCHES DEBUG OR CMAKE_BUILD_TYPE MATCHES "Debug")
    add_definitions(-DQT_QML_DEBUG)
endif()

include(qt5)
find_package(Qt5Gui REQUIRED)
find_package(Qt5Sql REQUIRED)
find_package(Qt5Widgets REQUIRED)
find_package(Qt5Quick REQUIRED)

set(CMAKE_INCLUDE_CURRENT_DIR ON)
set(CMAKE_AUTOMOC ON)

# uninstall target
configure_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/cmake_uninstall.cmake.in"
    "${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake"
    IMMEDIATE @ONLY)
add_custom_target(uninstall
    COMMAND ${CMAKE_COMMAND} -P ${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake)

add_subdirectory(src)

enable_testing()
# add_subdirectory(tests)

# make non compiled files (QML, JS, images, etc.) visible in QtCreator
file(GLOB_RECURSE NON_COMPILED_FILES *.qml *.js *.png *.svg *.py *.pot *.po *.qdoc *.qdocconf *.css)
add_custom_target(NON_COMPILED_TARGET ALL SOURCES ${NON_COMPILED_FILES})

file(GLOB_RECURSE I18N_SRC_FILES
     RELATIVE ${CMAKE_CURRENT_SOURCE_DIR}
     src/app/**.qml src/app/**.desktop.in)
list(SORT I18N_SRC_FILES)

# for dh_translations to extract the domain
# (regarding syntax consistency, see http://pad.lv/1181187)
set (GETTEXT_PACKAGE "webbrowser-app")

add_subdirectory(po)

add_subdirectory(doc)

install(FILES webbrowser-app.svg
        DESTINATION ${CMAKE_INSTALL_DATADIR}/icons/hicolor/scalable/apps)
install(FILES screenshot.png
        DESTINATION ${CMAKE_INSTALL_DATADIR}/webbrowser-app)
