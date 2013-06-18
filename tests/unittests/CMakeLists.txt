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

set(HM_SRC
    ${webbrowser-plugin_SOURCE_DIR}/history-model.cpp
    tst_HistoryModelTests.cpp
)
add_executable(tst_HistoryModelTests ${HM_SRC})
include_directories(${webbrowser-plugin_SOURCE_DIR})
qt5_use_modules(tst_HistoryModelTests Core Sql Test)
add_test(tst_HistoryModelTests ${CMAKE_CURRENT_BINARY_DIR}/tst_HistoryModelTests)

set(HMM_SRC
    ${webbrowser-plugin_SOURCE_DIR}/history-model.cpp
    ${webbrowser-plugin_SOURCE_DIR}/history-matches-model.cpp
    tst_HistoryMatchesModelTests.cpp
)
add_executable(tst_HistoryMatchesModelTests ${HMM_SRC})
include_directories(${webbrowser-plugin_SOURCE_DIR})
qt5_use_modules(tst_HistoryMatchesModelTests Core Sql Test)
add_test(tst_HistoryMatchesModelTests ${CMAKE_CURRENT_BINARY_DIR}/tst_HistoryMatchesModelTests)

set(HTM_SRC
    ${webbrowser-plugin_SOURCE_DIR}/history-model.cpp
    ${webbrowser-plugin_SOURCE_DIR}/history-timeframe-model.cpp
    tst_HistoryTimeframeModelTests.cpp
)
add_executable(tst_HistoryTimeframeModelTests ${HTM_SRC})
include_directories(${webbrowser-plugin_SOURCE_DIR})
qt5_use_modules(tst_HistoryTimeframeModelTests Core Sql Test)
add_test(tst_HistoryTimeframeModelTests ${CMAKE_CURRENT_BINARY_DIR}/tst_HistoryTimeframeModelTests)

set(TM_SRC
    ${webbrowser-plugin_SOURCE_DIR}/tabs-model.cpp
    tst_TabsModelTests.cpp
)
add_executable(tst_TabsModelTests ${TM_SRC})
include_directories(${webbrowser-plugin_SOURCE_DIR})
qt5_use_modules(tst_TabsModelTests Core Quick Test)
add_test(tst_TabsModelTests ${CMAKE_CURRENT_BINARY_DIR}/tst_TabsModelTests)
set_tests_properties(tst_TabsModelTests PROPERTIES ENVIRONMENT "QT_QPA_PLATFORM=minimal")
