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

add_subdirectory(Components)
add_subdirectory(Web)
