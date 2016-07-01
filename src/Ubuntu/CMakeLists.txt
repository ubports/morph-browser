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

execute_process(COMMAND lsb_release --short --release
    OUTPUT_VARIABLE UBUNTU_VERSION OUTPUT_STRIP_TRAILING_WHITESPACE)
add_definitions(-DUBUNTU_VERSION="${UBUNTU_VERSION}")

execute_process(COMMAND ${XVFB_COMMAND} qmlscene --quit ${CMAKE_CURRENT_SOURCE_DIR}/chromium-version.qml
    OUTPUT_VARIABLE CHROMIUM_VERSION OUTPUT_STRIP_TRAILING_WHITESPACE)
string(REGEX MATCH "\\[(.*)\\]" _ ${CHROMIUM_VERSION})
set(CHROMIUM_VERSION ${CMAKE_MATCH_1})
if(NOT CHROMIUM_VERSION MATCHES "^[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+$")
    message(FATAL_ERROR "Invalid chromium version: '${CHROMIUM_VERSION}'")
endif()

add_subdirectory(Components)
add_subdirectory(Web)
