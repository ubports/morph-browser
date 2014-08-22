project(webbrowser-translations)

include(FindGettext)
find_program(GETTEXT_XGETTEXT_EXECUTABLE xgettext)

file(RELATIVE_PATH DESKTOP_FILE_IN_IN ${CMAKE_SOURCE_DIR}
     ${webbrowser-app_SOURCE_DIR}/${DESKTOP_FILE}.in.in)
file(RELATIVE_PATH DESKTOP_FILE_IN_IN_H ${CMAKE_SOURCE_DIR}
     ${CMAKE_CURRENT_SOURCE_DIR}/${DESKTOP_FILE_IN_IN}.h)

file(GLOB_RECURSE I18N_SRC_FILES
     RELATIVE ${CMAKE_SOURCE_DIR}
     ${CMAKE_SOURCE_DIR}/src/app/**.qml)
list(SORT I18N_SRC_FILES)

set(DOMAIN ${GETTEXT_PACKAGE})
set(POT_FILE ${DOMAIN}.pot)
file(GLOB PO_FILES *.po)

add_custom_target(${POT_FILE} ALL
                  COMMENT "Generating translation template"
                  COMMAND ${INTLTOOL_EXTRACT} --update --type=gettext/ini
                          --srcdir=${CMAKE_SOURCE_DIR} ${DESKTOP_FILE_IN_IN}
                  COMMAND ${GETTEXT_XGETTEXT_EXECUTABLE} -o ${POT_FILE}
                          --from-code=UTF-8
                          --c++ --qt --add-comments=TRANSLATORS
                          --keyword=tr --keyword=tr:1,2 --keyword=N_
                          --package-name=webbrowser-app
                          --copyright-holder='Canonical Ltd.'
                          -D ${CMAKE_SOURCE_DIR} ${I18N_SRC_FILES}
                          -D ${CMAKE_BINARY_DIR} ${DESKTOP_FILE_IN_IN_H})

foreach(PO_FILE ${PO_FILES})
    get_filename_component(LANG ${PO_FILE} NAME_WE)
    gettext_process_po_files(${LANG} ALL PO_FILES ${PO_FILE})
    set(INSTALL_DIR ${CMAKE_INSTALL_LOCALEDIR}/${LANG}/LC_MESSAGES)
    install(FILES ${CMAKE_CURRENT_BINARY_DIR}/${LANG}.gmo
            DESTINATION ${INSTALL_DIR}
            RENAME ${DOMAIN}.mo)
endforeach(PO_FILE)
