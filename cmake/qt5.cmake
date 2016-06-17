# shamelessly copied over from oxide’s build system
# to enable ARM cross compilation

if(CMAKE_CROSSCOMPILING)
  # QT_MOC_EXECUTABLE is set by Qt5CoreConfigExtras, but it sets it to
  # the target executable rather than the host executable, which is no
  # use for cross-compiling. For cross-compiling, we have a guess and
  # override it ourselves
  if(NOT TARGET Qt5::moc)
    find_program(
        QT_MOC_EXECUTABLE moc
        PATHS /usr/lib/qt5/bin /usr/lib/${HOST_ARCHITECTURE}/qt5/bin
        NO_DEFAULT_PATH)
    if(QT_MOC_EXECUTABLE STREQUAL "QT_MOC_EXECUTABLE-NOTFOUND")
      message(FATAL_ERROR "Can't find a moc executable for the host arch")
    endif()
    add_executable(Qt5::moc IMPORTED)
    set_target_properties(Qt5::moc PROPERTIES
        IMPORTED_LOCATION "${QT_MOC_EXECUTABLE}")
  endif()

  # Dummy targets - not used anywhere, but this stops Qt5CoreConfigExtras.cmake
  # from creating them and checking if the binary exists, which is broken when
  # cross-building because it checks for the target system binary. We need the
  # host system binaries installed, because they are in the same package as the
  # moc in Ubuntu (qtbase5-dev-tools), which is not currently multi-arch
  if(NOT TARGET Qt5::qmake)
    add_executable(Qt5::qmake IMPORTED)
  endif()
  if(NOT TARGET Qt5::rcc)
    add_executable(Qt5::rcc IMPORTED)
  endif()
  if(NOT TARGET Qt5::uic)
    add_executable(Qt5::uic IMPORTED)
  endif()
  if(NOT TARGET Qt5::qdbuscpp2xml)
    add_executable(Qt5::qdbuscpp2xml IMPORTED)
  endif()
  if(NOT TARGET Qt5::qdbusxml2cpp)
    add_executable(Qt5::qdbusxml2cpp IMPORTED)
  endif()
else()
  # This should be enough to initialize QT_MOC_EXECUTABLE
  find_package(Qt5Core)
endif()
