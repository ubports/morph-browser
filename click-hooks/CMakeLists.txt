project(webapp-container-hook)

find_package(Qt5Core REQUIRED)

include_directories(
    ${CMAKE_BINARY_DIR}
    ${webbrowser-common_SOURCE_DIR}
    ${webbrowser-common_BINARY_DIR}
)

set(WEBAPP_CONTAINER_HOOK_FOLDER webapp-container)

set(WEBAPP_CONTAINER_HOOK webapp-container-hook)

add_definitions(-DWEBAPP_CONTAINER_HOOK_FOLDER="${WEBAPP_CONTAINER_HOOK_FOLDER}")

set(WEBAPP_CONTAINER_HOOK_SRC
    hook.cpp
    hook-utils.h
    hook-utils.cpp
)

add_executable(${WEBAPP_CONTAINER_HOOK} ${WEBAPP_CONTAINER_HOOK_SRC})
target_link_libraries(${WEBAPP_CONTAINER_HOOK}
    Qt5::Core
)

install(TARGETS ${WEBAPP_CONTAINER_HOOK}
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})

configure_file(
    webapp-container.hook.in
    ${CMAKE_CURRENT_BINARY_DIR}/webapp-container.hook
    @ONLY)

file(GLOB WEBAPP_CONTANER_HOOK_FILES ${CMAKE_CURRENT_BINARY_DIR}/*.hook)
install(FILES ${WEBAPP_CONTANER_HOOK_FILES} DESTINATION ${CMAKE_INSTALL_DATADIR}/click/hooks)
