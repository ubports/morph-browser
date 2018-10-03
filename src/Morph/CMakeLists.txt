set(QT_INSTALL_QML "/usr/lib/${CMAKE_LIBRARY_ARCHITECTURE}/qt5/qml")

execute_process(COMMAND lsb_release --short --release
    OUTPUT_VARIABLE UBUNTU_VERSION OUTPUT_STRIP_TRAILING_WHITESPACE)
add_definitions(-DUBUNTU_VERSION="${UBUNTU_VERSION}")

add_subdirectory(Web)
