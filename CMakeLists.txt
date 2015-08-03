cmake_minimum_required(VERSION 2.8.9)
set(CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

project("webbrowser")

find_program(INTLTOOL_MERGE intltool-merge)
if(NOT INTLTOOL_MERGE)
    message(FATAL_ERROR "Could not find intltool-merge, please install the intltool package")
endif()
find_program(INTLTOOL_EXTRACT intltool-extract)
if(NOT INTLTOOL_EXTRACT)
    message(FATAL_ERROR "Could not find intltool-extract, please install the intltool package")
endif()

# Standard install paths
include(GNUInstallDirs)

string(TOLOWER "${CMAKE_BUILD_TYPE}" cmake_build_type_lower)

include(EnableCoverageReport)
#####################################################################
# Enable code coverage calculation with gcov/gcovr/lcov
# Usage:
#  * Switch build type to coverage (use ccmake or cmake-gui)
#  * Invoke make, make test, make coverage (or ninja if you use that backend)
#  * Find html report in subdir coveragereport
#  * Find xml report feasible for jenkins in coverage.xml
#####################################################################
if(cmake_build_type_lower MATCHES coverage)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} --coverage" )
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} --coverage" )
    set(CMAKE_MODULE_LINKER_FLAGS "${CMAKE_MODULE_LINKER_FLAGS} --coverage" )
    set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} --coverage" )
    ENABLE_COVERAGE_REPORT(EXCLUDES tests/*|.*moc_.*.cpp FILTER tests/* moc_*.cpp)
endif()

# for unity8 components
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")

# enable QML debugging
if(CMAKE_BUILD_TYPE MATCHES DEBUG OR CMAKE_BUILD_TYPE MATCHES "Debug")
    add_definitions(-DQT_QML_DEBUG)
endif()

include(qt5)

set(CMAKE_INCLUDE_CURRENT_DIR ON)
set(CMAKE_AUTOMOC ON)

set(DESKTOP_FILE webbrowser-app.desktop)

# uninstall target
configure_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/cmake_uninstall.cmake.in"
    "${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake"
    IMMEDIATE @ONLY)
add_custom_target(uninstall
    COMMAND ${CMAKE_COMMAND} -P ${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake)

add_subdirectory(src)

enable_testing()
add_subdirectory(tests)

# make non compiled files (QML, JS, images, etc.) visible in QtCreator
file(GLOB_RECURSE NON_COMPILED_FILES *.qml *.js *.png *.py *.pot *.po *.qdoc *.qdocconf *.css)
add_custom_target(NON_COMPILED_TARGET ALL SOURCES ${NON_COMPILED_FILES})

# for dh_translations to extract the domain
# (regarding syntax consistency, see http://pad.lv/1181187)
set (GETTEXT_PACKAGE "webbrowser-app")

add_subdirectory(po)

add_subdirectory(doc)

install(FILES webbrowser-app.png screenshot.png
        DESTINATION ${CMAKE_INSTALL_DATADIR}/webbrowser-app)

add_subdirectory(click-hooks)
