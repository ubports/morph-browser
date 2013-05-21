project(webbrowser-translations)

include(FindGettext)
find_program(GETTEXT_XGETTEXT_EXECUTABLE xgettext)

set(DOMAIN webbrowser-app)
set(POT_FILE ${DOMAIN}.pot)
file(GLOB PO_FILES *.po)

add_custom_target(${POT_FILE}
                  COMMAND ${GETTEXT_XGETTEXT_EXECUTABLE} -o ${POT_FILE}
                          -D ${CMAKE_SOURCE_DIR}
                          --c++ --qt --add-comments=TRANSLATORS --keyword=tr
                          --package-name=webbrowser-app
                          --copyright-holder='Canonical Ltd.'
                          ${I18N_SRC_FILES})

foreach(PO_FILE ${PO_FILES})
    get_filename_component(LANG ${PO_FILE} NAME_WE)
    gettext_process_po_files(${LANG} ALL PO_FILES ${PO_FILE})
    set(INSTALL_DIR ${CMAKE_INSTALL_LOCALEDIR}/${LANG}/LC_MESSAGES)
    install(FILES ${CMAKE_CURRENT_BINARY_DIR}/${LANG}.gmo
            DESTINATION ${INSTALL_DIR}
            RENAME ${DOMAIN}.mo)
endforeach(PO_FILE)
