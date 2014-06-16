project(webbrowser-translations)

include(FindGettext)
find_program(GETTEXT_XGETTEXT_EXECUTABLE xgettext)

set(DOMAIN ${GETTEXT_PACKAGE})
set(POT_FILE ${DOMAIN}.pot)
file(GLOB PO_FILES *.po)

add_custom_target(${POT_FILE}
                  COMMENT "Generating translation template"
                  COMMAND ${INTLTOOL_EXTRACT} --update --type=gettext/ini
                          --srcdir=${CMAKE_SOURCE_DIR} src/app/webbrowser/${DESKTOP_FILE}.in.in

                  COMMAND ${GETTEXT_XGETTEXT_EXECUTABLE} -o ${POT_FILE}
                          -D ${CMAKE_SOURCE_DIR}
                          --from-code=UTF-8
                          --c++ --qt --add-comments=TRANSLATORS
                          --keyword=tr --keyword=tr:1,2
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
