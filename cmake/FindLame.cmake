find_path(LAME_INCLUDE_DIR lame/lame.h)
find_library(LAME_LIBRARIES NAMES mp3lame)

if (LAME_INCLUDE_DIR AND LAME_LIBRARIES)
    set(LAME_FOUND TRUE)
endif ()

if (NOT LAME_FOUND)
    message(FATAL_ERROR "Could NOT find lame development files")
endif ()

message(STATUS "Found lame includes: ${LAME_INCLUDE_DIR}/lame/lame.h")
message(STATUS "Found lame library: ${LAME_LIBRARIES}")

add_library(Lame::Lame INTERFACE IMPORTED)

set_target_properties(Lame::Lame PROPERTIES
        INTERFACE_LINK_LIBRARIES "${LAME_LIBRARIES}"
        INTERFACE_INCLUDE_DIRECTORIES "${LAME_INCLUDE_DIR}")

mark_as_advanced(LAME_INCLUDE_DIR)
mark_as_advanced(LAME_LIBRARIES)
