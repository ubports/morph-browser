set(TEST tst_QmlTests)
add_executable(${TEST} tst_QmlTests.cpp)
qt5_use_modules(${TEST} Core Qml Quick Test QuickTest)
add_test(${TEST} ${CMAKE_CURRENT_BINARY_DIR}/${TEST} -import ${CMAKE_BINARY_DIR}/src)
#set_tests_properties(${TEST} PROPERTIES ENVIRONMENT "QT_QPA_PLATFORM=minimal")

# copy qml files under test to build dir
set(out_qml_files)
file(GLOB_RECURSE qmlFiles RELATIVE ${webbrowser-common_SOURCE_DIR} ${webbrowser-common_SOURCE_DIR}/*.qml)
foreach(qmlFile ${qmlFiles})
  add_custom_command(OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/undertest/${qmlFile}
                     DEPENDS ${webbrowser-common_SOURCE_DIR}/${qmlFile}
                     COMMAND ${CMAKE_COMMAND} -E copy_if_different ${webbrowser-common_SOURCE_DIR}/${qmlFile} ${CMAKE_CURRENT_BINARY_DIR}/undertest/${qmlFile})
  list(APPEND out_qml_files undertest/${qmlFile})
endforeach(qmlFile)
add_custom_target(copy_qml_files_under_test_to_build_dir DEPENDS ${out_qml_files})
add_dependencies(${TEST} copy_qml_files_under_test_to_build_dir)

if(NOT ${CMAKE_CURRENT_BINARY_DIR} STREQUAL ${CMAKE_CURRENT_SOURCE_DIR})
  # copy qml test files to build dir
  file(GLOB qmlTestFiles RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} *.qml)
  foreach(qmlTestFile ${qmlTestFiles})
    add_custom_command(OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${qmlTestFile}
                       DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/${qmlTestFile}
                       COMMAND ${CMAKE_COMMAND} -E copy_if_different ${CMAKE_CURRENT_SOURCE_DIR}/${qmlTestFile} ${CMAKE_CURRENT_BINARY_DIR}/${qmlTestFile})
  endforeach(qmlTestFile)
  add_custom_target(copy_qml_test_files_to_build_dir DEPENDS ${qmlTestFiles})
  add_dependencies(${TEST} copy_qml_test_files_to_build_dir)
endif()
