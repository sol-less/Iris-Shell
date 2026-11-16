cmake_minimum_required(VERSION 3.20)
cmake_policy(SET CMP0177 NEW)
project(Iris LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

find_package(Qt6 6.5 REQUIRED COMPONENTS Core Gui Qml Quick DBus Network)
qt_standard_project_setup(REQUIRES 6.5)
set(QT_QML_GENERATE_QMLLS_INI ON)

# Drop a .h/.cpp anywhere under src/, or a .qml under src/ui or src/widgets, and run
# `cmake --build build`: the globs are re-checked on every build.
file(GLOB_RECURSE IRIS_CPP RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} CONFIGURE_DEPENDS
    src/*.h src/*.cpp)
file(GLOB_RECURSE IRIS_QML RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} CONFIGURE_DEPENDS
    src/ui/*.qml src/widgets/*.qml)

set_source_files_properties(src/ui/motion/Motion.qml PROPERTIES QT_QML_SINGLETON_TYPE TRUE)

qt_add_qml_module(iris
    URI Iris
    VERSION 1.0
    PLUGIN_TARGET iris
    OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/Iris
    SOURCES ${IRIS_CPP}
    QML_FILES ${IRIS_QML}
)

file(GLOB _src_dirs LIST_DIRECTORIES true ${CMAKE_CURRENT_SOURCE_DIR}/src/*)
foreach(_d ${_src_dirs})
    if(IS_DIRECTORY ${_d})
        target_include_directories(iris PRIVATE ${_d})
    endif()
endforeach()

target_link_libraries(iris PRIVATE
    Qt6::Core Qt6::Gui Qt6::Qml Qt6::Quick Qt6::DBus Qt6::Network
)

install(DIRECTORY ${CMAKE_BINARY_DIR}/Iris
    DESTINATION ${QT6_INSTALL_PREFIX}/${QT6_INSTALL_QML}
)
install(DIRECTORY config/registry/ DESTINATION /usr/share/iris-shell/registry FILES_MATCHING PATTERN "*.json")
