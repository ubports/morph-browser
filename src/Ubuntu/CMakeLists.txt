if(NOT CMAKE_CROSSCOMPILING)
    set(QT_INSTALL_QML "${CMAKE_INSTALL_LIBDIR}/qt5/qml")
else()
    # qmake isn't multi-arch aware as it installs arch-specific mkspec files
    # in to /usr/share, so we can't use it here (we'd need a qmake binary
    # for the host arch using data for the target arch)
    set(QT_INSTALL_QML "/usr/lib/${CMAKE_LIBRARY_ARCHITECTURE}/qt5/qml")
endif()

execute_process(COMMAND lsb_release --short --release
    OUTPUT_VARIABLE UBUNTU_VERSION OUTPUT_STRIP_TRAILING_WHITESPACE)
add_definitions(-DUBUNTU_VERSION="${UBUNTU_VERSION}")

add_subdirectory(Components)
add_subdirectory(Web)
