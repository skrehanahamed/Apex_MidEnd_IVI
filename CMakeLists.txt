# ============================================================================
# Project: Apex IVI - Automotive In-Vehicle Infotainment System
# Developer: Sk Rehan Ahamed
# ============================================================================

cmake_minimum_required(VERSION 3.20)

# ============================================================================
# Project Version Configuration
# [VERSION_CONFIG] Update version numbers below when new release is given:
# ============================================================================
set(APEX_IVI_VERSION_MAJOR 1)
set(APEX_IVI_VERSION_MINOR 0)
set(APEX_IVI_VERSION_PATCH 0)
set(APEX_IVI_VERSION_STRING "v${APEX_IVI_VERSION_MAJOR}.${APEX_IVI_VERSION_MINOR}.${APEX_IVI_VERSION_PATCH}")

project(ApexIVI VERSION ${APEX_IVI_VERSION_MAJOR}.${APEX_IVI_VERSION_MINOR}.${APEX_IVI_VERSION_PATCH} LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

add_compile_definitions(APEX_IVI_VERSION_STRING="${APEX_IVI_VERSION_STRING}")
add_compile_definitions(APEX_IVI_VERSION_RAW="${PROJECT_VERSION}")

find_package(Qt6 REQUIRED COMPONENTS Core Gui Quick Qml QuickControls2 Multimedia)

if(APPLE)
    enable_language(OBJCXX)
    set(PLATFORM_SOURCES
        src/NativeAudioRecorder.h
        src/NativeAudioRecorder.mm
    )
    set_source_files_properties(src/NativeAudioRecorder.mm PROPERTIES COMPILE_FLAGS "-fobjc-arc")
    set(PLATFORM_LIBS
        "-framework AVFoundation"
        "-framework Foundation"
    )
else()
    set(PLATFORM_SOURCES
        src/NativeAudioRecorder.h
        src/NativeAudioRecorder.cpp
    )
    set(PLATFORM_LIBS "")
endif()

add_executable(ApexIVI
    src/main.cpp
    src/SystemController.hpp
    src/SystemController.cpp
    ${PLATFORM_SOURCES}
    resources.qrc
)

target_link_libraries(ApexIVI PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Quick
    Qt6::Qml
    Qt6::QuickControls2
    Qt6::Multimedia
    ${PLATFORM_LIBS}
)

# Output directory
set_target_properties(ApexIVI PROPERTIES
    OUTPUT_NAME "ApexIVI"
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}"
)
