set(TEST tst_QmlTests)
add_executable(${TEST} tst_QmlTests.cpp)
qt5_use_modules(${TEST} Core Qml Quick Test QuickTest)
add_test(${TEST} ${CMAKE_CURRENT_BINARY_DIR}/${TEST})
set_tests_properties(${TEST} PROPERTIES ENVIRONMENT "QT_QPA_PLATFORM=minimal")

# copy qml files under test to build dir
# FIXME: when the source files are updated, they are not copied over again
file(GLOB qmlFiles RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} ${webbrowser-app_SOURCE_DIR}/*.qml)
foreach(qmlFile ${qmlFiles})
  file(COPY ${qmlFile} DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/undertest)
endforeach(qmlFile)

# copy qml test files to build dir
# FIXME: when the source files are updated, they are not copied over again
file(GLOB qmlTestFiles RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} *qml)
foreach(qmlTestFile ${qmlTestFiles})
  file(COPY ${qmlTestFile} DESTINATION ${CMAKE_CURRENT_BINARY_DIR})
endforeach(qmlTestFile)
