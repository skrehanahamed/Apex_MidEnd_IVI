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
set(APEX_IVI_VERSION_MINOR 2)
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

find_package(Qt6 REQUIRED COMPONENTS Core Gui Quick Qml QuickControls2 Multimedia DBus Network)

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

    # Check if AASDK protocol library and headers are available
    set(AASDK_DIR "${CMAKE_SOURCE_DIR}/../aasdk")
    if(EXISTS "${AASDK_DIR}/libaasdk_proto.a")
        message(STATUS "AASDK detected at ${AASDK_DIR} -> Enabling native Android Auto projection")
        add_compile_definitions(APEX_ENABLE_AASDK=1)
        add_compile_definitions(BOOST_LOG_DYN_LINK)

        file(GLOB_RECURSE AASDK_RUNTIME_SOURCES CONFIGURE_DEPENDS
            "${AASDK_DIR}/src/*.cpp")
        list(FILTER AASDK_RUNTIME_SOURCES EXCLUDE REGEX "\\.ut\\.cpp$")

        file(CREATE_LINK "${AASDK_DIR}/gen_proto"
                         "${CMAKE_BINARY_DIR}/aasdk_proto" SYMBOLIC)

        set(PLATFORM_LIBS 
            usb-1.0 ssl crypto avcodec avformat avutil swscale asound
            ${AASDK_DIR}/libaasdk_proto.a
            -Wl,--no-as-needed
            protobuf boost_system boost_log boost_log_setup boost_thread boost_filesystem
            -Wl,--as-needed
        )

        if(EXISTS "/workspace/build/tmp/sysroots-components/cortexa76")
            set(PLATFORM_LIBS ${PLATFORM_LIBS}
                -labsl_log_internal_check_op -labsl_leak_check -labsl_die_if_null -labsl_log_internal_conditions -labsl_log_internal_message -labsl_examine_stack -labsl_log_internal_format -labsl_log_internal_proto -labsl_log_internal_nullguard -labsl_log_internal_log_sink_set -labsl_log_sink -labsl_log_entry -labsl_flags_internal -labsl_flags_marshalling -labsl_flags_reflection -labsl_flags_private_handle_accessor -labsl_flags_commandlineflag -labsl_flags_commandlineflag_internal -labsl_flags_config -labsl_flags_program_name -labsl_log_initialize -labsl_log_globals -labsl_vlog_config_internal -labsl_log_internal_fnmatch -labsl_log_internal_globals -labsl_raw_hash_set -labsl_hash -labsl_city -labsl_low_level_hash -labsl_hashtablez_sampler -labsl_statusor -labsl_status -labsl_cord -labsl_cordz_info -labsl_cord_internal -labsl_cordz_functions -labsl_exponential_biased -labsl_cordz_handle -labsl_crc_cord_state -labsl_crc32c -labsl_crc_internal -labsl_crc_cpu_detect -labsl_bad_optional_access -labsl_strerror -labsl_str_format_internal -labsl_synchronization -labsl_graphcycles_internal -labsl_kernel_timeout_internal -labsl_stacktrace -labsl_symbolize -labsl_debugging_internal -labsl_demangle_internal -labsl_malloc_internal -labsl_time -labsl_civil_time -labsl_time_zone -labsl_bad_variant_access -lutf8_validity -lutf8_range -labsl_strings -labsl_strings_internal -labsl_string_view -labsl_base -lrt -labsl_spinlock_wait -labsl_int128 -labsl_throw_delegate -labsl_raw_logging_internal -labsl_log_severity
            )
            include_directories(
                ${CMAKE_BINARY_DIR}
                ${AASDK_DIR}
                ${AASDK_DIR}/gen_proto
                ${AASDK_DIR}/include
                /workspace/build/tmp/sysroots-components/cortexa76/protobuf/usr/include
                /workspace/build/tmp/sysroots-components/cortexa76/abseil-cpp/usr/include
                /workspace/build/tmp/sysroots-components/cortexa76/boost/usr/include
            )
            link_directories(
                /workspace/build/tmp/sysroots-components/cortexa76/protobuf/usr/lib
                /workspace/build/tmp/sysroots-components/cortexa76/abseil-cpp/usr/lib
                /workspace/build/tmp/sysroots-components/cortexa76/boost/usr/lib
            )
        else()
            include_directories(
                ${CMAKE_BINARY_DIR}
                ${AASDK_DIR}
                ${AASDK_DIR}/gen_proto
                ${AASDK_DIR}/include
            )
        endif()
    else()
        message(STATUS "AASDK not found (${AASDK_DIR}/libaasdk_proto.a) -> Building in Desktop / CI mode")
        set(AASDK_RUNTIME_SOURCES "")
        set(PLATFORM_LIBS "")
    endif()
endif()

add_executable(ApexIVI
    src/main.cpp
    src/SystemController.hpp
    src/SystemController.cpp
    src/BluezBluetoothManager.hpp
    src/BluezBluetoothManager.cpp
    src/PbapSyncManager.hpp
    src/PbapSyncManager.cpp
    src/AndroidAutoManager.hpp
    src/AndroidAutoManager.cpp
    src/AndroidAutoH264Decoder.hpp
    src/AndroidAutoH264Decoder.cpp
    src/AndroidAutoAudioSink.hpp
    src/AndroidAutoAudioSink.cpp
    src/AndroidAutoSession.hpp
    src/AndroidAutoSession.cpp
    src/AndroidAutoVideoItem.hpp
    src/AndroidAutoVideoItem.cpp
    ${AASDK_RUNTIME_SOURCES}
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
    Qt6::DBus
    Qt6::Network
    ${PLATFORM_LIBS}
)

# Output directory
set_target_properties(ApexIVI PROPERTIES
    OUTPUT_NAME "ApexIVI"
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}"
)

include(GNUInstallDirs)
install(TARGETS ApexIVI RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
install(FILES THIRD_PARTY_LICENSES.md DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/doc/ApexIVI)
