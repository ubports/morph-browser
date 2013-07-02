set(TEST tst_QmlTests)
add_executable(${TEST} tst_QmlTests.cpp)
qt5_use_modules(${TEST} Core Qml Quick Test QuickTest)
target_link_libraries(${TEST} ${TPL_QT5_LIBRARIES})
add_test(${TEST} ${CMAKE_CURRENT_BINARY_DIR}/${TEST} -import ${CMAKE_BINARY_DIR}/src)
set_tests_properties(${TEST} PROPERTIES ENVIRONMENT "QT_QPA_PLATFORM=minimal")

# copy qml test files to build dir
file(GLOB qmlTestFiles RELATIVE ${CMAKE_SOURCE_DIR}/tests/unittests/qml/ *qml)
foreach(qmlTestFile ${qmlTestFiles})
  file(COPY ${qmlTestFile} DESTINATION ${CMAKE_BINARY_DIR}/tests/unittests/qml/)
endforeach(qmlTestFile)
