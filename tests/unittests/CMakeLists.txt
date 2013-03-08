add_executable(tst_QmlTests tst_QmlTests.cpp)
qt5_use_modules(tst_QmlTests Core Qml Quick Test QuickTest)
target_link_libraries(tst_QmlTests ${TPL_QT5_LIBRARIES})
add_test(tst_QmlTests ${CMAKE_CURRENT_BINARY_DIR}/tst_QmlTests -import ${CMAKE_BINARY_DIR}/src)
set_tests_properties(tst_QmlTests PROPERTIES ENVIRONMENT "QT_QPA_PLATFORM=minimal")

# copy qml test files to build dir
file(GLOB qmlTestFiles RELATIVE ${CMAKE_SOURCE_DIR}/tests/unittests/ *qml)
foreach(qmlTestFile ${qmlTestFiles})
  file(COPY ${qmlTestFile} DESTINATION ${CMAKE_BINARY_DIR}/tests/unittests/)
endforeach(qmlTestFile)

set(CLP_SRC
    ${webbrowser-app_SOURCE_DIR}/commandline-parser.cpp
    tst_CommandLineParserTests.cpp
)
add_executable(tst_CommandLineParserTests ${CLP_SRC})
include_directories(${webbrowser-app_SOURCE_DIR} ${webbrowser-app_BINARY_DIR})
qt5_use_modules(tst_CommandLineParserTests Core Test)
add_test(tst_CommandLineParserTests ${CMAKE_CURRENT_BINARY_DIR}/tst_CommandLineParserTests)
