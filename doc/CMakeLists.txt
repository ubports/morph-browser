project(ubuntu-web-doc)

find_program(QDOC_EXECUTABLE qdoc)
if(QDOC_EXECUTABLE STREQUAL "QDOC_EXECUTABLE-NOTFOUND")
    message(WARNING "qdoc not found, documentation cannot be built")
else()
    add_custom_target(doc ALL
                      COMMAND ${QDOC_EXECUTABLE}
                      -outputdir ${CMAKE_CURRENT_BINARY_DIR}/html
                      ${CMAKE_CURRENT_SOURCE_DIR}/ubuntu-web.qdocconf)
    install(DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/html
            DESTINATION ${CMAKE_INSTALL_DATADIR}/doc/ubuntu-web)
endif()
